defmodule CloudMonitor.Adapters.AWS.InventoryMetricsTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.Adapters.AWS
  @moduletag :tmp_dir
  @window %{start: ~U[2026-10-01 00:00:00Z], end: ~U[2026-10-03 00:00:00Z]}
  setup %{tmp_dir: dir} do
    file = Path.join(dir, "explicit-test-credential.json")

    File.write!(
      file,
      JSON.encode!(%{"accessKeyId" => "AKIDEXAMPLE", "secretAccessKey" => "fixture-secret"})
    )

    {:ok,
     c: %{
       "id" => "a",
       "billingScopeId" => "billing",
       "credentialRef" => "file:" <> file,
       "settings" => %{"accountId" => "123456789012", "regions" => ["us-east-1"]}
     }}
  end

  defp ok(body), do: {:ok, %{status: 200, headers: [], body: body}}

  defp identity,
    do:
      "<GetCallerIdentityResponse><GetCallerIdentityResult><Account>123456789012</Account></GetCallerIdentityResult></GetCallerIdentityResponse>"

  defp instances(token),
    do:
      "<DescribeInstancesResponse xmlns=\"http://ec2.amazonaws.com/doc/2016-11-15/\"><reservationSet><item><instancesSet><item><instanceId>#{if token, do: "i-b", else: "i-a"}</instanceId><instanceState><name>running</name></instanceState><tagSet><item><key>Name</key><value>Test instance</value></item></tagSet></item></instancesSet></item></reservationSet>#{if token, do: "", else: "<nextToken>ec2-next</nextToken>"}</DescribeInstancesResponse>"

  defp inventory_http(owner) do
    fn _, url, headers, body, opts ->
      send(owner, {:wire, url, headers, body, opts})

      cond do
        String.contains?(url, "sts.") ->
          ok(identity())

        String.contains?(url, "s3.") ->
          ok(
            "<ListAllMyBucketsResult><Buckets><Bucket><Name>test-bucket</Name><BucketRegion>us-east-1</BucketRegion></Bucket></Buckets></ListAllMyBucketsResult>"
          )

        URI.decode_query(body)["Action"] == "DescribeInstances" ->
          ok(instances(URI.decode_query(body)["NextToken"] != nil))

        true ->
          ok(
            "<DescribeVolumesResponse><volumeSet><item><volumeId>vol-a</volumeId><status>in-use</status><tagSet/></item></volumeSet></DescribeVolumesResponse>"
          )
      end
    end
  end

  test "EC2 EBS S3 inventories parse real XML and paginate within only configured region", %{c: c} do
    assert {:ok, %{records: rows, status: %{"complete" => true}}} =
             AWS.collect(c, "resources", @window, http: inventory_http(self()))

    assert Enum.sort(Enum.map(rows, & &1["service"])) == ["EBS", "EC2", "EC2", "S3"]
    assert Enum.all?(rows, &(&1["region"] == "us-east-1"))

    assert Enum.any?(
             rows,
             &(&1["id"] == "aws:123456789012:us-east-1:instance/i-a" and
                 &1["name"] == "Test instance")
           )

    assert_receive {:wire, _, _, _, _}
    assert_receive {:wire, _, _, body, opts}
    assert URI.decode_query(body)["Action"] == "DescribeInstances"
    assert opts[:response_format] == :raw
    assert opts[:content_type] == "application/x-www-form-urlencoded; charset=utf-8"

    assert {:error, "resourceLimitExceeded", nil} =
             AWS.collect(c, "resources", @window, http: inventory_http(self()), max_resources: 3)
  end

  test "empty inventory is known only with valid response structure and any later page failure aborts",
       %{c: c} do
    http = fn _, url, _, body, _ ->
      cond do
        String.contains?(url, "sts.") ->
          ok(identity())

        String.contains?(url, "s3.") ->
          ok("<ListAllMyBucketsResult><Buckets/></ListAllMyBucketsResult>")

        URI.decode_query(body)["Action"] == "DescribeInstances" ->
          ok("<DescribeInstancesResponse><reservationSet/></DescribeInstancesResponse>")

        true ->
          ok("<DescribeVolumesResponse><volumeSet/></DescribeVolumesResponse>")
      end
    end

    assert {:ok, %{records: [], status: %{"state" => "empty"}}} =
             AWS.collect(c, "resources", @window, http: http)

    malformed = fn method, url, headers, body, opts ->
      if String.contains?(url, "ec2."),
        do: ok("<WrongResponse/>"),
        else: http.(method, url, headers, body, opts)
    end

    assert {:error, "invalidData", nil} = AWS.collect(c, "resources", @window, http: malformed)
    fallback = inventory_http(self())

    failure = fn method, url, headers, body, opts ->
      if String.contains?(url, "ec2.") and URI.decode_query(body)["NextToken"],
        do:
          {:ok,
           %{
             status: 403,
             headers: [],
             body:
               "<Response><Errors><Error><Code>UnauthorizedOperation</Code></Error></Errors></Response>"
           }},
        else: fallback.(method, url, headers, body, opts)
    end

    assert {:error, "permissionDenied", nil} = AWS.collect(c, "resources", @window, http: failure)
  end

  test "S3 pagination token and endpoint region filter are exact", %{c: c} do
    fallback = inventory_http(self())

    http = fn method, url, headers, body, opts ->
      if String.contains?(url, "s3.") do
        query = url |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
        assert query["bucket-region"] == "us-east-1"
        assert query["max-buckets"] == "1000"
        token = query["continuation-token"]
        if token, do: assert(token == "opaque+/= next")

        ok(
          "<ListAllMyBucketsResult><Buckets><Bucket><Name>#{if token, do: "bucket-b", else: "bucket-a"}</Name></Bucket></Buckets>#{if token, do: "", else: "<ContinuationToken>opaque+/= next</ContinuationToken>"}</ListAllMyBucketsResult>"
        )
      else
        fallback.(method, url, headers, body, opts)
      end
    end

    assert {:ok, %{records: rows}} = AWS.collect(c, "resources", @window, http: http)
    assert Enum.count(rows, &(&1["service"] == "S3")) == 2
  end

  test "CloudWatch has native units aggregation intervals and daily S3 storage", %{c: c} do
    settings =
      Map.put(c["settings"], "metricResources", [
        %{"service" => "EC2", "id" => "i-a", "region" => "us-east-1"},
        %{"service" => "EBS", "id" => "vol-a", "region" => "us-east-1"},
        %{"service" => "S3", "id" => "bucket-a", "region" => "us-east-1"}
      ])

    http = fn _, url, _, body, _ ->
      if String.contains?(url, "sts.") do
        ok(identity())
      else
        p = URI.decode_query(body)
        assert p["Action"] == "GetMetricData"
        namespace = p["MetricDataQueries.member.1.MetricStat.Metric.Namespace"]
        assert namespace in ["AWS/EC2", "AWS/EBS", "AWS/S3"]

        assert p["MetricDataQueries.member.1.MetricStat.Period"] ==
                 if(namespace == "AWS/S3", do: "86400", else: "300")

        assert p["MetricDataQueries.member.1.MetricStat.Stat"] ==
                 if(namespace == "AWS/EBS", do: "Sum", else: "Average")

        ok(
          "<GetMetricDataResponse><GetMetricDataResult><MetricDataResults><member><Id>m1</Id><StatusCode>Complete</StatusCode><Timestamps><member>2026-10-01T00:00:00Z</member></Timestamps><Values><member>1.25E+2</member></Values></member></MetricDataResults></GetMetricDataResult></GetMetricDataResponse>"
        )
      end
    end

    assert {:ok, %{records: rows, status: %{"complete" => false, "sourceAsOf" => nil}}} =
             AWS.collect(%{c | "settings" => settings}, "usage", @window, http: http)

    assert Enum.all?(rows, &(&1["value"] == "125"))

    assert Enum.any?(
             rows,
             &(&1["metric"] == "BucketSizeBytes:StandardStorage" and &1["granularity"] == "1d" and
                 &1["unit"] == "Bytes")
           )

    assert Enum.any?(
             rows,
             &(&1["metric"] == "CPUUtilization" and &1["aggregation"] == "Average" and
                 &1["unit"] == "Percent")
           )

    assert Enum.any?(rows, &(&1["metric"] == "VolumeReadOps" and &1["unit"] == "Count"))
  end

  test "explicit metric scope prevents unconfigured resources, unknown services and wide windows",
       %{c: c} do
    http = fn _, _, _, _, _ -> ok(identity()) end
    assert {:error, "unconfigured", nil} = AWS.collect(c, "usage", @window, http: http)

    settings =
      Map.put(c["settings"], "metricResources", [
        %{"service" => "Lambda", "id" => "x", "region" => "us-east-1"}
      ])

    assert {:error, "unsupported", nil} =
             AWS.collect(%{c | "settings" => settings}, "usage", @window, http: http)

    settings =
      Map.put(c["settings"], "metricResources", [
        %{"service" => "EC2", "id" => "i-a", "region" => "us-west-2"}
      ])

    assert {:error, "configurationError", nil} =
             AWS.collect(%{c | "settings" => settings}, "usage", @window, http: http)
  end
end
