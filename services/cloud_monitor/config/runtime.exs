import Config

if config_env() != :test do
  if url = System.get_env("DATABASE_URL") do
    config :cloud_monitor, CloudMonitor.Repo, url: url, socket_dir: nil
  end

  if file = System.get_env("CLOUD_MONITOR_CONFIG") do
    settings = file |> File.read!() |> JSON.decode!()

    config :cloud_monitor,
      connections: Map.get(settings, "connections", []),
      scopes: Map.get(settings, "scopes", [])
  end

  config :cloud_monitor,
    token: System.get_env("CLOUD_MONITOR_TOKEN"),
    scheduler_enabled: System.get_env("CLOUD_MONITOR_SCHEDULER", "true") == "true"

  if System.get_env("PHX_SERVER") == "true" do
    config :cloud_monitor, CloudMonitorWeb.Endpoint,
      server: true,
      http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "4100"))]
  end

  if config_env() == :prod do
    config :cloud_monitor, CloudMonitorWeb.Endpoint,
      secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

    if System.get_env("CLOUD_MONITOR_TOKEN") in [nil, ""],
      do: raise("CLOUD_MONITOR_TOKEN is required")
  end
end
