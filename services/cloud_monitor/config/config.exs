import Config
config :cloud_monitor, ecto_repos: [CloudMonitor.Repo]
config :cloud_monitor, CloudMonitor.Repo, pool_size: 10, log: false

config :cloud_monitor, CloudMonitorWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [json: CloudMonitorWeb.ErrorJSON], layout: false],
  pubsub_server: CloudMonitor.PubSub,
  secret_key_base: String.duplicate("development-only-replace-in-production", 2),
  server: false

config :phoenix, :json_library, JSON
config :postgrex, :json_library, JSON

config :cloud_monitor,
  scheduler_enabled: true,
  tick_ms: 1_000,
  max_concurrency: 3,
  cooldown_seconds: 60,
  max_attempts: 3,
  max_records: 10_000,
  max_windows: 36,
  retention_days: 1100,
  job_retention_days: 30,
  request_budget: 100,
  max_pages: 100,
  max_resources: 1000,
  adapters: %{
    "cloudflare" => CloudMonitor.Adapters.Cloudflare,
    "aws" => CloudMonitor.Adapters.AWS,
    "gcp" => CloudMonitor.Adapters.GCP
  },
  token: nil,
  connections: [],
  scopes: []

import_config "#{config_env()}.exs"
