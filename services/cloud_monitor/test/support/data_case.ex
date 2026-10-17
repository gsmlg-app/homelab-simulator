defmodule CloudMonitor.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto.Query
      alias CloudMonitor.{Repo, Store, Jobs}
      alias CloudMonitor.Schema.{Connection, Snapshot, Entry, Job}
      import CloudMonitor.DataCase
    end
  end

  setup tags do
    owner =
      Ecto.Adapters.SQL.Sandbox.start_owner!(CloudMonitor.Repo,
        shared: not tags[:async],
        isolation: "REPEATABLE READ"
      )

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)
    :ok
  end

  def fixture do
    Path.expand("../../../../docs/cloud-center/fixtures/demo-v1.json", __DIR__)
    |> File.read!()
    |> JSON.decode!()
  end

  def configure_fixture do
    data = fixture()
    :ok = CloudMonitor.Store.configure(data)
    data
  end

  def window, do: %{start: ~U[2026-10-01 00:00:00.000Z], end: ~U[2026-11-01 00:00:00.000Z]}

  def status,
    do: %{
      "state" => "available",
      "complete" => true,
      "sourceAsOf" => "2026-10-12T00:00:00.000Z",
      "observedStart" => "2026-10-01T00:00:00.000Z",
      "observedEnd" => "2026-10-12T00:00:00.000Z",
      "reason" => nil
    }
end

defmodule CloudMonitor.TestAdapter do
  @behaviour CloudMonitor.Adapter
  def collect(connection, dataset, _window, opts) do
    case Keyword.get(opts, :test_result) do
      nil ->
        records =
          CloudMonitor.DataCase.fixture()[dataset]
          |> Enum.filter(&(&1["connectionId"] == connection["id"]))

        {:ok, %{records: records, status: CloudMonitor.DataCase.status()}}

      result ->
        result
    end
  end
end
