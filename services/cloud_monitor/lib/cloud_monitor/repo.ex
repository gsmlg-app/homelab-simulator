defmodule CloudMonitor.Repo do
  use Ecto.Repo, otp_app: :cloud_monitor, adapter: Ecto.Adapters.Postgres
end
