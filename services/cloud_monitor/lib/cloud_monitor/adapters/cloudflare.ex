defmodule CloudMonitor.Adapters.Cloudflare do
  @moduledoc """
  Bounded, read-only Cloudflare v1 billable usage, inventory and opt-in analytics.
  No subscription-price inference, source watermark inference or partial snapshots.
  See docs/cloud-center/cloudflare-setup.md for capability and sampling limits.
  """
  @behaviour CloudMonitor.Adapter
  alias CloudMonitor.{Credentials, Domain}
  @base "https://api.cloudflare.com/client/v4"

  @impl true
  def collect(connection, dataset, window, opts \\ []) do
    with :ok <- configuration(connection, window),
         {:ok, token} <- Credentials.read(connection["credentialRef"]),
         true <- token != "" do
      ctx = %{
        connection: connection,
        account: connection["settings"]["accountId"],
        token: token,
        opts: opts,
        http: Keyword.get(opts, :http, CloudMonitor.HTTP),
        now: Keyword.get(opts, :now, DateTime.utc_now()) |> DateTime.to_iso8601(),
        remaining: Keyword.get(opts, :request_budget, 100),
        pages: Keyword.get(opts, :max_pages, 100),
        maximum: Keyword.get(opts, :max_resources, 1000),
        window: window
      }

      case dataset do
        "costs" -> costs(ctx)
        "resources" -> resources(ctx)
        "usage" -> usage(ctx)
        _ -> {:error, "unsupported", nil}
      end
    else
      {:error, code} -> {:error, code, nil}
      false -> {:error, "unconfigured", nil}
    end
  end

  defp configuration(c, %{start: %DateTime{} = start, end: %DateTime{} = finish}) do
    cond do
      not Domain.valid_window?(start, finish) ->
        {:error, "invalidQuery"}

      not is_map(c["settings"]) ->
        {:error, "invalidConfiguration"}

      not Enum.all?([c["id"], c["billingScopeId"], c["settings"]["accountId"]], &text?/1) ->
        {:error, "invalidConfiguration"}

      not valid_metrics?(c["settings"]["metrics"] || %{}) ->
        {:error, "invalidConfiguration"}

      true ->
        :ok
    end
  end

  defp configuration(_, _), do: {:error, "invalidQuery"}

  defp valid_metrics?(metrics) when is_map(metrics) do
    Enum.all?(~w(workers r2Buckets zones), fn key ->
      values = Map.get(metrics, key, [])
      is_list(values) and Enum.all?(values, &text?/1)
    end)
  end

  defp valid_metrics?(_), do: false

  defp costs(ctx) do
    path = "/accounts/#{segment(ctx.account)}/billable-usage"

    with {:ok, info, ctx} <- request(ctx, :get, path <> "/info"),
         {:ok, coverage} <- result(info) do
      billing(ctx, path, coverage)
    else
      {:error, code, nil} = error when code in ["permissionDenied", "unsupported"] ->
        if is_list(ctx.connection["settings"]["billingAnchors"]) and
             ctx.connection["settings"]["billingAnchors"] != [] do
          billing(%{ctx | remaining: ctx.remaining - 1}, path, %{
            "covered" => true,
            "subscriptions" => []
          })
        else
          error
        end

      error ->
        error
    end
  end

  defp billing(_, _, %{"covered" => false}), do: {:error, "unsupported", nil}

  defp billing(ctx, path, %{"covered" => true, "subscriptions" => subscriptions})
       when is_list(subscriptions) do
    with {:ok, from} <- billing_from(ctx, subscriptions),
         {:ok, body, _ctx} <-
           request(ctx, :get, path, %{
             "from" => from,
             "to" => Date.to_iso8601(DateTime.to_date(ctx.window.end))
           }),
         {:ok, rows} when is_list(rows) <- result(body) do
      cond do
        rows == [] ->
          {:error, "waiting", nil}

        length(rows) > Keyword.get(ctx.opts, :max_records, 10_000) ->
          {:error, "resourceLimitExceeded", nil}

        Enum.any?(rows, &(not is_map(&1) or is_nil(&1["ContractedCost"]))) ->
          {:error, "unsupported", nil}

        true ->
          with {:ok, records} <- map_rows(rows, &cost_records(&1, ctx)),
               {:ok, records} <- unique(records) do
            records = Enum.filter(records, &overlaps?(&1, ctx.window))

            output(
              ctx,
              records,
              if(records == [], do: "waiting", else: "partial"),
              false,
              "billableUsageMeteredOnly;fixedSubscriptionsUncovered;sourceCompletenessUnknown"
            )
          end
      end
    else
      {:error, "anchorsUnavailable", nil} ->
        {:error, "waiting", nil}

      {:ok, _} ->
        {:error, "invalidData", nil}

      error ->
        error
    end
  end

  defp billing(_, _, _), do: {:error, "invalidData", nil}

  defp billing_from(ctx, subscriptions) do
    # An exact recent anchor is preferred. For a remote historical window,
    # requesting the entire preceding month includes every possible anchor day;
    # this is a query lookback, never an invented billing-period end.
    start = DateTime.to_date(ctx.window.start)

    previous_month =
      start |> Date.beginning_of_month() |> Date.add(-1) |> Date.beginning_of_month()

    anchors = Enum.map(subscriptions, & &1["billing_cycle_anchor_timestamp"])

    anchors =
      case ctx.connection["settings"]["billingAnchors"] do
        explicit when is_list(explicit) and explicit != [] -> explicit
        _ -> anchors
      end

    parsed = Enum.map(anchors, &Domain.timestamp/1)

    if parsed == [] or Enum.any?(parsed, &(not match?({:ok, _}, &1))) do
      {:error, "anchorsUnavailable", nil}
    else
      dates =
        Enum.map(parsed, fn {:ok, time} ->
          date = DateTime.to_date(time)

          if Date.compare(date, start) != :gt and Date.diff(start, date) <= 31,
            do: date,
            else: previous_month
        end)

      {:ok, dates |> Enum.min(Date) |> Date.to_iso8601()}
    end
  end

  defp cost_records(row, ctx) do
    with {:ok, amount, precision} <- number(row["ContractedCost"]),
         true <-
           Enum.all?(
             ~w(ServiceName BillingCurrency ChargePeriodStart ChargePeriodEnd BillingPeriodStart),
             &text?(row[&1])
           ),
         {:ok, _} <- Domain.timestamp(row["BillingPeriodStart"]) do
      identity =
        Enum.map(
          ~w(ServiceName SubscriptionId ZoneId ChargePeriodStart ChargePeriodEnd BillingPeriodStart ChargeDescription ConsumedUnit PricingUnit),
          &row[&1]
        )

      period = %{
        "id" => id([ctx.account, identity, "period"]),
        "connectionId" => ctx.connection["id"],
        "billingScopeId" => ctx.connection["billingScopeId"],
        "service" => row["ServiceName"],
        "resourceId" => nil,
        "start" => row["ChargePeriodStart"],
        "end" => row["ChargePeriodEnd"],
        "currency" => row["BillingCurrency"],
        "amount" => amount,
        "basis" => "ContractedCost",
        "category" => category(row),
        "estimated" => nil,
        "source" => "cloudflare:billable-usage:v1",
        "sourcePrecision" => precision,
        "invoiceMonth" => nil,
        "recordKind" => "reported",
        "view" => "period",
        "coverage" => [
          "meteredUsageOnly",
          "fixedSubscriptionsUncovered",
          "nativeBillingPeriodStart=" <> row["BillingPeriodStart"]
        ]
      }

      with {:ok, period} <- Domain.normalize(period, "costs") do
        case row["CumulatedContractedCost"] do
          nil ->
            {:ok, [period]}

          value ->
            with {:ok, total, precision} <- number(value),
                 {:ok, cumulative} <-
                   Domain.normalize(
                     %{
                       period
                       | "id" => id([ctx.account, identity, "cumulative"]),
                         "start" => row["BillingPeriodStart"],
                         "amount" => total,
                         "view" => "cumulative",
                         "sourcePrecision" => precision
                     },
                     "costs"
                   ) do
              {:ok, [period, cumulative]}
            else
              _ -> {:error, "invalidData", nil}
            end
        end
      else
        _ -> {:error, "invalidData", nil}
      end
    else
      _ -> {:error, "invalidData", nil}
    end
  end

  defp category(%{"ChargeClass" => class}) when class in ["Correction", "Adjustment"],
    do: "adjustment"

  defp category(row),
    do:
      Map.get(
        %{
          "Usage" => "usage",
          "Purchase" => "subscription",
          "Tax" => "tax",
          "Credit" => "credit",
          "Refund" => "refund",
          "Adjustment" => "adjustment"
        },
        row["ChargeCategory"],
        "unknown"
      )

  defp resources(ctx) do
    with {:ok, zones, ctx} <- pages(ctx, "/zones", :zones, nil, MapSet.new(), [], 0),
         {:ok, workers, ctx} <-
           pages(
             ctx,
             "/accounts/#{segment(ctx.account)}/workers/scripts",
             :workers,
             nil,
             MapSet.new(),
             [],
             length(zones)
           ),
         {:ok, buckets, ctx} <-
           pages(
             ctx,
             "/accounts/#{segment(ctx.account)}/r2/buckets",
             :r2,
             nil,
             MapSet.new(),
             [],
             length(zones) + length(workers)
           ),
         {:ok, records} <- map_rows(zones ++ workers ++ buckets, &resource_record(&1, ctx)),
         {:ok, records} <- unique(records) do
      output(
        ctx,
        records,
        if(records == [], do: "empty", else: "available"),
        true,
        "inventoryTypes=Zones,WorkersScripts,R2Buckets;R2Jurisdiction=default"
      )
    end
  end

  defp pages(ctx, path, kind, token, seen, rows, count) do
    cond do
      MapSet.size(seen) >= ctx.pages ->
        {:error, "requestBudgetExceeded", nil}

      MapSet.member?(seen, token) ->
        {:error, "paginationCycle", nil}

      true ->
        query =
          case kind do
            :zones ->
              %{"account.id" => ctx.account, "page" => token || 1, "per_page" => 50}

            :workers ->
              %{}

            :r2 ->
              if(token, do: %{"per_page" => 100, "cursor" => token}, else: %{"per_page" => 100})
          end

        with {:ok, body, ctx} <- request(ctx, :get, path, query),
             {:ok, result} <- result(body),
             {:ok, batch, next} <- page(result, body["result_info"], kind, token) do
          total = count + length(batch)

          if total > ctx.maximum do
            {:error, "resourceLimitExceeded", nil}
          else
            tagged = Enum.map(batch, &{kind, &1})

            if next == nil do
              {:ok, Enum.reverse(rows) |> List.flatten() |> Kernel.++(tagged), ctx}
            else
              pages(ctx, path, kind, next, MapSet.put(seen, token), [tagged | rows], total)
            end
          end
        end
    end
  end

  defp page(rows, info, :zones, token) when is_list(rows) do
    current = token || 1

    case info do
      %{"page" => ^current, "total_pages" => total} when is_integer(total) and total >= 0 ->
        {:ok, rows, if(current < total, do: current + 1)}

      nil when length(rows) < 50 ->
        {:ok, rows, nil}

      _ ->
        {:error, "invalidData", nil}
    end
  end

  defp page(rows, info, :workers, _) when is_list(rows) do
    if is_map(info) and (info["total_pages"] || 1) > 1,
      do: {:error, "unsupported", nil},
      else: {:ok, rows, nil}
  end

  defp page(%{"buckets" => rows} = result, info, :r2, _) when is_list(rows) do
    cursor = (info || %{})["cursor"] || result["cursor"]

    cond do
      is_binary(cursor) -> {:ok, rows, if(cursor == "", do: nil, else: cursor)}
      cursor == nil and length(rows) < 100 -> {:ok, rows, nil}
      true -> {:error, "invalidData", nil}
    end
  end

  defp page(_, _, _, _), do: {:error, "invalidData", nil}

  defp resource_record({kind, row}, ctx) when is_map(row) do
    if valid_resource?(kind, row, ctx) do
      build_resource(kind, row, ctx)
    else
      {:error, "invalidData", nil}
    end
  end

  defp resource_record(_, _), do: {:error, "invalidData", nil}

  defp valid_resource?(:zones, row, ctx),
    do:
      text?(row["id"]) and text?(row["name"]) and is_map(row["account"]) and
        row["account"]["id"] == ctx.account

  defp valid_resource?(:workers, row, _ctx),
    do: text?(row["id"]) and is_list(row["tags"] || []) and Enum.all?(row["tags"] || [], &text?/1)

  defp valid_resource?(:r2, row, _ctx), do: text?(row["name"])

  defp build_resource(kind, row, ctx) do
    {type, identity, service, name, tags} =
      case kind do
        :zones ->
          {"zone", "zone:" <> to_string(row["id"]), "Zones", row["name"], %{}}

        :workers ->
          {"worker", "worker:" <> to_string(row["id"]), "Workers", row["id"],
           Map.new(row["tags"] || [], &{&1, "true"})}

        :r2 ->
          {"r2Bucket", "r2:default:" <> to_string(row["name"]), "R2", row["name"], %{}}
      end

    record = %{
      "id" => "cloudflare:#{ctx.account}:#{identity}",
      "connectionId" => ctx.connection["id"],
      "billingScopeId" => ctx.connection["billingScopeId"],
      "service" => service,
      "type" => type,
      "region" => "global",
      "name" => name,
      "tags" => tags,
      "observedAt" => ctx.now,
      "state" => if(kind == :zones, do: row["status"], else: nil)
    }

    if kind == :zones and get_in(row, ["account", "id"]) != ctx.account do
      {:error, "invalidData", nil}
    else
      case Domain.normalize(record, "resources") do
        {:ok, record} -> {:ok, [record]}
        _ -> {:error, "invalidData", nil}
      end
    end
  end

  defp usage(ctx) do
    metrics = ctx.connection["settings"]["metrics"] || %{}

    scopes =
      for {key, kind} <- [{"workers", :workers}, {"r2Buckets", :r2}, {"zones", :zones}],
          name <- Map.get(metrics, key, []),
          do: {kind, name}

    scopes = Enum.uniq(scopes)

    cond do
      scopes == [] ->
        output(ctx, [], "unconfigured", false, "metricScopesUnconfigured")

      length(scopes) > ctx.maximum ->
        {:error, "resourceLimitExceeded", nil}

      not Enum.all?(scopes, fn {_, name} -> text?(name) end) ->
        {:error, "invalidConfiguration", nil}

      DateTime.diff(ctx.window.end, ctx.window.start) > 31 * 86_400 ->
        {:error, "invalidQuery", nil}

      true ->
        result =
          Enum.reduce_while(scopes, {:ok, [], ctx}, fn {kind, name}, {:ok, rows, ctx} ->
            case metrics(ctx, kind, name) do
              {:ok, batch, ctx} -> {:cont, {:ok, rows ++ batch, ctx}}
              error -> {:halt, error}
            end
          end)

        with {:ok, rows, ctx} <- result do
          output(
            ctx,
            rows,
            if(rows == [], do: "waiting", else: "partial"),
            false,
            "configuredMetricScopesOnly;adaptiveSampling;storageLatestObservation;sourceCompletenessUnknown"
          )
        end
    end
  end

  defp metrics(ctx, :r2, name) do
    with {:ok, operations, ctx} <- graphql(ctx, :r2_operations, name),
         {:ok, storage, ctx} <- graphql(ctx, :r2_storage, name),
         {:ok, counts} <-
           counter_rows(
             operations,
             [{"requests", "operations"}],
             "R2",
             resource_id(ctx, :r2, name),
             ctx
           ),
         {:ok, gauges} <- storage_rows(storage, resource_id(ctx, :r2, name), ctx) do
      {:ok, counts ++ gauges, ctx}
    end
  end

  defp metrics(ctx, kind, name) do
    with {:ok, data, ctx} <- graphql(ctx, kind, name),
         {:ok, rows} <-
           counter_rows(
             data,
             if(kind == :workers,
               do: [{"requests", "requests"}, {"errors", "errors"}],
               else: [{"requests", "requests"}]
             ),
             if(kind == :workers, do: "Workers", else: "Zones"),
             resource_id(ctx, kind, name),
             ctx
           ) do
      {:ok, rows, ctx}
    end
  end

  defp graphql(ctx, kind, name) do
    {root, dataset, filter, fields, tail} =
      case kind do
        :workers ->
          {"accounts", "workersInvocationsAdaptive", "scriptName: $name",
           "sum { requests errors }", ""}

        :r2_operations ->
          {"accounts", "r2OperationsAdaptiveGroups", "bucketName: $name", "sum { requests }", ""}

        :r2_storage ->
          {"accounts", "r2StorageAdaptiveGroups", "bucketName: $name",
           "max { payloadSize metadataSize } dimensions { datetime }",
           ", orderBy: [datetime_DESC]"}

        :zones ->
          {"zones", "httpRequests1hGroups", "", "sum { requests }", ""}
      end

    selector = if root == "zones", do: "zoneTag: $name", else: "accountTag: $accountTag"

    declaration =
      if kind == :zones,
        do: "$name: string!",
        else: "$accountTag: string!, $name: string!"

    # Dataset date filter scalars differ (Workers documents string, R2 Time).
    # ISO string literals are accepted by each scalar without declaring a
    # variable with the wrong schema type. These are generated dates only.
    start = JSON.encode!(DateTime.to_iso8601(ctx.window.start))

    finish =
      JSON.encode!(ctx.window.end |> DateTime.add(-1, :microsecond) |> DateTime.to_iso8601())

    time_filter =
      "datetime_geq: #{start}, datetime_leq: #{finish}" <>
        if(filter == "", do: "", else: ", " <> filter)

    # Without dimensions, counters are one aggregate for the complete query
    # window. A second row is rejected rather than silently truncating it.
    limit = if kind == :r2_storage, do: 1, else: 2

    body = %{
      "query" =>
        "query CloudCenter(#{declaration}) { viewer { #{root}(filter: {#{selector}}) { #{dataset}(limit: #{limit}, filter: {#{time_filter}}#{tail}) { #{fields} } } } }",
      "variables" =>
        if(kind == :zones,
          do: %{"name" => name},
          else: %{"accountTag" => ctx.account, "name" => name}
        )
    }

    with {:ok, body, ctx} <- request(ctx, :post, "/graphql", %{}, body),
         [container] when is_map(container) <- get_in(body, ["data", "viewer", root]),
         rows when is_list(rows) <- container[dataset],
         true <- length(rows) <= 1 do
      {:ok, rows, ctx}
    else
      {:error, _, _} = error -> error
      _ -> {:error, "invalidData", nil}
    end
  end

  defp counter_rows([], _, _, _, _), do: {:ok, []}

  defp counter_rows([%{"sum" => values}], metrics, service, resource, ctx) do
    map_rows(metrics, fn {source, metric} ->
      sample(
        ctx,
        resource,
        service,
        metric,
        "count",
        values[source],
        ctx.window.start,
        ctx.window.end,
        "queryWindow",
        "sum"
      )
    end)
  end

  defp counter_rows(_, _, _, _, _), do: {:error, "invalidData", nil}

  defp storage_rows([], _, _), do: {:ok, []}

  defp storage_rows([%{"max" => values, "dimensions" => %{"datetime" => time}}], resource, ctx) do
    with {:ok, observed} <- Domain.timestamp(time),
         true <-
           DateTime.compare(observed, ctx.window.start) != :lt and
             DateTime.compare(observed, ctx.window.end) == :lt do
      map_rows([{"payloadSize", "storedBytes"}, {"metadataSize", "metadataBytes"}], fn {source,
                                                                                        metric} ->
        # A one-microsecond marker represents a point observation, not a claim
        # that the gauge is valid for the whole requested interval.
        sample(
          ctx,
          resource,
          "R2",
          metric,
          "bytes",
          values[source],
          observed,
          DateTime.add(observed, 1, :microsecond),
          "pointObservation",
          "maximum"
        )
      end)
    else
      _ -> {:error, "invalidData", nil}
    end
  end

  defp storage_rows(_, _, _), do: {:error, "invalidData", nil}

  defp sample(
         _ctx,
         resource,
         service,
         metric,
         unit,
         value,
         start,
         finish,
         granularity,
         aggregation
       ) do
    with {:ok, value, _precision} <- number(value),
         {:ok, row} <-
           Domain.normalize(
             %{
               "id" => id([resource, metric, start, finish]),
               "resourceId" => resource,
               "service" => service,
               "metric" => metric,
               "unit" => unit,
               "start" => DateTime.to_iso8601(start),
               "end" => DateTime.to_iso8601(finish),
               "granularity" => granularity,
               "aggregation" => aggregation,
               "value" => value,
               "source" => "cloudflare:graphql:" <> metric_dataset(service, metric)
             },
             "usage"
           ) do
      {:ok, [row]}
    else
      _ -> {:error, "invalidData", nil}
    end
  end

  defp resource_id(ctx, :workers, name), do: "cloudflare:#{ctx.account}:worker:#{name}"
  defp resource_id(ctx, :r2, name), do: "cloudflare:#{ctx.account}:r2:default:#{name}"
  defp resource_id(ctx, :zones, name), do: "cloudflare:#{ctx.account}:zone:#{name}"

  defp metric_dataset("Workers", _), do: "workersInvocationsAdaptive"
  defp metric_dataset("Zones", _), do: "httpRequests1hGroups"
  defp metric_dataset("R2", "operations"), do: "r2OperationsAdaptiveGroups"
  defp metric_dataset("R2", _), do: "r2StorageAdaptiveGroups"

  defp request(ctx, method, path, query \\ %{}, body \\ "")

  defp request(%{remaining: remaining}, _, _, _, _) when remaining <= 0,
    do: {:error, "requestBudgetExceeded", nil}

  defp request(ctx, method, path, query, body) do
    url = @base <> path <> if(map_size(query) == 0, do: "", else: "?" <> URI.encode_query(query))
    headers = [{"authorization", "Bearer " <> ctx.token}, {"accept", "application/json"}]

    case ctx.http.request(method, url, headers, body, ctx.opts) do
      {:ok, %{status: status, body: body} = response} ->
        retry = retry_after(response[:headers] || [])

        cond do
          status == 401 ->
            {:error, "authenticationFailed", nil}

          status == 403 ->
            {:error, "permissionDenied", nil}

          status == 429 ->
            {:error, "rateLimited", retry}

          status == 404 ->
            {:error, "unsupported", nil}

          status >= 500 ->
            {:error, "failed", retry}

          status < 200 or status >= 300 ->
            {:error, "invalidData", nil}

          not is_map(body) ->
            {:error, "invalidData", nil}

          body["success"] == false or (is_list(body["errors"]) and body["errors"] != []) ->
            {:error, api_error(body["errors"]), nil}

          true ->
            {:ok, body, %{ctx | remaining: ctx.remaining - 1}}
        end

      {:error, code} ->
        {:error, code, nil}
    end
  end

  defp result(%{"success" => true, "result" => result}), do: {:ok, result}
  defp result(_), do: {:error, "invalidData", nil}

  defp api_error(errors) when is_list(errors) do
    text = errors |> Enum.map(&Map.get(&1, "message", "")) |> Enum.join(" ") |> String.downcase()

    cond do
      String.contains?(text, ["not authorized", "permission", "forbidden", "not allowed"]) ->
        "permissionDenied"

      String.contains?(text, [
        "unknown field",
        "cannot query field",
        "not available",
        "not supported"
      ]) ->
        "unsupported"

      String.contains?(text, ["rate limit", "rate-limit"]) ->
        "rateLimited"

      true ->
        "invalidData"
    end
  end

  defp api_error(_), do: "invalidData"

  defp retry_after(headers) do
    case Enum.find(headers, fn {key, _} -> String.downcase(to_string(key)) == "retry-after" end) do
      {_, value} ->
        case Integer.parse(to_string(value)) do
          {seconds, ""} when seconds >= 0 -> min(seconds, 86_400)
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp output(_ctx, [], state, _complete, _reason)
       when state in ["waiting", "unsupported", "unconfigured"],
       do: {:error, state, nil}

  defp output(ctx, records, state, complete, reason) do
    if length(records) > Keyword.get(ctx.opts, :max_records, 10_000) do
      {:error, "resourceLimitExceeded", nil}
    else
      {:ok,
       %{
         records: records,
         status: %{
           "state" => state,
           "lastAttemptAt" => ctx.now,
           "lastSuccessAt" => ctx.now,
           "sourceAsOf" => nil,
           "observedStart" => nil,
           "observedEnd" => nil,
           "complete" => complete,
           "reason" => reason
         }
       }}
    end
  end

  defp overlaps?(r, window) do
    {:ok, start} = Domain.timestamp(r["start"])
    {:ok, finish} = Domain.timestamp(r["end"])
    DateTime.compare(start, window.end) == :lt and DateTime.compare(finish, window.start) == :gt
  end

  defp number(value) when is_binary(value) do
    with {:ok, number} <- Domain.decimal(value), do: {:ok, Domain.amount(number), "decimalString"}
  end

  defp number(value) when is_integer(value), do: {:ok, Integer.to_string(value), "jsonInteger"}

  defp number(value) when is_float(value),
    do: {:ok, value |> Decimal.from_float() |> Domain.amount(), "jsonNumberAlreadyRounded"}

  defp number(_), do: {:error, "invalidData"}

  defp map_rows(rows, fun) do
    Enum.reduce_while(rows, {:ok, []}, fn row, {:ok, result} ->
      case fun.(row) do
        {:ok, batch} -> {:cont, {:ok, [batch | result]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, rows} -> {:ok, rows |> Enum.reverse() |> List.flatten()}
      error -> error
    end
  end

  defp unique(rows) do
    Enum.reduce_while(rows, {:ok, %{}, []}, fn row, {:ok, seen, result} ->
      case seen[row["id"]] do
        nil -> {:cont, {:ok, Map.put(seen, row["id"], row), [row | result]}}
        ^row -> {:cont, {:ok, seen, result}}
        _ -> {:halt, {:error, "invalidData", nil}}
      end
    end)
    |> case do
      {:ok, _, rows} -> {:ok, Enum.reverse(rows)}
      error -> error
    end
  end

  defp id(parts),
    do:
      "cloudflare:" <>
        (:crypto.hash(:sha256, :erlang.term_to_binary(parts))
         |> Base.url_encode64(padding: false))

  defp text?(s), do: is_binary(s) and s != ""
  defp segment(s), do: URI.encode(s, &URI.char_unreserved?/1)
end
