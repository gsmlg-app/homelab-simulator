defmodule CloudMonitor.Repo.Migrations.CloudMonitor do
  use Ecto.Migration

  def change do
    create table(:cloud_connections, primary_key: false) do
      add :id, :text, primary_key: true
      add :config, :map, null: false
      add :statuses, :map, null: false, default: %{}
      timestamps(type: :utc_datetime_usec)
    end

    create table(:billing_scopes, primary_key: false) do
      add :id, :text, primary_key: true
      add :data, :map, null: false
    end

    create table(:cloud_snapshots, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :connection_id, references(:cloud_connections, type: :text), null: false
      add :dataset, :text, null: false
      add :window_key, :text, null: false
      add :window_start, :utc_datetime_usec, null: false
      add :window_end, :utc_datetime_usec, null: false
      add :revision, :text, null: false
      add :status, :map, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:cloud_snapshots, [:connection_id, :dataset, :window_key])

    create table(:cloud_entries, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :snapshot_id, references(:cloud_snapshots, type: :uuid, on_delete: :delete_all),
        null: false

      add :external_id, :text, null: false
      add :amount, :decimal
      add :payload, :map, null: false
    end

    create unique_index(:cloud_entries, [:snapshot_id, :external_id])

    create table(:cloud_jobs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :connection_id, references(:cloud_connections, type: :text), null: false
      add :dataset, :text, null: false
      add :state, :text, null: false
      add :window_start, :utc_datetime_usec, null: false
      add :window_end, :utc_datetime_usec, null: false
      add :attempts, :integer, null: false, default: 0
      add :error_code, :text
      add :next_run_at, :utc_datetime_usec, null: false
      add :started_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:cloud_jobs, [:connection_id, :dataset],
             where: "state IN ('queued','running','retry')",
             name: :one_active_dataset_job
           )

    create index(:cloud_jobs, [:state, :next_run_at])

    create table(:cloud_budgets, primary_key: false) do
      add :id, :text, primary_key: true
      add :amount, :decimal, null: false
      add :payload, :map, null: false
      timestamps(type: :utc_datetime_usec)
    end
  end
end
