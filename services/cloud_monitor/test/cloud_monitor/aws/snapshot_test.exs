defmodule CloudMonitor.Adapters.AWS.SnapshotTest do
  use CloudMonitor.DataCase, async: true
  @moduletag :tmp_dir
  @window %{start: ~U[2026-10-01 00:00:00.000Z], end: ~U[2026-10-03 00:00:00.000Z]}

  setup %{tmp_dir: dir} do
    data = fixture()
    file = Path.join(dir, "explicit-snapshot-test-credentials.json")

    File.write!(
      file,
      JSON.encode!(%{"accessKeyId" => "AKIDEXAMPLE", "secretAccessKey" => "fixture-secret"})
    )

    connection =
      data["connections"]
      |> Enum.find(&(&1["id"] == "aws-main"))
      |> Map.merge(%{
        "credentialRef" => "file:" <> file,
        "settings" => %{
          "accountId" => "123456789012",
          "regions" => ["us-east-1"],
          "metricResources" => [%{"service" => "EC2", "id" => "i-a", "region" => "us-east-1"}]
        }
      })

    :ok = Store.configure(%{data | "connections" => [connection]})
    {:ok, data: data}
  end

  for dataset <- ~w(costs usage) do
    @tag dataset: dataset
    test "ambiguous empty #{dataset} preserves persisted rows and source timestamps", tags do
      dataset = tags.dataset

      row =
        tags.data[dataset]
        |> Enum.find(fn row -> dataset == "usage" or row["connectionId"] == "aws-main" end)
        |> Map.merge(%{
          "start" => "2026-10-01T00:00:00.000Z",
          "end" => "2026-10-02T00:00:00.000Z"
        })

      source_status = %{
        status()
        | "sourceAsOf" => "2026-10-03T00:00:00.000Z",
          "observedStart" => "2026-10-01T00:00:00.000Z",
          "observedEnd" => "2026-10-03T00:00:00.000Z"
      }

      assert {:ok, snapshot} =
               Store.publish("aws-main", dataset, @window, %{
                 records: [row],
                 status: source_status
               })

      previous_rows = Store.records(dataset, "aws-main")
      assert previous_rows != []
      previous_status = Store.connection("aws-main")["statuses"][dataset]
      owner = self()

      http = fn :post, url, headers, body, _opts ->
        send(owner, {:aws_request, url, headers, body})

        response =
          cond do
            String.contains?(url, "sts.") ->
              "<GetCallerIdentityResponse><GetCallerIdentityResult><Account>123456789012</Account></GetCallerIdentityResult></GetCallerIdentityResponse>"

            dataset == "costs" ->
              %{"ResultsByTime" => []}

            true ->
              "<GetMetricDataResponse><GetMetricDataResult><MetricDataResults/></GetMetricDataResult></GetMetricDataResponse>"
          end

        {:ok, %{status: 200, headers: [], body: response}}
      end

      assert {:ok, job} = Jobs.enqueue("aws-main", dataset, @window)
      attempted_at = Store.now()

      result =
        Jobs.run(job.id,
          adapter: CloudMonitor.Adapters.AWS,
          adapter_opts: [http: http]
        )

      assert Store.records(dataset, "aws-main") == previous_rows
      assert Repo.get!(Snapshot, snapshot.id).revision == snapshot.revision
      assert {:error, "waiting"} = result
      assert Repo.get!(Job, job.id).error_code == "waiting"
      current_status = Store.connection("aws-main")["statuses"][dataset]
      assert current_status["state"] == "waiting"
      assert current_status["reason"] == "waiting"
      refute current_status["complete"]

      for field <- ~w(lastSuccessAt sourceAsOf observedStart observedEnd) do
        assert current_status[field] == previous_status[field]
      end

      {:ok, last_attempt, _} = DateTime.from_iso8601(current_status["lastAttemptAt"])
      assert DateTime.compare(last_attempt, attempted_at) in [:eq, :gt]
      assert_receive {:aws_request, "https://sts.us-east-1.amazonaws.com/", _, sts_body}
      assert URI.decode_query(sts_body)["Action"] == "GetCallerIdentity"
      assert_receive {:aws_request, endpoint, signed_headers, request_body}

      assert Enum.any?(signed_headers, fn {name, value} ->
               String.downcase(name) == "authorization" and String.starts_with?(value, "AWS4-")
             end)

      if dataset == "costs" do
        assert endpoint == "https://ce.us-east-1.amazonaws.com/"
        assert JSON.decode!(request_body)["Metrics"] == ["UnblendedCost"]
      else
        assert endpoint == "https://monitoring.us-east-1.amazonaws.com/"
        assert URI.decode_query(request_body)["Action"] == "GetMetricData"
      end
    end
  end
end
