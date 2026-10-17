defmodule CloudMonitor.Adapters.GCP.Billing do
  @moduledoc false
  alias CloudMonitor.Domain
  alias CloudMonitor.Adapters.GCP.Transport

  @columns ~w(project_id service sku_id start end currency invoice_month cost_type cost credits export_time)
  @base "https://bigquery.googleapis.com/bigquery/v2/projects/"

  def collect(ctx) do
    s = ctx.settings
    [project, dataset, table] = String.split(s["exportTable"], ".")

    with {:ok, metadata, ctx} <-
           Transport.request(ctx, :get, @base <> "#{project}/datasets/#{dataset}/tables/#{table}"),
         {:ok, filter} <- partition_filter(metadata),
         true <- metadata["location"] == s["location"],
         {:ok, response, ctx} <-
           Transport.request(
             ctx,
             :post,
             @base <> s["queryProject"] <> "/queries",
             query(ctx, filter)
           ),
         {:ok, rows, _ctx} <- results(ctx, response, nil, MapSet.new(), [], nil, 0),
         false <- rows == [],
         {:ok, records} <- records(rows, ctx) do
      exports = Enum.map(rows, & &1["export_time"])

      source =
        Enum.max_by(exports, fn value ->
          {:ok, dt} = Domain.timestamp(value)
          DateTime.to_unix(dt, :microsecond)
        end)

      {:ok,
       %{
         records: records,
         status:
           status(
             ctx,
             "partial",
             false,
             source,
             "billingExportLatencyUnknown;configuredProjectsOnly;noResourceCostAllocation"
           )
       }}
    else
      {:error, "notFound", _} -> {:error, "waiting", nil}
      false -> {:error, "invalidConfiguration", nil}
      true -> {:error, "waiting", nil}
      error -> error
    end
  end

  defp partition_filter(%{"timePartitioning" => partition}) when is_map(partition) do
    case partition["field"] do
      "usage_start_time" ->
        {:ok,
         "usage_start_time >= TIMESTAMP_SUB(@start, INTERVAL 93 DAY) AND usage_start_time < @end"}

      "export_time" ->
        {:ok, "export_time >= @start AND export_time <= @asOf"}

      nil ->
        {:ok,
         "_PARTITIONTIME >= TIMESTAMP_TRUNC(@start, DAY) AND _PARTITIONTIME <= TIMESTAMP_TRUNC(@asOf, DAY)"}

      _ ->
        {:error, "unsupported", nil}
    end
  end

  # Legacy non-partitioned exports still get explicit bounded usage filters
  # and a hard maximumBytesBilled cap; no fictitious partition is referenced.
  defp partition_filter(_),
    do:
      {:ok,
       "usage_start_time >= TIMESTAMP_SUB(@start, INTERVAL 93 DAY) AND usage_start_time < @end"}

  defp query(ctx, partition) do
    s = ctx.settings
    maximum = Keyword.get(ctx.opts, :max_records, 10_000)

    sql = """
    WITH base AS (
      SELECT COALESCE(project.id, '__billing_account_unallocated__') AS project_id, service.description AS service, sku.id AS sku_id,
        usage_start_time AS start_time, usage_end_time AS end_time, currency,
        invoice.month AS invoice_month, cost_type, export_time,
        CAST(cost AS NUMERIC) AS base_cost,
        IFNULL((SELECT SUM(CAST(credit.amount AS NUMERIC)) FROM UNNEST(credits) AS credit), NUMERIC '0') AS credit_amount
      FROM `#{s["exportTable"]}`
      WHERE (#{partition}) AND usage_start_time < @end AND usage_end_time > @start
        AND billing_account_id = @billingAccount AND (project.id IN UNNEST(@projects) OR project.id IS NULL)
    )
    SELECT project_id, service, sku_id,
      FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E6SZ', start_time) AS `start`,
      FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E6SZ', end_time) AS `end`,
      currency, invoice_month, cost_type, CAST(SUM(base_cost) AS STRING) AS cost,
      CAST(SUM(credit_amount) AS STRING) AS credits,
      FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E6SZ', MAX(export_time)) AS export_time
    FROM base
    GROUP BY project_id, service, sku_id, start_time, end_time, currency, invoice_month, cost_type
    ORDER BY project_id, service, sku_id, `start`, `end`, currency, invoice_month, cost_type
    LIMIT #{maximum + 1}
    """

    %{
      "query" => sql,
      "useLegacySql" => false,
      "parameterMode" => "NAMED",
      "location" => s["location"],
      "maxResults" => 100,
      "timeoutMs" => 1000,
      "jobTimeoutMs" => "60000",
      "maximumBytesBilled" => to_string(Keyword.get(ctx.opts, :max_query_bytes, 1_000_000_000)),
      "requestId" => Base.encode16(:crypto.strong_rand_bytes(16), case: :lower),
      "queryParameters" => [
        parameter("start", "TIMESTAMP", DateTime.to_iso8601(ctx.window.start)),
        parameter("end", "TIMESTAMP", DateTime.to_iso8601(ctx.window.end)),
        parameter("asOf", "TIMESTAMP", DateTime.to_iso8601(ctx.now)),
        parameter("billingAccount", "STRING", s["billingAccountId"]),
        %{
          "name" => "projects",
          "parameterType" => %{"type" => "ARRAY", "arrayType" => %{"type" => "STRING"}},
          "parameterValue" => %{"arrayValues" => Enum.map(s["projects"], &%{"value" => &1})}
        }
      ]
    }
  end

  defp parameter(name, type, value),
    do: %{
      "name" => name,
      "parameterType" => %{"type" => type},
      "parameterValue" => %{"value" => value}
    }

  defp results(ctx, response, job, seen, pages, total, polls) do
    with {:ok, job} <- job_reference(response["jobReference"], job, ctx) do
      cond do
        response["jobComplete"] == false and polls >= Keyword.get(ctx.opts, :max_polls, 5) ->
          {:error, "waiting", nil}

        response["jobComplete"] == false ->
          with {:ok, next, ctx} <- fetch(ctx, job, nil),
               do: results(ctx, next, job, seen, pages, total, polls + 1)

        response["jobComplete"] != true ->
          {:error, "invalidData", nil}

        true ->
          completed(ctx, response, job, seen, pages, total, polls)
      end
    end
  end

  defp completed(ctx, response, job, seen, pages, total, polls) do
    with {count, ""} when count >= 0 <- Integer.parse(response["totalRows"] || ""),
         true <- total == nil or total == count,
         true <- count <= Keyword.get(ctx.opts, :max_records, 10_000),
         {:ok, batch} <- decode_rows(response) do
      next = response["pageToken"]
      pages = [batch | pages]

      cond do
        next in [nil, ""] ->
          rows = pages |> Enum.reverse() |> List.flatten()
          if length(rows) == count, do: {:ok, rows, ctx}, else: {:error, "invalidData", nil}

        not is_binary(next) ->
          {:error, "invalidData", nil}

        MapSet.member?(seen, next) ->
          {:error, "paginationCycle", nil}

        MapSet.size(seen) + 1 >= Keyword.get(ctx.opts, :max_pages, 100) ->
          {:error, "requestBudgetExceeded", nil}

        true ->
          with {:ok, response, ctx} <- fetch(ctx, job, next),
               do: results(ctx, response, job, MapSet.put(seen, next), pages, count, polls)
      end
    else
      false -> {:error, "resourceLimitExceeded", nil}
      {:error, _, _} = error -> error
      _ -> {:error, "invalidData", nil}
    end
  end

  defp fetch(ctx, job, token) do
    params = %{"location" => job["location"], "maxResults" => 100, "timeoutMs" => 1000}
    params = if token, do: Map.put(params, "pageToken", token), else: params

    Transport.request(
      ctx,
      :get,
      @base <> ctx.settings["queryProject"] <> "/queries/" <> job["jobId"],
      "",
      params
    )
  end

  defp job_reference(%{"projectId" => project, "jobId" => id} = ref, previous, ctx)
       when is_binary(id) do
    ref = Map.put_new(ref, "location", ctx.settings["location"])

    if project == ctx.settings["queryProject"] and ref["location"] == ctx.settings["location"] and
         Regex.match?(~r/^[A-Za-z0-9_-]{1,1024}$/, id) and (previous == nil or ref == previous),
       do: {:ok, ref},
       else: {:error, "invalidData", nil}
  end

  defp job_reference(nil, previous, _) when is_map(previous), do: {:ok, previous}
  defp job_reference(_, _, _), do: {:error, "invalidData", nil}

  defp decode_rows(response) do
    fields = get_in(response, ["schema", "fields"])
    valid = fields == nil or (is_list(fields) and Enum.map(fields, & &1["name"]) == @columns)

    if valid and is_list(Map.get(response, "rows", [])) do
      Enum.reduce_while(Map.get(response, "rows", []), {:ok, []}, fn
        %{"f" => cells}, {:ok, rows} when is_list(cells) and length(cells) == length(@columns) ->
          if Enum.all?(cells, &(is_map(&1) and is_binary(&1["v"]))),
            do: {:cont, {:ok, [Map.new(Enum.zip(@columns, Enum.map(cells, & &1["v"]))) | rows]}},
            else: {:halt, {:error, "invalidData", nil}}

        _, _ ->
          {:halt, {:error, "invalidData", nil}}
      end)
      |> case do
        {:ok, rows} -> {:ok, Enum.reverse(rows)}
        error -> error
      end
    else
      {:error, "invalidData", nil}
    end
  end

  defp records(rows, ctx) do
    Enum.reduce_while(rows, {:ok, []}, fn row, {:ok, records} ->
      case cost(row, ctx) do
        {:ok, batch} -> {:cont, {:ok, records ++ batch}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, records} when length(records) <= 10_000 ->
        if length(records) <= Keyword.get(ctx.opts, :max_records, 10_000),
          do: {:ok, records},
          else: {:error, "resourceLimitExceeded", nil}

      {:ok, _} ->
        {:error, "resourceLimitExceeded", nil}

      error ->
        error
    end
  end

  defp cost(row, ctx) do
    with true <-
           row["project_id"] in ["__billing_account_unallocated__" | ctx.settings["projects"]],
         true <- Regex.match?(~r/^\d{6}$/, row["invoice_month"]),
         {:ok, _} <- Domain.timestamp(row["export_time"]),
         {:ok, amount} <- Domain.decimal(row["cost"]),
         {:ok, credits} <- Domain.decimal(row["credits"]) do
      identity = Map.take(row, @columns -- ~w(cost credits export_time))

      base = %{
        "id" => id([ctx.settings["billingAccountId"], identity, "base"]),
        "connectionId" => ctx.connection["id"],
        "billingScopeId" => ctx.connection["billingScopeId"],
        "service" => row["service"],
        "resourceId" => nil,
        "start" => row["start"],
        "end" => row["end"],
        "currency" => row["currency"],
        "amount" => Domain.amount(amount),
        "basis" => "GcpExportNetCost",
        "category" => category(row["cost_type"]),
        "estimated" => nil,
        "source" => "gcp:bigquery:billing-export",
        "sourcePrecision" => "sourceFloat64CastToNumericScale9",
        "invoiceMonth" => row["invoice_month"],
        "recordKind" => "reported",
        "view" => "period",
        "coverage" => [
          if(row["project_id"] == "__billing_account_unallocated__",
            do: "billingAccountUnallocated",
            else: "project=" <> row["project_id"]
          ),
          "sku=" <> row["sku_id"],
          "costType=" <> row["cost_type"],
          "exportedAt=" <> row["export_time"],
          "resourceCostUnallocated",
          "sourceCompletenessUnknown"
        ]
      }

      with {:ok, base} <- Domain.normalize(base, "costs") do
        credit = %{
          base
          | "id" => id([ctx.settings["billingAccountId"], identity, "credits"]),
            "amount" => Domain.amount(credits),
            "category" => "credit"
        }

        {:ok, if(Decimal.equal?(credits, 0), do: [base], else: [base, credit])}
      else
        _ -> {:error, "invalidData", nil}
      end
    else
      _ -> {:error, "invalidData", nil}
    end
  end

  defp category("regular"), do: "usage"
  defp category("tax"), do: "tax"
  defp category(type) when type in ["adjustment", "rounding error"], do: "adjustment"
  defp category(_), do: "unknown"

  defp id(parts),
    do:
      "gcp:" <>
        (:crypto.hash(:sha256, :erlang.term_to_binary(parts))
         |> Base.url_encode64(padding: false))

  defp status(ctx, state, complete, source, reason),
    do: %{
      "state" => state,
      "complete" => complete,
      "lastAttemptAt" => DateTime.to_iso8601(ctx.now),
      "lastSuccessAt" => DateTime.to_iso8601(ctx.now),
      "sourceAsOf" => source,
      "observedStart" => nil,
      "observedEnd" => nil,
      "reason" => reason
    }
end
