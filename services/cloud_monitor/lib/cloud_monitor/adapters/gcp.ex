defmodule CloudMonitor.Adapters.GCP do
  @moduledoc "Read-only configured GCP billing export, inventory and Monitoring adapter."
  @behaviour CloudMonitor.Adapter
  alias CloudMonitor.{Credentials, Domain}
  alias CloudMonitor.Adapters.GCP.{Auth, Billing, Transport}
  @project ~r/^[a-z][a-z0-9-]{4,61}[a-z0-9]$/
  @region ~r/^[a-z][a-z0-9-]{1,62}$/

  @impl true
  def collect(connection, dataset, window, opts \\ []) do
    with :ok <- configuration(connection, dataset, window),
         {:ok, raw} <- Credentials.read(connection["credentialRef"]) do
      ctx = %{
        connection: connection,
        settings: Map.put_new(connection["settings"], "location", "US"),
        opts: opts,
        http: Keyword.get(opts, :http, CloudMonitor.HTTP),
        token: nil,
        now: Keyword.get(opts, :now, DateTime.utc_now()),
        window: window,
        remaining: Keyword.get(opts, :request_budget, 100),
        total: 0
      }

      with {:ok, ctx} <- Auth.authenticate(raw, ctx) do
        case dataset do
          "costs" -> Billing.collect(ctx)
          "resources" -> resources(ctx)
          "usage" -> usage(ctx)
        end
      end
    else
      {:error, code} -> {:error, code, nil}
      error -> error
    end
  end

  defp configuration(c, dataset, %{start: %DateTime{} = start, end: %DateTime{} = finish}) do
    s = c["settings"]

    cond do
      dataset not in ~w(costs resources usage) ->
        {:error, "unsupported", nil}

      not Domain.valid_window?(start, finish) ->
        {:error, "invalidQuery", nil}

      not text?(c["id"]) or not text?(c["billingScopeId"]) or not is_map(s) ->
        {:error, "invalidConfiguration", nil}

      not is_list(s["projects"]) or s["projects"] == [] or length(s["projects"]) > 50 ->
        {:error, "invalidConfiguration", nil}

      not Enum.all?(s["projects"], &valid?(@project, &1)) ->
        {:error, "invalidConfiguration", nil}

      dataset == "costs" and not billing_config?(s) ->
        {:error, "invalidConfiguration", nil}

      dataset == "resources" and not locations?(s["cloudRunLocations"]) ->
        {:error, "invalidConfiguration", nil}

      dataset == "usage" and not metrics_config?(s) ->
        {:error, "invalidConfiguration", nil}

      true ->
        :ok
    end
  end

  defp configuration(_, _, _), do: {:error, "invalidQuery", nil}

  defp billing_config?(s) do
    table = s["exportTable"]

    valid?(@project, s["queryProject"]) and
      valid?(~r/^[A-Za-z0-9]{6}-[A-Za-z0-9]{6}-[A-Za-z0-9]{6}$/, s["billingAccountId"]) and
      is_binary(table) and match?([_, _, _], String.split(table, ".")) and
      table_identifier?(String.split(table, ".")) and
      valid?(~r/^[A-Za-z][A-Za-z0-9-]{1,62}$/, Map.get(s, "location", "US"))
  end

  defp table_identifier?([p, d, t]),
    do:
      valid?(@project, p) and Enum.all?([d, t], &valid?(~r/^[A-Za-z_][A-Za-z0-9_]{0,1023}$/, &1))

  defp locations?(locations),
    do:
      is_list(locations) and locations != [] and length(locations) <= 20 and
        Enum.all?(locations, &valid?(@region, &1))

  defp metrics_config?(s) do
    metrics = Map.get(s, "metrics", [])

    is_list(metrics) and
      Enum.all?(metrics, fn metric ->
        is_map(metric) and metric["project"] in s["projects"] and metric_scope?(metric)
      end)
  end

  defp metric_scope?(%{"kind" => kind} = m)
       when kind in ~w(gceCpu gceNetworkReceived gceNetworkSent),
       do: valid?(~r/^\d{1,32}$/, m["instanceId"]) and valid?(@region, m["zone"])

  defp metric_scope?(%{"kind" => "gcsStorage"} = m),
    do: valid?(~r/^[a-z0-9][a-z0-9._-]{1,220}[a-z0-9]$/, m["bucket"])

  defp metric_scope?(%{"kind" => "cloudRunRequests"} = m),
    do:
      valid?(@region, m["location"]) and valid?(~r/^[a-z][a-z0-9-]{0,61}[a-z0-9]$/, m["service"])

  defp metric_scope?(_), do: false

  defp resources(ctx) do
    collections =
      for project <- Enum.uniq(ctx.settings["projects"]),
          entry <- inventories(project, ctx.settings["cloudRunLocations"]),
          do: entry

    result =
      Enum.reduce_while(collections, {:ok, [], ctx}, fn {kind, project, url, query},
                                                        {:ok, records, ctx} ->
        with {:ok, rows, ctx} <- pages(ctx, url, query, kind),
             {:ok, batch} <- map_rows(rows, &resource(&1, kind, project, ctx)) do
          {:cont, {:ok, records ++ batch, ctx}}
        else
          error -> {:halt, error}
        end
      end)

    with {:ok, records, ctx} <- result do
      output(
        ctx,
        records,
        if(records == [], do: "empty", else: "available"),
        true,
        "configuredProjectsAndCloudRunLocationsOnly;types=GCEInstances,GCEDisks,StorageBuckets,CloudRunServices"
      )
    else
      {:error, "notFound", _} -> {:error, "unsupported", nil}
      error -> error
    end
  end

  defp inventories(project, locations) do
    [
      {:instances, project,
       "https://compute.googleapis.com/compute/v1/projects/#{project}/aggregated/instances",
       %{"maxResults" => 100, "returnPartialSuccess" => false}},
      {:disks, project,
       "https://compute.googleapis.com/compute/v1/projects/#{project}/aggregated/disks",
       %{"maxResults" => 100, "returnPartialSuccess" => false}},
      {:buckets, project, "https://storage.googleapis.com/storage/v1/b",
       %{"project" => project, "maxResults" => 100}}
    ] ++
      Enum.map(
        Enum.uniq(locations),
        &{:services, project,
         "https://run.googleapis.com/v2/projects/#{project}/locations/#{&1}/services",
         %{"pageSize" => 100}}
      )
  end

  defp pages(ctx, url, query, kind, seen \\ MapSet.new(), rows \\ []) do
    with {:ok, body, ctx} <- Transport.request(ctx, :get, url, "", query),
         {:ok, batch} <- page_rows(body, kind) do
      ctx = %{ctx | total: ctx.total + length(batch)}
      next = body["nextPageToken"]

      cond do
        ctx.total > Keyword.get(ctx.opts, :max_resources, 1000) ->
          {:error, "resourceLimitExceeded", nil}

        next in [nil, ""] ->
          {:ok, rows ++ batch, ctx}

        not is_binary(next) ->
          {:error, "invalidData", nil}

        MapSet.member?(seen, next) ->
          {:error, "paginationCycle", nil}

        MapSet.size(seen) + 1 >= Keyword.get(ctx.opts, :max_pages, 100) ->
          {:error, "requestBudgetExceeded", nil}

        true ->
          pages(
            ctx,
            url,
            Map.put(query, "pageToken", next),
            kind,
            MapSet.put(seen, next),
            rows ++ batch
          )
      end
    end
  end

  defp page_rows(body, kind) do
    cond do
      (body["unreachables"] || []) != [] or (body["unreachable"] || []) != [] ->
        {:error, "failed", nil}

      kind in [:instances, :disks] ->
        aggregated(body, kind)

      true ->
        key =
          case kind do
            :buckets -> "items"
            :services -> "services"
            :time_series -> "timeSeries"
          end

        case Map.get(body, key, []) do
          rows when is_list(rows) -> {:ok, rows}
          _ -> {:error, "invalidData", nil}
        end
    end
  end

  defp aggregated(body, kind) do
    items = Map.get(body, "items", %{})

    if is_map(items) and benign_warning?(body["warning"]) do
      Enum.reduce_while(items, {:ok, []}, fn {_scope, value}, {:ok, rows} ->
        batch = if is_map(value), do: Map.get(value, Atom.to_string(kind), []), else: nil

        if is_list(batch) and benign_warning?(value["warning"]),
          do: {:cont, {:ok, rows ++ batch}},
          else: {:halt, {:error, "failed", nil}}
      end)
    else
      {:error, "failed", nil}
    end
  end

  defp benign_warning?(nil), do: true
  defp benign_warning?(%{"code" => "NO_RESULTS_ON_PAGE"}), do: true
  defp benign_warning?(_), do: false

  defp resource(row, kind, project, ctx) when is_map(row) do
    {id, service, type, region, name, state} =
      case kind do
        kind when kind in [:instances, :disks] ->
          zone =
            if is_binary(row["zone"]), do: List.last(String.split(row["zone"], "/")), else: ""

          prefix = if kind == :instances, do: "compute", else: "computeDisk"

          {"gcp:#{prefix}:#{project}:#{zone}:#{row["id"]}", "Compute Engine",
           if(kind == :instances, do: "instance", else: "disk"), zone, row["name"], row["status"]}

        :buckets ->
          {"gcp:storage:#{project}:#{row["id"]}", "Cloud Storage", "bucket", row["location"],
           row["name"], nil}

        :services ->
          location =
            if is_binary(row["name"]), do: Enum.at(String.split(row["name"], "/"), 3), else: nil

          {"gcp:#{row["name"]}", "Cloud Run", "service", location, row["name"], nil}
      end

    valid =
      case kind do
        k when k in [:instances, :disks] ->
          valid?(~r/^\d+$/, row["id"]) and valid?(@region, region)

        :buckets ->
          text?(row["id"]) and text?(row["name"])

        :services ->
          text?(row["name"]) and
            String.starts_with?(row["name"], "projects/#{project}/locations/") and
            region in ctx.settings["cloudRunLocations"]
      end

    if valid do
      normalize(
        %{
          "id" => id,
          "connectionId" => ctx.connection["id"],
          "billingScopeId" => ctx.connection["billingScopeId"],
          "service" => service,
          "type" => type,
          "region" => region,
          "name" => name,
          "state" => state,
          "tags" => row["labels"] || %{},
          "observedAt" => DateTime.to_iso8601(ctx.now)
        },
        "resources"
      )
    else
      {:error, "invalidData", nil}
    end
  end

  defp resource(_, _, _, _), do: {:error, "invalidData", nil}

  defp usage(ctx) do
    metrics = ctx.settings["metrics"] || []

    cond do
      metrics == [] ->
        {:error, "unconfigured", nil}

      length(metrics) > Keyword.get(ctx.opts, :max_resources, 1000) ->
        {:error, "resourceLimitExceeded", nil}

      true ->
        result =
          Enum.reduce_while(Enum.uniq(metrics), {:ok, [], ctx}, fn metric, {:ok, records, ctx} ->
            case metric(ctx, metric) do
              {:ok, rows, ctx} -> {:cont, {:ok, records ++ rows, ctx}}
              error -> {:halt, error}
            end
          end)

        with {:ok, records, ctx} <- result do
          if records == [],
            do: {:error, "waiting", nil},
            else:
              output(
                ctx,
                records,
                "partial",
                false,
                "configuredMetricScopesOnly;sourceSamplingAndLatencyApply"
              )
        else
          {:error, "notFound", _} -> {:error, "unsupported", nil}
          error -> error
        end
    end
  end

  defp metric(ctx, scope) do
    {type, kind, unit, aligner, aggregation, resource_type, service, period} = spec(scope["kind"])
    project = scope["project"]
    base = "https://monitoring.googleapis.com/v3/projects/#{project}"

    with {:ok, descriptor, ctx} <-
           Transport.request(ctx, :get, base <> "/metricDescriptors/" <> type),
         true <-
           descriptor["type"] == type and descriptor["metricKind"] == kind and
             descriptor["unit"] == unit and descriptor["valueType"] in ~w(INT64 DOUBLE),
         query = %{
           "filter" => filter(scope, type, resource_type),
           "interval.startTime" =>
             ctx.window.start |> DateTime.add(-1, :microsecond) |> DateTime.to_iso8601(),
           "interval.endTime" =>
             ctx.window.end |> DateTime.add(-1, :microsecond) |> DateTime.to_iso8601(),
           "view" => "FULL",
           "pageSize" => 100,
           "aggregation.alignmentPeriod" => "#{period}s",
           "aggregation.perSeriesAligner" => aligner
         },
         {:ok, series, ctx} <- pages(ctx, base <> "/timeSeries", query, :time_series),
         {:ok, records} <-
           map_rows(
             series,
             &samples(&1, scope, type, unit, aggregation, resource_type, service, period, ctx)
           ) do
      {:ok, records, ctx}
    else
      false -> {:error, "unsupported", nil}
      error -> error
    end
  end

  defp spec("gceCpu"),
    do:
      {"compute.googleapis.com/instance/cpu/utilization", "GAUGE", "10^2.%", "ALIGN_MEAN", "mean",
       "gce_instance", "Compute Engine", 300}

  defp spec("gceNetworkReceived"),
    do:
      {"compute.googleapis.com/instance/network/received_bytes_count", "DELTA", "By", "ALIGN_SUM",
       "sum", "gce_instance", "Compute Engine", 300}

  defp spec("gceNetworkSent"),
    do:
      {"compute.googleapis.com/instance/network/sent_bytes_count", "DELTA", "By", "ALIGN_SUM",
       "sum", "gce_instance", "Compute Engine", 300}

  defp spec("gcsStorage"),
    do:
      {"storage.googleapis.com/storage/total_bytes", "GAUGE", "By", "ALIGN_MAX", "maximum",
       "gcs_bucket", "Cloud Storage", 86_400}

  defp spec("cloudRunRequests"),
    do:
      {"run.googleapis.com/request_count", "DELTA", "1", "ALIGN_SUM", "sum", "cloud_run_revision",
       "Cloud Run", 300}

  defp filter(scope, type, resource_type) do
    fields =
      [
        {"metric.type", type},
        {"resource.type", resource_type},
        {"resource.labels.project_id", scope["project"]}
      ] ++ labels(scope)

    Enum.map_join(fields, " AND ", fn {key, value} -> key <> " = " <> JSON.encode!(value) end)
  end

  defp labels(%{"kind" => kind} = s) when kind in ~w(gceCpu gceNetworkReceived gceNetworkSent),
    do: [{"resource.labels.instance_id", s["instanceId"]}, {"resource.labels.zone", s["zone"]}]

  defp labels(%{"kind" => "gcsStorage"} = s), do: [{"resource.labels.bucket_name", s["bucket"]}]

  defp labels(%{"kind" => "cloudRunRequests"} = s),
    do: [
      {"resource.labels.service_name", s["service"]},
      {"resource.labels.location", s["location"]}
    ]

  defp samples(series, scope, type, unit, aggregation, resource_type, service, period, ctx)
       when is_map(series) do
    labels = get_in(series, ["resource", "labels"])

    valid =
      is_map(labels) and get_in(series, ["resource", "type"]) == resource_type and
        labels["project_id"] == scope["project"] and
        Enum.all?(labels(scope), fn {key, value} ->
          labels[String.replace_prefix(key, "resource.labels.", "")] == value
        end)

    if valid and is_list(series["points"]) do
      map_rows(series["points"], fn point ->
        sample(point, series, scope, type, unit, aggregation, service, period, ctx)
      end)
    else
      {:error, "invalidData", nil}
    end
  end

  defp samples(_, _, _, _, _, _, _, _, _), do: {:error, "invalidData", nil}

  defp sample(
         %{"interval" => interval, "value" => value},
         series,
         scope,
         type,
         unit,
         aggregation,
         service,
         period,
         ctx
       )
       when is_map(interval) and is_map(value) do
    with {:ok, finish} <- Domain.timestamp(interval["endTime"]),
         {:ok, start} <- sample_start(interval, finish),
         {:ok, amount} <- metric_value(value) do
      {start, finish} =
        if start == finish,
          do: {finish, DateTime.add(finish, 1, :microsecond)},
          else: {start, finish}

      if DateTime.compare(finish, ctx.window.start) == :lt or
           DateTime.compare(start, ctx.window.end) != :lt do
        {:ok, []}
      else
        resource = metric_resource(scope)

        normalize(
          %{
            "id" =>
              "gcp:" <>
                Base.url_encode64(
                  :crypto.hash(
                    :sha256,
                    :erlang.term_to_binary(
                      {resource, type, series["metric"], series["resource"], start, finish}
                    )
                  ),
                  padding: false
                ),
            "resourceId" => resource,
            "service" => service,
            "metric" => type,
            "unit" => unit,
            "start" => DateTime.to_iso8601(start),
            "end" => DateTime.to_iso8601(finish),
            "granularity" => "#{period}s",
            "aggregation" => aggregation,
            "value" => amount,
            "source" => "gcp:monitoring"
          },
          "usage"
        )
      end
    else
      _ -> {:error, "invalidData", nil}
    end
  end

  defp sample(_, _, _, _, _, _, _, _, _), do: {:error, "invalidData", nil}
  defp sample_start(%{"startTime" => start}, _), do: Domain.timestamp(start)
  defp sample_start(_, finish), do: {:ok, finish}

  defp metric_value(%{"int64Value" => n}) when is_binary(n) do
    case Domain.decimal(n) do
      {:ok, d} -> {:ok, Domain.amount(d)}
      _ -> {:error, "invalidData"}
    end
  end

  defp metric_value(%{"doubleValue" => n}) when is_float(n),
    do: {:ok, n |> Decimal.from_float() |> Domain.amount()}

  defp metric_value(%{"doubleValue" => n}) when is_integer(n), do: {:ok, Integer.to_string(n)}
  defp metric_value(_), do: {:error, "invalidData"}

  defp metric_resource(%{"kind" => kind} = s)
       when kind in ~w(gceCpu gceNetworkReceived gceNetworkSent),
       do: "gcp:compute:#{s["project"]}:#{s["zone"]}:#{s["instanceId"]}"

  defp metric_resource(%{"kind" => "gcsStorage"} = s),
    do: "gcp:storage:#{s["project"]}:#{s["bucket"]}"

  defp metric_resource(s),
    do: "gcp:projects/#{s["project"]}/locations/#{s["location"]}/services/#{s["service"]}"

  defp normalize(row, dataset) do
    case Domain.normalize(row, dataset) do
      {:ok, row} -> {:ok, [row]}
      _ -> {:error, "invalidData", nil}
    end
  end

  defp map_rows(rows, fun) do
    Enum.reduce_while(rows, {:ok, []}, fn row, {:ok, records} ->
      case fun.(row) do
        {:ok, batch} -> {:cont, {:ok, records ++ batch}}
        error -> {:halt, error}
      end
    end)
  end

  defp output(ctx, records, state, complete, reason) do
    if length(records) <= Keyword.get(ctx.opts, :max_records, 10_000) do
      {:ok,
       %{
         records: records,
         status: %{
           "state" => state,
           "complete" => complete,
           "sourceAsOf" => nil,
           "observedStart" => nil,
           "observedEnd" => nil,
           "lastAttemptAt" => DateTime.to_iso8601(ctx.now),
           "lastSuccessAt" => DateTime.to_iso8601(ctx.now),
           "reason" => reason
         }
       }}
    else
      {:error, "resourceLimitExceeded", nil}
    end
  end

  defp valid?(regex, s), do: is_binary(s) and Regex.match?(regex, s)
  defp text?(s), do: is_binary(s) and s != ""
end
