defmodule CloudMonitorWeb.APIController do
  use Phoenix.Controller, formats: [:json]
  alias CloudMonitor.{Repo, Store, Jobs, Query, Domain}
  alias CloudMonitor.Schema.Job

  # All GET action reads, including overview metadata and serialization, belong to
  # the same snapshot. Mutating actions retain their existing transaction boundaries.
  def action(%{method: "GET"} = conn, _opts) do
    Store.read_snapshot(fn revision ->
      conn = Plug.Conn.assign(conn, :cloud_revision, revision)
      apply(__MODULE__, action_name(conn), [conn, conn.params])
    end)
  end

  def action(conn, _opts), do: apply(__MODULE__, action_name(conn), [conn, conn.params])

  def connections(conn, params), do: list(conn, params, Store.connections(), "connections")
  def budgets(conn, params), do: list(conn, params, Store.budgets(), "budgets")
  def costs(conn, %{"id" => id} = params), do: connection_list(conn, params, id, "costs")
  def resources(conn, %{"id" => id} = params), do: connection_list(conn, params, id, "resources")

  def usage(conn, %{"id" => id} = params),
    do:
      list(
        conn,
        params,
        Enum.filter(Store.records("usage"), &(&1["resourceId"] == id)),
        "usage:" <> id
      )

  defp connection_list(conn, params, id, dataset) do
    if Store.connection(id),
      do: list(conn, params, Store.records(dataset, id), dataset <> ":" <> id),
      else: failure(conn, "notFound")
  end

  defp list(conn, params, records, identity) do
    with {:ok, query} <- Query.parse(params),
         {:ok, result} <- Query.page(records, query, identity, conn.assigns.cloud_revision) do
      json(conn, result)
    else
      {:error, code} -> failure(conn, code)
    end
  end

  def overview(conn, params) do
    with {:ok, query} <- Query.parse(default_window(params)) do
      rows = Query.filter(Store.records("costs"), Map.drop(query, ~w(start end)))

      aggregate = Domain.window_totals(rows, Store.scopes(), query["start"], query["end"])

      data = %{
        "totals" => aggregate["totals"],
        "unmappedTotals" => aggregate["unmappedTotals"],
        "connections" => Store.connections(),
        "coverage" => overview_coverage(rows, aggregate, Store.connections())
      }

      json(conn, Query.envelope(data, conn.assigns.cloud_revision, query))
    else
      {:error, code} -> failure(conn, code)
    end
  end

  def connection_overview(conn, %{"id" => id} = params) do
    with connection when not is_nil(connection) <- Store.connection(id),
         {:ok, query} <- Query.parse(default_window(params)) do
      rows = Query.filter(Store.records("costs", id), Map.drop(query, ~w(start end)))

      aggregate = Domain.window_totals(rows, Store.scopes(), query["start"], query["end"])

      data = %{
        "connection" => connection,
        "totals" => aggregate["totals"],
        "unmappedTotals" => aggregate["unmappedTotals"],
        "coverage" => overview_coverage(rows, aggregate, [connection]),
        "resourceCount" => length(Store.records("resources", id)),
        "statuses" => connection["statuses"]
      }

      json(conn, Query.envelope(data, conn.assigns.cloud_revision, query))
    else
      nil -> failure(conn, "notFound")
      {:error, code} -> failure(conn, code)
    end
  end

  defp default_window(params) do
    if params["start"] || params["end"] do
      params
    else
      now = DateTime.utc_now()
      first = Date.new!(now.year, now.month, 1)

      Map.merge(params, %{
        "start" => DateTime.new!(first, ~T[00:00:00.000], "Etc/UTC") |> DateTime.to_iso8601(),
        "end" =>
          DateTime.new!(Date.shift(first, month: 1), ~T[00:00:00.000], "Etc/UTC")
          |> DateTime.to_iso8601()
      })
    end
  end

  defp overview_coverage(rows, aggregate, connections) do
    unmapped = aggregate["unmappedTotals"]

    gaps = if unmapped == [], do: [], else: ["nativePeriodNotAllocated"]

    unknown =
      if Enum.any?(connections, fn c ->
           get_in(c, ["statuses", "costs", "complete"]) != true
         end), do: ["incompleteOrUnknownCoverage"], else: []

    Enum.uniq(coverage(rows) ++ aggregate["coverage"] ++ gaps ++ unknown)
  end

  defp coverage(rows), do: rows |> Enum.flat_map(& &1["coverage"]) |> Enum.uniq() |> Enum.sort()

  def sync(conn, %{"id" => id} = params) do
    dataset = Map.get(params, "dataset", "costs")

    window =
      if params["start"] && params["end"] do
        with {:ok, q} <- Query.parse(params),
             {:ok, start} <- Domain.timestamp(q["start"]),
             {:ok, finish} <- Domain.timestamp(q["end"]) do
          %{start: start, end: finish}
        else
          _ -> :invalid
        end
      else
        if params["start"] || params["end"], do: :invalid, else: Jobs.default_window(dataset)
      end

    result =
      if window == :invalid, do: {:error, "invalidQuery"}, else: Jobs.enqueue(id, dataset, window)

    case result do
      {:ok, job} -> conn |> put_status(202) |> json(Map.take(Jobs.wire(job), ~w(id state)))
      {:error, code} -> failure(conn, code)
    end
  end

  def sync_job(conn, %{"id" => id}) do
    case Ecto.UUID.cast(id) do
      {:ok, id} ->
        case Repo.get(Job, id) do
          nil -> failure(conn, "notFound")
          job -> json(conn, Query.envelope(Jobs.wire(job), conn.assigns.cloud_revision))
        end

      :error ->
        failure(conn, "notFound")
    end
  end

  def save_budget(conn, %{"id" => id} = params) do
    case Store.save_budget(id, params) do
      {:ok, rule} -> json(conn, rule)
      {:error, code} -> failure(conn, code)
    end
  end

  defp failure(conn, code) do
    status =
      case code do
        "notFound" -> 404
        "revisionExpired" -> 409
        "cooldown" -> 429
        _ -> 400
      end

    conn
    |> put_status(status)
    |> json(%{"error" => %{"code" => code, "message" => "Request could not be completed"}})
  end
end
