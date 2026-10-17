defmodule CloudMonitor.Adapters.AWS do
  @moduledoc "Bounded read-only AWS Cost Explorer, inventory and CloudWatch adapter."
  @behaviour CloudMonitor.Adapter
  alias CloudMonitor.{Credentials, Domain}
  alias CloudMonitor.Adapters.AWS.{XML, Signature}
  @form "application/x-www-form-urlencoded; charset=utf-8"
  @json "application/x-amz-json-1.1"
  @cost_coverage [
    "CostExplorerUnblendedCost",
    "serviceAndLinkedAccountAggregate",
    "resourceCostUnallocated",
    "categoryNotSeparated",
    "sourceWatermarkUnknown"
  ]

  @impl true
  def collect(connection, dataset, window, opts) do
    with {:ok, context} <- context(connection, window, opts),
         {:ok, context} <- verify_account(context) do
      case dataset do
        "costs" -> costs(context)
        "resources" -> resources(context)
        "usage" -> usage(context)
        _ -> {:error, "unsupported", nil}
      end
    else
      {:error, code} -> {:error, code, nil}
      {:error, _, _} = error -> error
    end
  end

  defp context(connection, window, opts) do
    settings = Map.get(connection, "settings", %{})
    regions = settings["regions"]
    account = settings["accountId"]

    with true <- is_binary(account) and Regex.match?(~r/^\d{12}$/, account),
         true <-
           is_list(regions) and regions != [] and length(regions) <= 20 and
             Enum.all?(
               regions,
               &(is_binary(&1) and Regex.match?(~r/^[a-z]{2}-(?:[a-z]+-)*[a-z]+-\d+$/, &1) and
                   not String.starts_with?(&1, ["cn-", "us-gov-"]))
             ),
         true <- Domain.valid_window?(window.start, window.end),
         {:ok, raw} <- Credentials.read(connection["credentialRef"]),
         {:ok, credentials} when is_map(credentials) <- JSON.decode(raw),
         true <-
           Enum.all?(
             ~w(accessKeyId secretAccessKey),
             &(is_binary(credentials[&1]) and credentials[&1] != "")
           ),
         true <- credentials["sessionToken"] == nil or is_binary(credentials["sessionToken"]),
         true <- valid_expiration?(credentials, Keyword.get(opts, :now, DateTime.utc_now())) do
      {:ok,
       %{
         connection: connection,
         settings: settings,
         credentials: credentials,
         window: window,
         http: Keyword.get(opts, :http, CloudMonitor.HTTP),
         now: Keyword.get(opts, :now, DateTime.utc_now()),
         remaining: Keyword.get(opts, :request_budget, 100),
         max_pages: Keyword.get(opts, :max_pages, 100),
         max_resources: Keyword.get(opts, :max_resources, 1000),
         opts: opts
       }}
    else
      {:error, "unconfigured"} -> {:error, "unconfigured"}
      _ -> {:error, "configurationError"}
    end
  end

  defp valid_expiration?(%{"expiration" => expiration}, now) do
    case Domain.timestamp(expiration) do
      {:ok, time} -> DateTime.compare(time, now) == :gt
      _ -> false
    end
  end

  defp valid_expiration?(_, _), do: true

  defp verify_account(context) do
    with {:ok, doc, context} <-
           query(context, "sts", hd(context.settings["regions"]), %{
             "Action" => "GetCallerIdentity",
             "Version" => "2011-06-15"
           }),
         true <-
           XML.value(doc, ["GetCallerIdentityResult", "Account"]) == context.settings["accountId"] do
      {:ok, context}
    else
      false -> {:error, "configurationError", nil}
      error -> error
    end
  end

  defp costs(context) do
    accounts = Map.get(context.settings, "linkedAccountIds", [context.settings["accountId"]])

    if is_list(accounts) and accounts != [] and length(accounts) <= 100 and
         Enum.all?(accounts, &(is_binary(&1) and Regex.match?(~r/^\d{12}$/, &1))) do
      start = DateTime.to_date(context.window.start) |> Date.to_iso8601()
      finish = DateTime.to_date(context.window.end) |> Date.to_iso8601()
      # Cost Explorer accepts date-only UTC boundaries. Never silently truncate a time-of-day.
      if midnight?(context.window.start) and midnight?(context.window.end) do
        base = %{
          "TimePeriod" => %{"Start" => start, "End" => finish},
          "Granularity" => "DAILY",
          "Metrics" => ["UnblendedCost"],
          "GroupBy" => [
            %{"Type" => "DIMENSION", "Key" => "SERVICE"},
            %{"Type" => "DIMENSION", "Key" => "LINKED_ACCOUNT"}
          ],
          "Filter" => %{"Dimensions" => %{"Key" => "LINKED_ACCOUNT", "Values" => accounts}}
        }

        fetch = fn ctx, token ->
          body = if token, do: Map.put(base, "NextPageToken", token), else: base

          with {:ok, response, ctx} <-
                 request(
                   ctx,
                   :post,
                   "ce",
                   "us-east-1",
                   "/",
                   JSON.encode!(body),
                   :json,
                   "AWSInsightsIndexService.GetCostAndUsage"
                 ),
               {:ok, rows} <- cost_rows(response, ctx, accounts) do
            {:ok, rows, response["NextPageToken"], ctx}
          end
        end

        with {:ok, [_ | _] = records, _} <- pages(context, fetch) do
          {:ok,
           %{
             records: records,
             status:
               status(
                 "partial",
                 false,
                 "costExplorerSourceWatermarkUnavailable"
               )
           }}
        else
          {:ok, [], _} -> {:error, "waiting", nil}
          error -> error
        end
      else
        {:error, "configurationError", nil}
      end
    else
      {:error, "configurationError", nil}
    end
  end

  defp midnight?(time),
    do:
      time.hour == 0 and time.minute == 0 and time.second == 0 and elem(time.microsecond, 0) == 0

  defp cost_rows(%{"ResultsByTime" => buckets}, context, accounts) when is_list(buckets) do
    Enum.reduce_while(buckets, {:ok, []}, fn bucket, {:ok, acc} ->
      with %{"Start" => start, "End" => finish} <- bucket["TimePeriod"],
           {:ok, first} <- Date.from_iso8601(start),
           {:ok, last} <- Date.from_iso8601(finish),
           true <- Date.compare(first, last) == :lt,
           groups when is_list(groups) <- bucket["Groups"],
           estimated when is_boolean(estimated) <- bucket["Estimated"],
           {:ok, rows} <- cost_groups(groups, context, accounts, start, finish, estimated) do
        {:cont, {:ok, acc ++ rows}}
      else
        _ -> {:halt, {:error, "invalidData", nil}}
      end
    end)
  end

  defp cost_rows(_, _, _), do: {:error, "invalidData", nil}

  defp cost_groups(groups, context, accounts, start, finish, estimated) do
    Enum.reduce_while(groups, {:ok, []}, fn group, {:ok, acc} ->
      with [service, account] when is_binary(service) <- group["Keys"],
           true <- account in accounts,
           %{"Amount" => value, "Unit" => currency} when is_binary(currency) <-
             get_in(group, ["Metrics", "UnblendedCost"]),
           {:ok, _} <- Domain.decimal(value) do
        row = %{
          "id" =>
            stable("aws:cost", [
              context.connection["billingScopeId"],
              account,
              service,
              start,
              finish,
              "UnblendedCost"
            ]),
          "connectionId" => context.connection["id"],
          "billingScopeId" => context.connection["billingScopeId"],
          "service" => service,
          "resourceId" => nil,
          "start" => start <> "T00:00:00.000Z",
          "end" => finish <> "T00:00:00.000Z",
          "currency" => currency,
          "amount" => value,
          "basis" => "UnblendedCost",
          "category" => "unknown",
          "estimated" => estimated,
          "source" => "AWS Cost Explorer GetCostAndUsage",
          "sourcePrecision" => "sourceDecimalString",
          "invoiceMonth" => nil,
          "recordKind" => "reported",
          "view" => "period",
          "coverage" => @cost_coverage
        }

        {:cont, {:ok, acc ++ [row]}}
      else
        _ -> {:halt, {:error, "invalidData", nil}}
      end
    end)
  end

  defp resources(context) do
    result =
      Enum.reduce_while(context.settings["regions"], {:ok, [], context}, fn region,
                                                                            {:ok, acc, ctx} ->
        with {:ok, instances, ctx} <- ec2_inventory(ctx, region, "DescribeInstances"),
             {:ok, volumes, ctx} <- ec2_inventory(ctx, region, "DescribeVolumes"),
             {:ok, buckets, ctx} <- s3_inventory(ctx, region),
             true <-
               length(acc) + length(instances) + length(volumes) + length(buckets) <=
                 ctx.max_resources do
          {:cont, {:ok, acc ++ instances ++ volumes ++ buckets, ctx}}
        else
          false -> {:halt, {:error, "resourceLimitExceeded", nil}}
          error -> {:halt, error}
        end
      end)

    with {:ok, rows, _} <- result do
      {:ok,
       %{
         records: rows,
         status:
           status(if(rows == [], do: "empty", else: "available"), true, "scopedEC2EBSS3Inventory")
       }}
    end
  end

  defp ec2_inventory(context, region, action) do
    fetch = fn ctx, token ->
      params = %{"Action" => action, "Version" => "2016-11-15", "MaxResults" => "1000"}
      params = if token, do: Map.put(params, "NextToken", token), else: params

      with {:ok, doc, ctx} <- query(ctx, "ec2", region, params),
           {:ok, rows} <- inventory_rows(doc, ctx, region, action) do
        {:ok, rows, XML.value(doc, ["nextToken"]), ctx}
      end
    end

    pages(context, fetch)
  end

  defp inventory_rows(doc, context, region, action) do
    container = if action == "DescribeInstances", do: "reservationSet", else: "volumeSet"

    with :ok <- valid_response(doc, action <> "Response", [container]) do
      parsed_inventory_rows(doc, context, region, action)
    end
  end

  defp parsed_inventory_rows(doc, context, region, "DescribeInstances") do
    nodes =
      doc
      |> XML.path(["reservationSet"])
      |> XML.children("item")
      |> Enum.flat_map(fn r -> r |> XML.path(["instancesSet"]) |> XML.children("item") end)

    map_inventory(nodes, fn item ->
      id = XML.value(item, ["instanceId"])
      tags = tags(item)

      resource(
        context,
        region,
        "EC2",
        "instance",
        id,
        tags["Name"] || id,
        tags,
        XML.value(item, ["instanceState", "name"])
      )
    end)
  end

  defp parsed_inventory_rows(doc, context, region, "DescribeVolumes") do
    nodes = doc |> XML.path(["volumeSet"]) |> XML.children("item")

    map_inventory(nodes, fn item ->
      id = XML.value(item, ["volumeId"])
      tags = tags(item)

      resource(
        context,
        region,
        "EBS",
        "volume",
        id,
        tags["Name"] || id,
        tags,
        XML.value(item, ["status"])
      )
    end)
  end

  defp map_inventory(nodes, mapper) do
    Enum.reduce_while(nodes, {:ok, []}, fn node, {:ok, rows} ->
      case mapper.(node) do
        {:ok, row} -> {:cont, {:ok, rows ++ [row]}}
        error -> {:halt, error}
      end
    end)
  end

  defp tags(item),
    do:
      item
      |> XML.path(["tagSet"])
      |> XML.children("item")
      |> Map.new(&{XML.value(&1, ["key"]), XML.value(&1, ["value"])})

  defp s3_inventory(context, region) do
    fetch = fn ctx, token ->
      params =
        [{"bucket-region", region}, {"max-buckets", "1000"}] ++
          if(token, do: [{"continuation-token", token}], else: [])

      path = "/?" <> URI.encode_query(params)

      with {:ok, doc, ctx} <- request(ctx, :get, "s3", region, path, "", :xml),
           :ok <- valid_response(doc, "ListAllMyBucketsResult", ["Buckets"]),
           {:ok, rows} <-
             map_inventory(doc |> XML.path(["Buckets"]) |> XML.children("Bucket"), fn node ->
               id = XML.value(node, ["Name"])
               returned_region = XML.value(node, ["BucketRegion"])

               if returned_region in [nil, region],
                 do: resource(ctx, region, "S3", "bucket", id, id, %{}, nil),
                 else: {:error, "invalidData", nil}
             end) do
        {:ok, rows, XML.value(doc, ["ContinuationToken"]), ctx}
      end
    end

    pages(context, fetch)
  end

  defp resource(context, region, service, type, id, name, tags, state)
       when is_binary(id) and byte_size(id) > 0 do
    {:ok,
     %{
       "id" => resource_id(context, region, type, id),
       "connectionId" => context.connection["id"],
       "billingScopeId" => context.connection["billingScopeId"],
       "service" => service,
       "type" => type,
       "region" => region,
       "name" => name,
       "tags" => tags,
       "observedAt" => DateTime.to_iso8601(context.now),
       "state" => state
     }}
  end

  defp resource(_, _, _, _, _, _, _, _), do: {:error, "invalidData", nil}

  defp resource_id(context, region, type, id),
    do: "aws:#{context.settings["accountId"]}:#{region}:#{type}/#{id}"

  defp usage(context) do
    configured = Map.get(context.settings, "metricResources", [])
    max_days = min(Map.get(context.settings, "metricsWindowDays", 7), 14)

    cond do
      configured == [] ->
        {:error, "unconfigured", nil}

      not is_list(configured) or length(configured) > context.max_resources ->
        {:error, "resourceLimitExceeded", nil}

      DateTime.diff(context.window.end, context.window.start) > max_days * 86_400 ->
        {:error, "configurationError", nil}

      true ->
        collect_metrics(context, configured)
    end
  end

  defp collect_metrics(context, configured) do
    result =
      Enum.reduce_while(configured, {:ok, [], context}, fn spec, {:ok, rows, ctx} ->
        with true <- spec["region"] in ctx.settings["regions"],
             true <- is_binary(spec["id"]) and spec["id"] != "",
             {:ok, definitions} <- metric_definitions(spec),
             {:ok, samples, ctx} <- metric_data(ctx, spec, definitions),
             true <- length(rows) + length(samples) <= Keyword.get(ctx.opts, :max_records, 10_000) do
          {:cont, {:ok, rows ++ samples, ctx}}
        else
          false -> {:halt, {:error, "configurationError", nil}}
          error -> {:halt, error}
        end
      end)

    with {:ok, [_ | _] = rows, _} <- result do
      {:ok,
       %{
         records: rows,
         status:
           status(
             "partial",
             false,
             "configuredMetricsOnlyNoRequestMetrics"
           )
       }}
    else
      {:ok, [], _} -> {:error, "waiting", nil}
      error -> error
    end
  end

  defp metric_definitions(%{"service" => "EC2"}),
    do:
      {:ok,
       [
         {"CPUUtilization", "Percent", "Average", 300, [{"InstanceId", nil}]},
         {"NetworkIn", "Bytes", "Sum", 300, [{"InstanceId", nil}]},
         {"NetworkOut", "Bytes", "Sum", 300, [{"InstanceId", nil}]}
       ]}

  defp metric_definitions(%{"service" => "EBS"}),
    do:
      {:ok,
       Enum.map(~w(VolumeReadOps VolumeWriteOps), &{&1, "Count", "Sum", 300, [{"VolumeId", nil}]}) ++
         Enum.map(
           ~w(VolumeReadBytes VolumeWriteBytes),
           &{&1, "Bytes", "Sum", 300, [{"VolumeId", nil}]}
         )}

  defp metric_definitions(%{"service" => "S3"} = spec) do
    classes = Map.get(spec, "storageTypes", ["StandardStorage"])

    if is_list(classes) and classes != [] and length(classes) <= 16 and
         Enum.all?(classes, &(is_binary(&1) and Regex.match?(~r/^[A-Za-z]+Storage$/, &1))) do
      {:ok,
       Enum.map(
         classes,
         &{"BucketSizeBytes", "Bytes", "Average", 86_400,
          [{"BucketName", nil}, {"StorageType", &1}]}
       ) ++
         [
           {"NumberOfObjects", "Count", "Average", 86_400,
            [{"BucketName", nil}, {"StorageType", "AllStorageTypes"}]}
         ]}
    else
      {:error, "configurationError", nil}
    end
  end

  defp metric_definitions(_), do: {:error, "unsupported", nil}

  defp metric_data(context, spec, definitions) do
    indexed =
      definitions
      |> Enum.with_index(1)
      |> Map.new(fn {definition, i} -> {"m#{i}", definition} end)

    params =
      Enum.reduce(
        indexed,
        %{
          "Action" => "GetMetricData",
          "Version" => "2010-08-01",
          "StartTime" => DateTime.to_iso8601(context.window.start),
          "EndTime" => DateTime.to_iso8601(context.window.end),
          "ScanBy" => "TimestampAscending",
          "MaxDatapoints" => "10080"
        },
        fn {id, {metric, unit, aggregation, period, dimensions}}, acc ->
          prefix = "MetricDataQueries.member." <> String.trim_leading(id, "m")

          dimension_params =
            dimensions
            |> Enum.with_index(1)
            |> Enum.flat_map(fn {{key, value}, i} ->
              [
                {prefix <> ".MetricStat.Metric.Dimensions.member.#{i}.Name", key},
                {prefix <> ".MetricStat.Metric.Dimensions.member.#{i}.Value", value || spec["id"]}
              ]
            end)

          Map.merge(
            acc,
            Map.new(
              [
                {prefix <> ".Id", id},
                {prefix <> ".ReturnData", "true"},
                {prefix <> ".MetricStat.Metric.Namespace", "AWS/" <> spec["service"]},
                {prefix <> ".MetricStat.Metric.MetricName", metric},
                {prefix <> ".MetricStat.Period", to_string(period)},
                {prefix <> ".MetricStat.Stat", aggregation},
                {prefix <> ".MetricStat.Unit", unit}
              ] ++ dimension_params
            )
          )
        end
      )

    fetch = fn ctx, token ->
      body = if token, do: Map.put(params, "NextToken", token), else: params

      with {:ok, doc, ctx} <- query(ctx, "monitoring", spec["region"], body),
           {:ok, samples} <- metric_rows(doc, ctx, spec, indexed) do
        {:ok, samples, XML.value(doc, ["GetMetricDataResult", "NextToken"]), ctx}
      end
    end

    pages(context, fetch)
  end

  defp valid_response(doc, root, path) do
    if XML.name(doc) == root and XML.path(doc, path) != nil,
      do: :ok,
      else: {:error, "invalidData", nil}
  end

  defp metric_rows(doc, context, spec, definitions) do
    with :ok <-
           valid_response(doc, "GetMetricDataResponse", [
             "GetMetricDataResult",
             "MetricDataResults"
           ]) do
      parsed_metric_rows(doc, context, spec, definitions)
    end
  end

  defp parsed_metric_rows(doc, context, spec, definitions) do
    members =
      doc |> XML.path(["GetMetricDataResult", "MetricDataResults"]) |> XML.children("member")

    Enum.reduce_while(members, {:ok, []}, fn node, {:ok, rows} ->
      id = XML.value(node, ["Id"])

      with {metric, unit, aggregation, period, dimensions} <- definitions[id],
           true <- XML.value(node, ["StatusCode"]) in ["Complete", "PartialData"],
           timestamps =
             node |> XML.path(["Timestamps"]) |> XML.children("member") |> Enum.map(&XML.value/1),
           values =
             node |> XML.path(["Values"]) |> XML.children("member") |> Enum.map(&XML.value/1),
           true <- length(timestamps) == length(values),
           {:ok, samples} <-
             samples(
               context,
               spec,
               metric,
               unit,
               aggregation,
               period,
               dimensions,
               Enum.zip(timestamps, values)
             ) do
        {:cont, {:ok, rows ++ samples}}
      else
        _ -> {:halt, {:error, "invalidData", nil}}
      end
    end)
  end

  defp samples(context, spec, metric, unit, aggregation, period, dimensions, points) do
    type =
      case spec["service"] do
        "EC2" -> "instance"
        "EBS" -> "volume"
        "S3" -> "bucket"
      end

    resource = resource_id(context, spec["region"], type, spec["id"])
    # StorageType is a distinct metric series, not a second total for the bucket.
    storage = Enum.find_value(dimensions, fn {k, v} -> if k == "StorageType", do: v end)
    label = if storage, do: metric <> ":" <> storage, else: metric

    Enum.reduce_while(points, {:ok, []}, fn {timestamp, raw}, {:ok, rows} ->
      with {:ok, start} <- Domain.timestamp(timestamp), {:ok, value} <- metric_decimal(raw) do
        finish = DateTime.add(start, period)

        if DateTime.compare(start, context.window.start) == :lt or
             DateTime.compare(finish, context.window.end) == :gt do
          {:cont, {:ok, rows}}
        else
          row = %{
            "id" =>
              stable("aws:usage", [resource, label, timestamp, to_string(period), aggregation]),
            "resourceId" => resource,
            "service" => spec["service"],
            "metric" => label,
            "unit" => unit,
            "start" => DateTime.to_iso8601(start),
            "end" => DateTime.to_iso8601(finish),
            "granularity" => if(period == 86_400, do: "1d", else: "5m"),
            "aggregation" => aggregation,
            "value" => value,
            "source" => "AWS CloudWatch GetMetricData (source double)"
          }

          {:cont, {:ok, rows ++ [row]}}
        end
      else
        _ -> {:halt, {:error, "invalidData", nil}}
      end
    end)
  end

  defp metric_decimal(raw) when is_binary(raw) do
    if byte_size(raw) <= 128 and Regex.match?(~r/^-?\d+(\.\d+)?([eE][+-]?\d{1,3})?$/, raw) do
      decimal = Decimal.new(raw)
      if abs(decimal.exp) <= 300, do: {:ok, Domain.amount(decimal)}, else: {:error, "invalidData"}
    else
      {:error, "invalidData"}
    end
  end

  defp metric_decimal(_), do: {:error, "invalidData"}

  defp query(context, service, region, params),
    do: request(context, :post, service, region, "/", URI.encode_query(Enum.sort(params)), :xml)

  defp request(context, method, service, region, path, body, format, target \\ nil) do
    if context.remaining <= 0 do
      {:error, "requestBudgetExceeded", nil}
    else
      url = "https://#{service}.#{region}.amazonaws.com" <> path
      type = if format == :json, do: @json, else: @form
      headers = if method == :post, do: [{"content-type", type}], else: []
      headers = if target, do: [{"x-amz-target", target} | headers], else: headers
      signing_service = if service == "monitoring", do: "monitoring", else: service

      headers =
        Signature.sign(
          context.credentials,
          region,
          signing_service,
          context.now,
          method,
          url,
          headers,
          body
        )

      opts = [
        response_format: if(format == :xml, do: :raw, else: :json),
        content_type: type,
        timeout: 30_000
      ]

      response =
        if is_function(context.http, 5),
          do: context.http.(method, url, headers, body, opts),
          else: context.http.request(method, url, headers, body, opts)

      ctx = %{context | remaining: context.remaining - 1}

      case response do
        {:ok, %{status: code, body: payload}} when code in 200..299 ->
          if format == :xml do
            with {:ok, doc} <- XML.parse(payload), do: {:ok, doc, ctx}
          else
            if is_map(payload), do: {:ok, payload, ctx}, else: {:error, "invalidData", nil}
          end

        {:ok, response} ->
          http_error(response)

        {:error, code} ->
          {:error,
           if(code in ~w(networkFailure responseTooLarge invalidData), do: code, else: "failed"),
           nil}
      end
    end
  end

  defp http_error(%{status: status, body: body} = response) do
    code = if is_map(body), do: body["__type"] || body["code"] || "", else: xml_error(body)

    result =
      cond do
        status == 429 or String.contains?(code, ["Throttl", "LimitExceeded"]) ->
          "rateLimited"

        String.contains?(code, "DataUnavailable") ->
          "waiting"

        status == 401 or
            String.contains?(code, [
              "ExpiredToken",
              "InvalidClientTokenId",
              "SignatureDoesNotMatch",
              "UnrecognizedClient",
              "AuthFailure"
            ]) ->
          "authenticationFailed"

        status == 403 or String.contains?(code, ["AccessDenied", "UnauthorizedOperation"]) ->
          "permissionDenied"

        true ->
          "failed"
      end

    retry =
      if result == "rateLimited", do: retry_after(Map.get(response, :headers, [])), else: nil

    {:error, result, retry}
  end

  defp xml_error(body) do
    case XML.parse(body) do
      {:ok, doc} ->
        XML.value(doc, ["Errors", "Error", "Code"]) || XML.value(doc, ["Error", "Code"]) ||
          XML.value(doc, ["Code"]) || ""

      _ ->
        ""
    end
  end

  defp retry_after(headers) do
    value =
      Enum.find_value(headers, fn {k, v} -> if String.downcase(k) == "retry-after", do: v end)

    case Integer.parse(value || "") do
      {n, ""} when n >= 0 -> n
      _ -> nil
    end
  end

  defp pages(context, fetch), do: do_pages(context, fetch, nil, MapSet.new(), [], 0)

  defp do_pages(context, fetch, token, seen, rows, count) do
    cond do
      count >= context.max_pages ->
        {:error, "requestBudgetExceeded", nil}

      MapSet.member?(seen, token) ->
        {:error, "paginationCycle", nil}

      true ->
        with {:ok, page, next, context} <- fetch.(context, token) do
          combined = rows ++ page
          maximum = Keyword.get(context.opts, :max_records, 10_000)

          cond do
            length(combined) > maximum -> {:error, "resourceLimitExceeded", nil}
            next in [nil, ""] -> {:ok, combined, context}
            not is_binary(next) -> {:error, "invalidData", nil}
            true -> do_pages(context, fetch, next, MapSet.put(seen, token), combined, count + 1)
          end
        else
          {:error, code} -> {:error, code, nil}
          error -> error
        end
    end
  end

  defp status(state, complete, reason),
    do: %{
      "state" => state,
      "complete" => complete,
      "sourceAsOf" => nil,
      "observedStart" => nil,
      "observedEnd" => nil,
      "reason" => reason
    }

  defp stable(prefix, fields),
    do:
      prefix <>
        ":" <>
        (:crypto.hash(:sha256, :erlang.term_to_binary(fields))
         |> Base.url_encode64(padding: false))
end
