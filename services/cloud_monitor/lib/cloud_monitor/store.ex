defmodule CloudMonitor.Store do
  import Ecto.Query
  alias CloudMonitor.{Repo, Domain}
  alias CloudMonitor.Schema.{Connection, Scope, Snapshot, Entry, Budget, Job}
  @datasets ~w(costs resources usage)
  @public ~w(id provider displayName billingScopeId capabilities)
  def datasets, do: @datasets
  def now, do: DateTime.utc_now()
  def iso(time), do: DateTime.to_iso8601(time)

  def configure(data) do
    connections = Map.get(data, "connections", [])
    scopes = Map.get(data, "scopes", [])

    valid =
      Enum.all?(connections, fn c ->
        c["provider"] in ~w(cloudflare aws gcp) and
          Enum.all?(~w(id provider displayName billingScopeId), &is_binary(c[&1])) and
          valid_ref?(c["credentialRef"])
      end)

    valid =
      valid and
        Enum.all?(scopes, fn s ->
          Enum.all?(~w(id provider accountId authoritativeConnectionId), &is_binary(s[&1]))
        end)

    if valid do
      Repo.transact(fn ->
        for c <- connections do
          config =
            Map.take(c, @public ++ ~w(credentialRef settings))
            |> Map.put_new("capabilities", Map.new(@datasets, &{&1, "unknown"}))

          row = Repo.get(Connection, c["id"])

          statuses =
            if row,
              do: row.statuses,
              else:
                Map.get(c, "statuses", Map.new(@datasets, &{&1, blank_status("unconfigured")}))

          changeset =
            Ecto.Changeset.change(row || %Connection{id: c["id"]},
              config: config,
              statuses: statuses
            )

          Repo.insert_or_update!(changeset)
        end

        for s <- scopes do
          Repo.insert!(
            %Scope{
              id: s["id"],
              data: Map.take(s, ~w(id provider parentId accountId authoritativeConnectionId))
            },
            on_conflict: [set: [data: s]],
            conflict_target: :id
          )
        end

        {:ok, :ok}
      end)
      |> case do
        {:ok, :ok} -> :ok
        {:error, _} -> {:error, "invalidConfiguration"}
      end
    else
      {:error, "invalidConfiguration"}
    end
  end

  defp valid_ref?(nil), do: true
  defp valid_ref?(ref) when is_binary(ref), do: String.starts_with?(ref, ["env:", "file:"])
  defp valid_ref?(_), do: false

  def blank_status(state),
    do:
      Map.new(
        ~w(lastAttemptAt lastSuccessAt sourceAsOf observedStart observedEnd reason),
        &{&1, nil}
      )
      |> Map.merge(%{"state" => state, "complete" => false})

  def connections, do: Connection |> order_by(:id) |> Repo.all() |> Enum.map(&public/1)

  def connection(id) do
    case Repo.get(Connection, id) do
      nil -> nil
      c -> public(c)
    end
  end

  def server_connection(id) do
    case Repo.get(Connection, id) do
      nil -> nil
      c -> c.config
    end
  end

  defp public(c), do: Map.take(c.config, @public) |> Map.put("statuses", c.statuses)
  def scopes, do: Scope |> order_by(:id) |> Repo.all() |> Enum.map(& &1.data)

  @doc "Reads an entire response and its revision from one PostgreSQL MVCC snapshot."
  def read_snapshot(fun) when is_function(fun, 1) do
    {:ok, result} =
      Repo.transact(fn ->
        # This must precede the first response SELECT, including revision metadata.
        Repo.query!("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ")
        {:ok, fun.(revision())}
      end)

    result
  end

  def revision do
    snapshots = Repo.all(from(s in Snapshot, order_by: s.id, select: {s.id, s.revision}))
    # Public metadata is part of the response too. No credentials or private settings
    # enter this identity; edits to lists/statuses must invalidate their cursors.
    jobs =
      Repo.all(from(j in Job, order_by: j.id, select: {j.id, j.state, j.attempts, j.error_code}))

    state = {snapshots, connections(), scopes(), budgets(), jobs}

    :crypto.hash(:sha256, :erlang.term_to_binary(state, [:deterministic]))
    |> Base.url_encode64(padding: false)
  end

  def publish(connection_id, dataset, window, %{records: records, status: status})
      when dataset in @datasets and is_list(records) and is_map(status) do
    with true <- length(records) <= Application.get_env(:cloud_monitor, :max_records),
         true <- status["state"] in Domain.states() and is_boolean(status["complete"]),
         {:ok, normalized} <- normalize_records(records, dataset, connection_id) do
      window = %{
        start: Domain.persistence_time(window.start),
        end: Domain.persistence_time(window.end)
      }

      Repo.transact(fn ->
        connection =
          Repo.one(from(c in Connection, where: c.id == ^connection_id, lock: "FOR UPDATE"))

        if is_nil(connection), do: Repo.rollback("notFound")

        key =
          if dataset == "costs", do: iso(window.start) <> "/" <> iso(window.end), else: "latest"

        snapshot =
          Repo.get_by(Snapshot, connection_id: connection_id, dataset: dataset, window_key: key)

        old_status = connection.statuses[dataset] || blank_status("waiting")

        updated_status =
          Map.merge(old_status, Map.take(status, Map.keys(blank_status("waiting"))))
          |> Map.merge(%{"lastAttemptAt" => iso(now()), "lastSuccessAt" => iso(now())})

        attrs = [
          connection_id: connection_id,
          dataset: dataset,
          window_key: key,
          window_start: window.start,
          window_end: window.end,
          revision: Ecto.UUID.generate(),
          status: updated_status
        ]

        saved = Repo.insert_or_update!(Ecto.Changeset.change(snapshot || %Snapshot{}, attrs))
        Repo.delete_all(from(e in Entry, where: e.snapshot_id == ^saved.id))

        entries =
          Enum.map(normalized, fn r ->
            amount =
              case dataset do
                "costs" -> Decimal.new(r["amount"])
                "usage" -> Decimal.new(r["value"])
                _ -> nil
              end

            %{
              id: Ecto.UUID.generate(),
              snapshot_id: saved.id,
              external_id: r["id"],
              payload: r,
              amount: amount
            }
          end)

        Enum.chunk_every(entries, 500) |> Enum.each(&Repo.insert_all(Entry, &1))

        Repo.update!(
          Ecto.Changeset.change(connection,
            statuses: Map.put(connection.statuses, dataset, updated_status)
          )
        )

        trim_windows(connection_id, dataset, saved.id)
        {:ok, saved}
      end)
    else
      _ -> {:error, "invalidData"}
    end
  end

  def publish(_, _, _, _), do: {:error, "invalidData"}

  defp normalize_records(records, dataset, connection_id) do
    Enum.reduce_while(records, {:ok, %{}}, fn r, {:ok, acc} ->
      case Domain.normalize(r, dataset) do
        {:ok, row} ->
          valid_connection = dataset == "usage" or row["connectionId"] == connection_id
          previous = acc[row["id"]]

          if valid_connection and (previous == nil or previous == row),
            do: {:cont, {:ok, Map.put(acc, row["id"], row)}},
            else: {:halt, {:error, "invalidData"}}

        error ->
          {:halt, error}
      end
    end)
    |> case do
      {:ok, rows} -> {:ok, Map.values(rows)}
      error -> error
    end
  end

  defp trim_windows(connection_id, dataset, current_id) do
    ids =
      Repo.all(
        from(s in Snapshot,
          where:
            s.connection_id == ^connection_id and s.dataset == ^dataset and s.id != ^current_id,
          order_by: [desc: s.window_start],
          offset: ^(Application.get_env(:cloud_monitor, :max_windows) - 1),
          select: s.id
        )
      )

    Repo.delete_all(from(s in Snapshot, where: s.id in ^ids))
  end

  def mark_failure(id, dataset, code) do
    Repo.transact(fn ->
      c = Repo.one(from(c in Connection, where: c.id == ^id, lock: "FOR UPDATE"))

      if c do
        status =
          Map.merge(c.statuses[dataset] || blank_status(code), %{
            "state" => if(code in Domain.states(), do: code, else: "failed"),
            "reason" => code,
            "complete" => false,
            "lastAttemptAt" => iso(now())
          })

        Repo.update!(Ecto.Changeset.change(c, statuses: Map.put(c.statuses, dataset, status)))
      end

      {:ok, :ok}
    end)
    |> case do
      {:ok, :ok} -> :ok
      error -> error
    end
  end

  def records(dataset, connection_id \\ nil) do
    query =
      from(e in Entry,
        join: s in Snapshot,
        on: e.snapshot_id == s.id,
        where: s.dataset == ^dataset,
        order_by: [e.external_id, s.window_start],
        select: {e, s.updated_at}
      )

    query =
      if connection_id,
        do: from([e, s] in query, where: s.connection_id == ^connection_id),
        else: query

    # A revised overlapping history window chooses the newest instance of each stable source row.
    query
    |> Repo.all()
    |> Enum.sort_by(fn {_, time} -> DateTime.to_unix(time, :microsecond) end, :desc)
    |> Enum.uniq_by(fn {e, _} -> {e.payload["connectionId"], e.external_id} end)
    |> Enum.map(fn {e, _} ->
      key =
        case dataset do
          "costs" -> "amount"
          "usage" -> "value"
          _ -> nil
        end

      if key, do: Map.put(e.payload, key, Domain.amount(e.amount)), else: e.payload
    end)
    |> Enum.sort_by(& &1["id"])
  end

  def budgets, do: Budget |> order_by(:id) |> Repo.all() |> Enum.map(& &1.payload)

  def save_budget(id, payload) do
    with true <- Enum.all?(~w(billingScopeId currency start end basis), &is_binary(payload[&1])),
         true <- Repo.get(Scope, payload["billingScopeId"]) != nil,
         {:ok, amount} <- Domain.decimal(payload["amount"]),
         true <- Decimal.compare(amount, 0) != :lt,
         {:ok, start} <- Domain.timestamp(payload["start"]),
         {:ok, finish} <- Domain.timestamp(payload["end"]),
         true <- Domain.valid_window?(start, finish),
         thresholds = Map.get(payload, "thresholds", ["0.8", "1"]),
         true <-
           is_list(thresholds) and thresholds != [] and
             Enum.all?(thresholds, fn t ->
               case Domain.decimal(t) do
                 {:ok, d} -> Decimal.compare(d, 0) == :gt
                 _ -> false
               end
             end) do
      payload =
        payload
        |> Map.take(~w(billingScopeId currency start end basis amount thresholds))
        |> Map.put("id", id)
        |> Map.put("thresholds", thresholds)

      row = Repo.get(Budget, id) || %Budget{id: id}

      case Repo.insert_or_update(Ecto.Changeset.change(row, amount: amount, payload: payload)) do
        {:ok, _} -> {:ok, payload}
        _ -> {:error, "invalidData"}
      end
    else
      _ -> {:error, "invalidData"}
    end
  end

  def prune do
    cutoff = DateTime.add(now(), -Application.get_env(:cloud_monitor, :retention_days) * 86_400)

    jobs_cutoff =
      DateTime.add(now(), -Application.get_env(:cloud_monitor, :job_retention_days) * 86_400)

    Repo.delete_all(from(s in Snapshot, where: s.window_end < ^cutoff))

    Repo.delete_all(
      from(j in Job, where: j.state in ["succeeded", "failed"] and j.updated_at < ^jobs_cutoff)
    )

    :ok
  end
end
