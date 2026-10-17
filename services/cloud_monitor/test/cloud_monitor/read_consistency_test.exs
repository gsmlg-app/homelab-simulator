defmodule CloudMonitor.ReadConsistencyTest do
  use ExUnit.Case, async: false
  import Ecto.Query
  import Phoenix.ConnTest
  alias Ecto.Adapters.SQL.Sandbox
  alias CloudMonitor.{Repo, Store}
  alias CloudMonitor.Schema.{Connection, Scope, Snapshot, Budget, Job}
  @endpoint CloudMonitorWeb.Endpoint

  setup do
    :ok = Sandbox.checkout(Repo, sandbox: false)
    id = "cc04-race-" <> Ecto.UUID.generate()
    scope_id = id <> "-scope"
    fixture = CloudMonitor.DataCase.fixture()

    connection = %{
      "id" => id,
      "provider" => "aws",
      "displayName" => "Before",
      "billingScopeId" => scope_id
    }

    scope = %{
      "id" => scope_id,
      "provider" => "aws",
      "accountId" => "offline",
      "parentId" => nil,
      "authoritativeConnectionId" => id
    }

    :ok = Store.configure(%{"connections" => [connection], "scopes" => [scope]})

    rewrite =
      &Map.merge(&1, %{
        "id" => id <> ":" <> &1["id"],
        "connectionId" => id,
        "billingScopeId" => scope_id
      })

    resources =
      fixture["resources"] |> Enum.take(3) |> Enum.map(rewrite) |> Enum.sort_by(& &1["id"])

    cost =
      fixture["costs"]
      |> Enum.find(&(&1["id"] == "aws-usage"))
      |> rewrite.()
      |> Map.put("amount", "10")

    for {dataset, rows} <- [{"resources", resources}, {"costs", [cost]}] do
      {:ok, _} =
        Store.publish(id, dataset, CloudMonitor.DataCase.window(), %{
          records: rows,
          status: CloudMonitor.DataCase.status()
        })
    end

    on_exit(fn ->
      Sandbox.unboxed_run(Repo, fn ->
        Repo.delete_all(from(j in Job, where: j.connection_id == ^id))
        Repo.delete_all(from(s in Snapshot, where: s.connection_id == ^id))

        Repo.delete_all(
          from(b in Budget, where: fragment("?->>'billingScopeId'", b.payload) == ^scope_id)
        )

        Repo.delete_all(from(c in Connection, where: c.id == ^id))
        Repo.delete_all(from(s in Scope, where: s.id == ^scope_id))
      end)
    end)

    %{
      id: id,
      scope_id: scope_id,
      resources: resources,
      cost: cost,
      connection: connection,
      scope: scope
    }
  end

  test "a committed publication cannot attach a new revision to old page rows", context do
    old_revision = Store.revision()

    result =
      race_get("/v1/connections/#{context.id}/resources?limit=1", "resources", fn ->
        rows = Enum.map(context.resources, &Map.put(&1, "name", "After"))

        {:ok, _} =
          Store.publish(context.id, "resources", CloudMonitor.DataCase.window(), %{
            records: rows,
            status: CloudMonitor.DataCase.status()
          })
      end)

    assert result["data"] == Enum.take(context.resources, 1)
    assert result["revision"] == old_revision
    refute Store.revision() == old_revision
    cursor = URI.encode_www_form(result["nextCursor"])

    assert %{"error" => %{"code" => "revisionExpired"}} =
             authorized()
             |> get("/v1/connections/#{context.id}/resources?limit=1&cursor=#{cursor}")
             |> json_response(409)
  end

  test "overview amounts, statuses, resource count and revision share one database snapshot",
       context do
    old_revision = Store.revision()
    old_status = Store.connection(context.id)["statuses"]

    result =
      race_get(
        "/v1/connections/#{context.id}/overview?start=2026-10-01T00:00:00Z&end=2026-11-01T00:00:00Z",
        "costs",
        fn ->
          {:ok, _} =
            Store.publish(context.id, "costs", CloudMonitor.DataCase.window(), %{
              records: [Map.put(context.cost, "amount", "20")],
              status: CloudMonitor.DataCase.status()
            })

          {:ok, _} =
            Store.publish(context.id, "resources", CloudMonitor.DataCase.window(), %{
              records: [],
              status: CloudMonitor.DataCase.status()
            })
        end
      )

    assert result["data"]["resourceCount"] == 3
    assert result["data"]["statuses"] == old_status
    assert [%{"amount" => "10"}] = result["data"]["totals"]
    assert result["revision"] == old_revision
  end

  test "cross-cloud overview cannot mix earlier costs with newly failed connection status",
       context do
    old_revision = Store.revision()
    old = Store.connection(context.id)

    result =
      race_get(
        "/v1/cloud-center/overview?start=2026-10-01T00:00:00Z&end=2026-11-01T00:00:00Z",
        "costs",
        fn ->
          :ok = Store.mark_failure(context.id, "costs", "permissionDenied")
        end
      )

    assert Enum.find(result["data"]["connections"], &(&1["id"] == context.id)) == old
    assert result["revision"] == old_revision
  end

  defp authorized,
    do:
      build_conn()
      |> Plug.Conn.put_req_header("authorization", "Bearer offline-test-application-token")

  defp race_get(path, dataset, publish) do
    owner = self()

    task =
      Task.async(fn ->
        :ok = Sandbox.checkout(Repo, sandbox: false)

        try do
          [[backend]] = Repo.query!("SELECT pg_backend_pid()").rows
          send(owner, {:reader_ready, self(), backend})

          receive do
            :start -> authorized() |> get(path) |> json_response(200)
          end
        after
          Sandbox.checkin(Repo)
        end
      end)

    assert_receive {:reader_ready, reader, reader_backend}, 2000
    [[writer_backend]] = Repo.query!("SELECT pg_backend_pid()").rows
    refute reader_backend == writer_backend
    handler = {__MODULE__, make_ref()}

    :ok =
      :telemetry.attach(
        handler,
        [:cloud_monitor, :repo, :query],
        &__MODULE__.pause_after_rows/4,
        {owner, reader, dataset}
      )

    try do
      send(reader, :start)
      assert_receive {:rows_read, ^reader}, 2000
      publish.()
      send(reader, :continue)
      Task.await(task, 5000)
    after
      :telemetry.detach(handler)
      send(reader, :continue)
      Task.shutdown(task, :brutal_kill)
    end
  end

  def pause_after_rows(_event, _measurements, metadata, {owner, reader, dataset}) do
    if self() == reader and String.contains?(metadata.query, "cloud_entries") and
         dataset in metadata.params and not Process.get(:cc04_rows_paused, false) do
      Process.put(:cc04_rows_paused, true)
      send(owner, {:rows_read, self()})

      receive do
        :continue -> :ok
      after
        5000 -> raise "Concurrent publication test did not resume reader"
      end
    end
  end
end
