defmodule CloudMonitor.Jobs do
  import Ecto.Query
  alias CloudMonitor.{Repo, Store, Domain}
  alias CloudMonitor.Schema.{Connection, Job}
  @active ~w(queued running retry)
  @retryable ~w(rateLimited failed networkFailure timeout)
  def default_window(dataset, time \\ DateTime.utc_now()) do
    if dataset == "costs" do
      month = Date.new!(time.year, time.month, 1)
      previous = Date.shift(month, month: -2)
      finish = Date.shift(month, month: 1)

      %{
        start: DateTime.new!(previous, ~T[00:00:00.000], "Etc/UTC"),
        end: DateTime.new!(finish, ~T[00:00:00.000], "Etc/UTC")
      }
    else
      %{start: DateTime.add(time, -86_400), end: time}
    end
  end

  def enqueue(connection_id, dataset, window \\ nil, opts \\ []) do
    window = window || default_window(dataset)

    if dataset in Store.datasets() and Domain.valid_window?(window.start, window.end) do
      window = %{
        start: Domain.persistence_time(window.start),
        end: Domain.persistence_time(window.end)
      }

      Repo.transact(fn ->
        connection =
          Repo.one(from(c in Connection, where: c.id == ^connection_id, lock: "FOR UPDATE"))

        if is_nil(connection), do: Repo.rollback("notFound")

        existing =
          Repo.one(
            from(j in Job,
              where:
                j.connection_id == ^connection_id and j.dataset == ^dataset and
                  j.state in ^@active
            )
          )

        latest =
          Repo.one(
            from(j in Job,
              where: j.connection_id == ^connection_id and j.dataset == ^dataset,
              order_by: [desc: j.inserted_at],
              limit: 1
            )
          )

        cooldown =
          Keyword.get(
            opts,
            :cooldown_seconds,
            Application.get_env(:cloud_monitor, :cooldown_seconds)
          )

        cond do
          existing ->
            {:ok, existing}

          latest && DateTime.diff(Store.now(), latest.inserted_at) < cooldown ->
            Repo.rollback("cooldown")

          true ->
            Repo.insert(%Job{
              connection_id: connection_id,
              dataset: dataset,
              state: "queued",
              window_start: window.start,
              window_end: window.end,
              next_run_at: Store.now()
            })
        end
      end)
    else
      {:error, "invalidQuery"}
    end
  end

  def claim(id) do
    Repo.transact(fn ->
      job = Repo.one(from(j in Job, where: j.id == ^id, lock: "FOR UPDATE"))

      cond do
        is_nil(job) ->
          Repo.rollback("notFound")

        job.state not in ["queued", "retry"] ->
          Repo.rollback("notDue")

        DateTime.compare(job.next_run_at, Store.now()) == :gt ->
          Repo.rollback("notDue")

        true ->
          Repo.update(
            Ecto.Changeset.change(job,
              state: "running",
              attempts: job.attempts + 1,
              started_at: Store.now()
            )
          )
      end
    end)
  end

  def recover do
    Repo.update_all(from(j in Job, where: j.state == "running"),
      set: [
        state: "queued",
        next_run_at: Store.now(),
        error_code: "workerInterrupted",
        updated_at: Store.now()
      ]
    )

    :ok
  end

  def due(limit),
    do:
      Repo.all(
        from(j in Job,
          where: j.state in ["queued", "retry"] and j.next_run_at <= ^Store.now(),
          order_by: j.next_run_at,
          limit: ^limit
        )
      )

  def run(id, opts \\ []) do
    with {:ok, job} <- claim(id) do
      config = Store.server_connection(job.connection_id)

      adapter =
        Keyword.get(opts, :adapter) ||
          Application.get_env(:cloud_monitor, :adapters)[config["provider"]]

      adapter_opts =
        [
          http: CloudMonitor.HTTP,
          request_budget: Application.get_env(:cloud_monitor, :request_budget),
          max_pages: Application.get_env(:cloud_monitor, :max_pages),
          max_resources: Application.get_env(:cloud_monitor, :max_resources)
        ]
        |> Keyword.merge(Keyword.get(opts, :adapter_opts, []))

      result = safe_collect(adapter, config, job, adapter_opts)

      case result do
        {:ok, output} ->
          case Store.publish(
                 job.connection_id,
                 job.dataset,
                 %{start: job.window_start, end: job.window_end},
                 output
               ) do
            {:ok, snapshot} ->
              Repo.update!(Ecto.Changeset.change(job, state: "succeeded", error_code: nil))
              {:ok, snapshot}

            {:error, code} ->
              fail(job, code, nil)
          end

        {:error, code, retry_after} ->
          fail(job, code, retry_after)
      end
    end
  end

  defp safe_collect(nil, _, _, _), do: {:error, "unconfigured", nil}

  defp safe_collect(adapter, config, job, opts) do
    try do
      case adapter.collect(
             config,
             job.dataset,
             %{start: job.window_start, end: job.window_end},
             opts
           ) do
        {:ok, %{records: records, status: status}} when is_list(records) and is_map(status) ->
          {:ok, %{records: records, status: status}}

        {:error, code, retry_after} when is_binary(code) ->
          code =
            if code in ~w(configurationError invalidConfiguration) and
                 config["credentialRef"] in [nil, ""],
               do: "unconfigured",
               else: safe_code(code)

          {:error, code, retry_after}

        _ ->
          {:error, "invalidData", nil}
      end
    rescue
      _ -> {:error, "failed", nil}
    catch
      _, _ -> {:error, "failed", nil}
    end
  end

  def safe_code("invalidConfiguration"), do: "configurationError"

  def safe_code(code),
    do:
      if(
        code in (Domain.states() ++
                   ~w(invalidData requestBudgetExceeded resourceLimitExceeded paginationCycle networkFailure timeout configurationError)),
        do: code,
        else: "failed"
      )

  def fail(job, code, retry_after) do
    code = safe_code(code)
    Store.mark_failure(job.connection_id, job.dataset, code)

    retry =
      code in @retryable and job.attempts < Application.get_env(:cloud_monitor, :max_attempts)

    delay =
      if is_integer(retry_after) and retry_after >= 0,
        do: min(retry_after, 86_400),
        else: min(trunc(:math.pow(2, job.attempts)) * 30, 3600)

    Repo.update!(
      Ecto.Changeset.change(job,
        state: if(retry, do: "retry", else: "failed"),
        error_code: code,
        next_run_at: DateTime.add(Store.now(), delay)
      )
    )

    {:error, code}
  end

  def wire(job),
    do: %{
      "id" => job.id,
      "connectionId" => job.connection_id,
      "dataset" => job.dataset,
      "state" => job.state,
      "attempts" => job.attempts,
      "errorCode" => job.error_code
    }

  def schedule_due do
    for connection <- Repo.all(Connection), dataset <- Store.datasets() do
      intervals = get_in(connection.config, ["settings", "intervalSeconds"]) || %{}

      default =
        case dataset do
          "resources" -> 1800
          "usage" -> 900
          "costs" -> if connection.config["provider"] == "gcp", do: 21_600, else: 86_400
        end

      interval = max(Map.get(intervals, dataset, default), 60)
      status = connection.statuses[dataset] || %{}

      enabled =
        connection.config["credentialRef"] != nil and
          (dataset != "usage" or get_in(connection.config, ["settings", "usageEnabled"]) == true)

      last_attempt =
        case Domain.timestamp(status["lastAttemptAt"]) do
          {:ok, value} -> value
          _ -> nil
        end

      if enabled and (last_attempt == nil or DateTime.diff(Store.now(), last_attempt) >= interval),
        do: enqueue(connection.id, dataset)
    end

    :ok
  end
end
