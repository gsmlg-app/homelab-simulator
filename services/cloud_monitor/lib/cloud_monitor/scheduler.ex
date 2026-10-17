defmodule CloudMonitor.Scheduler do
  @moduledoc "Single-node coordinator; the database owns durable job state."
  use GenServer
  alias CloudMonitor.{Jobs, Store, Repo}
  alias CloudMonitor.Schema.Job
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(opts) do
    enabled = Keyword.get(opts, :enabled, Application.get_env(:cloud_monitor, :scheduler_enabled))
    if enabled, do: Jobs.recover()
    if enabled, do: Process.send_after(self(), :tick, 1_000)
    {:ok, %{enabled: enabled, tasks: %{}}}
  end

  @impl true
  def handle_continue(:tick, state), do: {:noreply, tick(state)}
  @impl true
  def handle_info(:tick, state), do: {:noreply, tick(state)}

  def handle_info({ref, _result}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    case Map.pop(state.tasks, ref) do
      {nil, _} ->
        {:noreply, state}

      {{_, timer, _}, tasks} ->
        Process.cancel_timer(timer)
        {:noreply, %{state | tasks: tasks}}
    end
  end

  def handle_info({:DOWN, ref, :process, _, _}, state) do
    case Map.pop(state.tasks, ref) do
      {nil, _} ->
        {:noreply, state}

      {{id, timer, _}, tasks} ->
        Process.cancel_timer(timer)

        case Repo.get(Job, id) do
          %Job{state: "running"} = job -> Jobs.fail(job, "failed", nil)
          _ -> :ok
        end

        {:noreply, %{state | tasks: tasks}}
    end
  end

  def handle_info({:timeout, ref}, state) do
    case state.tasks[ref] do
      {_, _, pid} -> Process.exit(pid, :kill)
      nil -> :ok
    end

    {:noreply, state}
  end

  defp tick(%{enabled: false} = state), do: state

  defp tick(state) do
    Jobs.schedule_due()
    Store.prune()
    slots = max(Application.get_env(:cloud_monitor, :max_concurrency) - map_size(state.tasks), 0)

    tasks =
      Enum.reduce(Jobs.due(slots), state.tasks, fn job, tasks ->
        task =
          Task.Supervisor.async_nolink(CloudMonitor.CollectorSupervisor, fn ->
            Jobs.run(job.id)
          end)

        timer = Process.send_after(self(), {:timeout, task.ref}, 120_000)
        Map.put(tasks, task.ref, {job.id, timer, task.pid})
      end)

    Process.send_after(self(), :tick, Application.get_env(:cloud_monitor, :tick_ms))
    %{state | tasks: tasks}
  end
end
