defmodule CloudMonitor.APITest do
  use CloudMonitor.DataCase, async: true
  import Phoenix.ConnTest
  @endpoint CloudMonitorWeb.Endpoint
  defp authorized(conn),
    do: Plug.Conn.put_req_header(conn, "authorization", "Bearer offline-test-application-token")

  test "bearer is mandatory and GET reads snapshots without enqueuing cloud calls" do
    configure_fixture()

    assert %{"error" => %{"code" => "authenticationFailed"}} =
             build_conn() |> get("/v1/connections") |> json_response(401)

    assert %{"schemaVersion" => 1, "data" => connections} =
             build_conn() |> authorized() |> get("/v1/connections") |> json_response(200)

    assert Enum.any?(
             connections,
             &(&1["id"] == "unconfigured" and &1["statuses"]["costs"]["state"] == "unconfigured")
           )

    assert Repo.aggregate(Job, :count) == 0
  end

  test "encoded provider resource identifiers retain slashes through the HTTP route" do
    configure_fixture()
    resource_id = "aws:123:us-east-1:instance/i-123"

    row = %{
      "id" => "usage-slash",
      "resourceId" => resource_id,
      "service" => "EC2",
      "metric" => "CPUUtilization",
      "unit" => "Percent",
      "start" => "2026-10-01T00:00:00Z",
      "end" => "2026-10-01T01:00:00Z",
      "granularity" => "hour",
      "aggregation" => "average",
      "value" => "12.5",
      "source" => "offline-fixture"
    }

    assert {:ok, _} =
             Store.publish("aws-main", "usage", window(), %{records: [row], status: status()})

    path = "/v1/resources/" <> URI.encode_www_form(resource_id) <> "/usage"
    assert %{"data" => [^row]} = build_conn() |> authorized() |> get(path) |> json_response(200)
  end

  test "query-bound cursor pages all resources and rejects changed query or revision" do
    data = configure_fixture()
    rows = Enum.filter(data["resources"], &(&1["connectionId"] == "aws-main"))

    assert {:ok, _} =
             Store.publish("aws-main", "resources", window(), %{records: rows, status: status()})

    first =
      build_conn()
      |> authorized()
      |> get("/v1/connections/aws-main/resources?limit=50")
      |> json_response(200)

    assert length(first["data"]) == 50
    assert first["nextCursor"] != nil
    cursor = URI.encode_www_form(first["nextCursor"])

    second =
      build_conn()
      |> authorized()
      |> get("/v1/connections/aws-main/resources?limit=50&cursor=" <> cursor)
      |> json_response(200)

    assert MapSet.disjoint?(
             MapSet.new(first["data"], & &1["id"]),
             MapSet.new(second["data"], & &1["id"])
           )

    assert %{"error" => %{"code" => "invalidCursor"}} =
             build_conn()
             |> authorized()
             |> get("/v1/connections/aws-main/resources?limit=20&cursor=" <> cursor)
             |> json_response(400)

    assert {:ok, _} =
             Store.publish("aws-main", "resources", window(), %{records: rows, status: status()})

    assert %{"error" => %{"code" => "revisionExpired"}} =
             build_conn()
             |> authorized()
             |> get("/v1/connections/aws-main/resources?limit=50&cursor=" <> cursor)
             |> json_response(409)
  end

  test "manual sync deduplicates, budgets are local writes, query limits reject wide windows" do
    data = configure_fixture()

    first =
      build_conn()
      |> authorized()
      |> post("/v1/connections/aws-main/sync", %{"dataset" => "costs"})
      |> json_response(202)

    second =
      build_conn()
      |> authorized()
      |> post("/v1/connections/aws-main/sync", %{"dataset" => "costs"})
      |> json_response(202)

    assert first["id"] == second["id"]

    assert %{"data" => %{"state" => "queued"}} =
             build_conn()
             |> authorized()
             |> get("/v1/sync-jobs/" <> first["id"])
             |> json_response(200)

    [rule] = data["budgets"]

    assert ^rule =
             build_conn()
             |> authorized()
             |> put("/v1/budgets/demo-budget", rule)
             |> json_response(200)

    assert %{"data" => [^rule]} =
             build_conn() |> authorized() |> get("/v1/budgets") |> json_response(200)

    assert %{"error" => %{"code" => "invalidQuery"}} =
             build_conn()
             |> authorized()
             |> get("/v1/connections/aws-main/costs?limit=101")
             |> json_response(400)

    assert %{"error" => %{"code" => "invalidQuery"}} =
             build_conn()
             |> authorized()
             |> get(
               "/v1/cloud-center/overview?start=2026-01-01T00:00:00Z&end=2027-01-01T00:00:00Z"
             )
             |> json_response(400)

    assert Repo.aggregate(Job, :count) == 1
  end

  test "query-window overview sums daily intervals without prorating incompatible native periods" do
    data = configure_fixture()
    base = hd(data["costs"])

    daily = [
      Map.merge(base, %{
        "id" => "daily1",
        "amount" => "0.1",
        "start" => "2026-10-01T00:00:00.000Z",
        "end" => "2026-10-02T00:00:00.000Z"
      }),
      Map.merge(base, %{
        "id" => "daily2",
        "amount" => "0.2",
        "start" => "2026-10-02T00:00:00.000Z",
        "end" => "2026-10-03T00:00:00.000Z"
      }),
      Map.merge(base, %{
        "id" => "coarse",
        "amount" => "900",
        "start" => "2026-09-15T00:00:00.000Z",
        "end" => "2026-10-15T00:00:00.000Z"
      })
    ]

    assert {:ok, _} =
             Store.publish("aws-main", "costs", window(), %{records: daily, status: status()})

    result =
      build_conn()
      |> authorized()
      |> get(
        "/v1/cloud-center/overview?start=2026-10-01T00:00:00.000Z&end=2026-11-01T00:00:00.000Z"
      )
      |> json_response(200)

    assert [
             %{
               "amount" => "0.3",
               "start" => "2026-10-01T00:00:00.000Z",
               "end" => "2026-11-01T00:00:00.000Z"
             }
           ] = result["data"]["totals"]

    assert [%{"amount" => "900"}] = result["data"]["unmappedTotals"]
    assert "nativePeriodNotAllocated" in result["data"]["coverage"]
  end

  test "connection configuration and status writes expire metadata cursors" do
    data = configure_fixture()
    first = build_conn() |> authorized() |> get("/v1/connections?limit=1") |> json_response(200)

    changed =
      Enum.map(data["connections"], &Map.put(&1, "displayName", &1["displayName"] <> " revised"))

    :ok = Store.configure(%{"connections" => changed, "scopes" => data["scopes"]})
    cursor = URI.encode_www_form(first["nextCursor"])

    assert %{"error" => %{"code" => "revisionExpired"}} =
             build_conn()
             |> authorized()
             |> get("/v1/connections?limit=1&cursor=" <> cursor)
             |> json_response(409)

    first = build_conn() |> authorized() |> get("/v1/connections?limit=1") |> json_response(200)
    :ok = Store.mark_failure("aws-main", "costs", "permissionDenied")
    cursor = URI.encode_www_form(first["nextCursor"])

    assert %{"error" => %{"code" => "revisionExpired"}} =
             build_conn()
             |> authorized()
             |> get("/v1/connections?limit=1&cursor=" <> cursor)
             |> json_response(409)
  end

  test "budget updates expire budget cursors without publishing a snapshot" do
    data = configure_fixture()
    [rule] = data["budgets"]
    {:ok, _} = Store.save_budget("budget-a", rule)
    {:ok, _} = Store.save_budget("budget-b", rule)
    first = build_conn() |> authorized() |> get("/v1/budgets?limit=1") |> json_response(200)
    {:ok, _} = Store.save_budget("budget-b", Map.put(rule, "amount", "999"))
    cursor = URI.encode_www_form(first["nextCursor"])

    assert %{"error" => %{"code" => "revisionExpired"}} =
             build_conn()
             |> authorized()
             |> get("/v1/budgets?limit=1&cursor=" <> cursor)
             |> json_response(409)
  end
end
