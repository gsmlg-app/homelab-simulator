defmodule CloudMonitor.DomainTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.Domain
  @fixture Path.expand("../../../../docs/cloud-center/fixtures/demo-v1.json", __DIR__)
  test "shared fixture exact period totals match Dart and repeated import is idempotent" do
    data = @fixture |> File.read!() |> JSON.decode!()
    assert Domain.totals(data["costs"] ++ data["costs"], data["scopes"]) == data["expectedTotals"]
  end

  test "monthly budget includes daily buckets and excludes different basis and overlapping native periods" do
    data = @fixture |> File.read!() |> JSON.decode!()
    [rule] = data["budgets"]
    base = Enum.find(data["costs"], &(&1["id"] == "aws-usage"))

    rows = [
      Map.merge(base, %{"id" => "day1", "amount" => "40", "end" => "2026-10-02T00:00:00Z"}),
      Map.merge(base, %{
        "id" => "day2",
        "amount" => "45",
        "start" => "2026-10-02T00:00:00Z",
        "end" => "2026-10-03T00:00:00Z"
      }),
      Map.merge(base, %{"id" => "other-basis", "amount" => "999", "basis" => "Other"}),
      Map.merge(base, %{
        "id" => "native-overlap",
        "amount" => "999",
        "start" => "2026-09-15T00:00:00Z"
      })
    ]

    assert %{"state" => "warning", "knownAmount" => "85"} =
             Domain.budget(rule, rows, data["scopes"], false)
  end

  test "query windows select native authority before lifting disjoint days" do
    {base, scopes} = hierarchy_fixture()

    rows = [
      cost(base, "parent-day1", "scope-aws-main", "aws-main", "01", "02", "10"),
      cost(base, "child-day2", "scope-aws-child", "aws-child", "02", "03", "20")
    ]

    assert [%{"amount" => "30"}] = query_totals(rows, scopes)["totals"]
    assert query_totals(rows, scopes)["unmappedTotals"] == []
  end

  test "query window excludes redundant finer child coverage under a containing parent" do
    {base, scopes} = hierarchy_fixture()

    rows = [
      cost(base, "parent", "scope-aws-main", "aws-main", "01", "04", "30"),
      cost(base, "child", "scope-aws-child", "aws-child", "02", "03", "20")
    ]

    assert [%{"amount" => "30"}] = query_totals(rows, scopes)["totals"]
    assert query_totals(rows, scopes)["unmappedTotals"] == []
  end

  test "partially overlapping parent and child buckets remain separate unmapped windows" do
    {base, scopes} = hierarchy_fixture()

    rows = [
      cost(base, "parent", "scope-aws-main", "aws-main", "01", "03", "30"),
      cost(base, "child", "scope-aws-child", "aws-child", "02", "04", "20")
    ]

    result = query_totals(rows, scopes)
    assert result["totals"] == []
    assert Enum.map(result["unmappedTotals"], & &1["amount"]) == ["30", "20"]
  end

  test "hierarchy overlap never suppresses another currency or basis" do
    {base, scopes} = hierarchy_fixture()
    parent = cost(base, "parent", "scope-aws-main", "aws-main", "01", "04", "30")
    child = cost(base, "child", "scope-aws-child", "aws-child", "02", "03", "20")

    rows = [
      parent,
      Map.put(child, "currency", "EUR"),
      Map.merge(child, %{"id" => "child-other-basis", "basis" => "Other"})
    ]

    assert length(query_totals(rows, scopes)["totals"]) == 3
    assert query_totals(rows, scopes)["unmappedTotals"] == []
  end

  defp hierarchy_fixture do
    data = @fixture |> File.read!() |> JSON.decode!()
    {Enum.find(data["costs"], &(&1["id"] == "aws-usage")), data["scopes"]}
  end

  defp cost(base, id, scope, connection, first, last, amount) do
    Map.merge(base, %{
      "id" => id,
      "billingScopeId" => scope,
      "connectionId" => connection,
      "start" => "2026-10-#{first}T00:00:00Z",
      "end" => "2026-10-#{last}T00:00:00Z",
      "amount" => amount
    })
  end

  defp query_totals(rows, scopes),
    do: Domain.window_totals(rows, scopes, "2026-10-01T00:00:00Z", "2026-11-01T00:00:00Z")

  test "child budget uses child view independent of parent totals and partial data stays unknown" do
    data = @fixture |> File.read!() |> JSON.decode!()
    [rule] = data["budgets"]

    assert %{"state" => "warning", "knownAmount" => "85"} =
             Domain.budget(rule, data["costs"], data["scopes"], true)

    assert %{"state" => "exceeded", "knownAmount" => "100"} =
             Domain.budget(
               %{rule | "billingScopeId" => "scope-aws-child"},
               data["costs"],
               data["scopes"],
               false
             )

    assert %{"state" => "unknown"} = Domain.budget(rule, [], data["scopes"], false)

    assert %{"state" => "disabled"} =
             Domain.budget(%{rule | "amount" => "0"}, [], data["scopes"], false)
  end
end
