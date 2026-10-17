import Config

config :cloud_monitor, CloudMonitor.Repo,
  database: "homelab_cloud_monitor_test",
  socket_dir: "/tmp",
  username: System.get_env("USER"),
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox

config :cloud_monitor,
  scheduler_enabled: false,
  token: "offline-test-application-token",
  cooldown_seconds: 0

config :logger, level: :warning
