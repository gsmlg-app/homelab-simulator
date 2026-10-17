import Config

config :cloud_monitor, CloudMonitor.Repo,
  database: "homelab_cloud_monitor_dev",
  socket_dir: "/tmp",
  username: System.get_env("USER"),
  port: 5432
