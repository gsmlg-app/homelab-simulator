defmodule CloudMonitor.Schema.Connection do
  use Ecto.Schema
  @primary_key {:id, :string, autogenerate: false}
  schema "cloud_connections" do
    field(:config, :map)
    field(:statuses, :map, default: %{})
    timestamps(type: :utc_datetime_usec)
  end
end

defmodule CloudMonitor.Schema.Scope do
  use Ecto.Schema
  @primary_key {:id, :string, autogenerate: false}
  schema "billing_scopes" do
    field(:data, :map)
  end
end

defmodule CloudMonitor.Schema.Snapshot do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "cloud_snapshots" do
    field(:connection_id, :string)
    field(:dataset, :string)
    field(:window_key, :string)
    field(:window_start, :utc_datetime_usec)
    field(:window_end, :utc_datetime_usec)
    field(:revision, :string)
    field(:status, :map)
    timestamps(type: :utc_datetime_usec)
  end
end

defmodule CloudMonitor.Schema.Entry do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "cloud_entries" do
    field(:snapshot_id, :binary_id)
    field(:external_id, :string)
    field(:amount, :decimal)
    field(:payload, :map)
  end
end

defmodule CloudMonitor.Schema.Job do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "cloud_jobs" do
    field(:connection_id, :string)
    field(:dataset, :string)
    field(:state, :string, default: "queued")
    field(:window_start, :utc_datetime_usec)
    field(:window_end, :utc_datetime_usec)
    field(:attempts, :integer, default: 0)
    field(:error_code, :string)
    field(:next_run_at, :utc_datetime_usec)
    field(:started_at, :utc_datetime_usec)
    timestamps(type: :utc_datetime_usec)
  end
end

defmodule CloudMonitor.Schema.Budget do
  use Ecto.Schema
  @primary_key {:id, :string, autogenerate: false}
  schema "cloud_budgets" do
    field(:amount, :decimal)
    field(:payload, :map)
    timestamps(type: :utc_datetime_usec)
  end
end
