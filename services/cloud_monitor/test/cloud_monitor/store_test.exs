defmodule CloudMonitor.StoreTest do
  use CloudMonitor.DataCase, async: true

  test "atomic publication replaces rather than accumulates and preserves exact numeric money" do
    data = configure_fixture()
    rows = Enum.filter(data["costs"], &(&1["connectionId"] == "aws-main"))

    assert {:ok, first} =
             Store.publish("aws-main", "costs", window(), %{records: rows, status: status()})

    assert {:ok, second} =
             Store.publish("aws-main", "costs", window(), %{
               records: rows ++ rows,
               status: status()
             })

    refute first.revision == second.revision
    assert Repo.aggregate(Entry, :count) == length(rows)

    assert %Decimal{} =
             Repo.one(from(e in Entry, where: e.external_id == "aws-usage", select: e.amount))

    adjusted =
      Enum.map(rows, fn r ->
        if r["id"] == "aws-usage", do: %{r | "amount" => "90.123456789123456789"}, else: r
      end)

    assert {:ok, _} =
             Store.publish("aws-main", "costs", window(), %{records: adjusted, status: status()})

    assert Enum.any?(Store.records("costs"), &(&1["amount"] == "90.123456789123456789"))
  end

  test "invalid or partial page publication cannot replace prior snapshot" do
    data = configure_fixture()
    rows = Enum.filter(data["costs"], &(&1["connectionId"] == "aws-main"))

    assert {:ok, old} =
             Store.publish("aws-main", "costs", window(), %{records: rows, status: status()})

    assert {:error, "invalidData"} =
             Store.publish("aws-main", "costs", window(), %{
               records: [%{"id" => "bad"}],
               status: status()
             })

    assert Repo.one(Snapshot).revision == old.revision
    assert {:ok, _} = Jobs.enqueue("aws-main", "costs", window())
    [job] = Repo.all(Job)

    assert {:error, "permissionDenied"} =
             Jobs.run(job.id,
               adapter: CloudMonitor.TestAdapter,
               adapter_opts: [test_result: {:error, "permissionDenied", nil}]
             )

    assert Repo.one(Snapshot).revision == old.revision
    assert Store.connection("aws-main")["statuses"]["costs"]["state"] == "permissionDenied"

    assert Store.connection("aws-main")["statuses"]["costs"]["sourceAsOf"] ==
             status()["sourceAsOf"]
  end

  test "resource failures do not clear costs and source timestamps do not advance on refresh" do
    data = configure_fixture()
    rows = Enum.filter(data["costs"], &(&1["connectionId"] == "aws-main"))

    assert {:ok, _} =
             Store.publish("aws-main", "costs", window(), %{records: rows, status: status()})

    assert :ok = Store.mark_failure("aws-main", "usage", "unsupported")

    assert Store.connection("aws-main")["statuses"]["costs"]["sourceAsOf"] ==
             "2026-10-12T00:00:00.000Z"

    assert Store.records("costs") == Enum.sort_by(rows, & &1["id"])
  end

  test "equivalent instant precision replaces one canonical snapshot and preserves microseconds" do
    data = configure_fixture()
    rows = Enum.filter(data["costs"], &(&1["connectionId"] == "aws-main"))

    windows = [
      window(),
      %{start: ~U[2026-10-01 00:00:00Z], end: ~U[2026-11-01 00:00:00Z]},
      %{start: ~U[2026-10-01 00:00:00.000000Z], end: ~U[2026-11-01 00:00:00.000000Z]}
    ]

    for w <- windows do
      assert {:ok, snapshot} =
               Store.publish("aws-main", "costs", w, %{records: rows, status: status()})

      assert snapshot.window_start.microsecond == {0, 6}
    end

    assert Repo.aggregate(Snapshot, :count) == 1
    precise = %{start: ~U[2026-10-01 00:00:00.123456Z], end: ~U[2026-11-01 00:00:00.654321Z]}

    assert {:ok, snapshot} =
             Store.publish("aws-main", "costs", precise, %{records: [], status: status()})

    assert snapshot.window_start == precise.start
    assert snapshot.window_end == precise.end
  end

  test "connections expose no credentials and aliases have a single authority" do
    configure_fixture()

    assert Enum.all?(
             Store.connections(),
             &(Map.keys(&1) |> Enum.sort() ==
                 ~w(billingScopeId capabilities displayName id provider statuses))
           )

    assert Enum.count(Store.scopes(), &(&1["id"] == "scope-aws-main")) == 1
  end
end
