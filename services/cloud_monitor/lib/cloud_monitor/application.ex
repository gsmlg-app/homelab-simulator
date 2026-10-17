defmodule CloudMonitor.Application do
  use Application
  @impl true
  def start(_type, _args) do
    children = [
      CloudMonitor.Repo,
      {Phoenix.PubSub, name: CloudMonitor.PubSub},
      {CloudMonitor.Scheduler, []},
      {Task.Supervisor,
       name: CloudMonitor.CollectorSupervisor,
       max_children: Application.get_env(:cloud_monitor, :max_concurrency)},
      CloudMonitorWeb.Endpoint
    ]

    # Restarting the coordinator also terminates its old workers before recovery.
    case Supervisor.start_link(children, strategy: :rest_for_one, name: CloudMonitor.Supervisor) do
      {:ok, pid} ->
        :ok =
          CloudMonitor.Store.configure(%{
            "connections" => Application.get_env(:cloud_monitor, :connections),
            "scopes" => Application.get_env(:cloud_monitor, :scopes)
          })

        {:ok, pid}

      error ->
        error
    end
  end
end
