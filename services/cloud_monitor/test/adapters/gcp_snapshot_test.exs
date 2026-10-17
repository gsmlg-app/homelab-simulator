defmodule CloudMonitor.Adapters.GCPSnapshotTest do
  use CloudMonitor.DataCase, async: true
  @moduletag :tmp_dir

  defmodule HTTP do
    def request(:get, _url, _headers, _body, _opts) do
      ok(%{"timePartitioning" => %{"field" => "usage_start_time"}, "location" => "US"})
    end

    def request(:post, _url, _headers, _body, _opts) do
      ok(%{
        "jobComplete" => true,
        "jobReference" => %{
          "projectId" => "query-project",
          "jobId" => "empty_export",
          "location" => "US"
        },
        "totalRows" => "0",
        "rows" => []
      })
    end

    defp ok(body), do: {:ok, %{status: 200, headers: [], body: body}}
  end

  test "successful empty export preserves persisted costs, revision and source time", tags do
    data = fixture()
    path = Path.join(tags.tmp_dir, "explicit-credential")

    File.write!(
      path,
      JSON.encode!(%{
        "type" => "access_token",
        "access_token" => "test-token",
        "expires_at" => "2026-10-18T00:00:00Z"
      })
    )

    connections =
      Enum.map(data["connections"], fn
        %{"id" => "gcp-main"} = c ->
          Map.merge(c, %{
            "credentialRef" => "file:" <> path,
            "settings" => %{
              "queryProject" => "query-project",
              "exportTable" => "billing-project.billing.export_table",
              "billingAccountId" => "ABCDEF-123456-ABCDEF",
              "projects" => ["resource-project"],
              "location" => "US"
            }
          })

        c ->
          c
      end)

    :ok = Store.configure(%{data | "connections" => connections})
    rows = Enum.filter(data["costs"], &(&1["connectionId"] == "gcp-main"))

    assert {:ok, snapshot} =
             Store.publish("gcp-main", "costs", window(), %{records: rows, status: status()})

    assert {:ok, job} = Jobs.enqueue("gcp-main", "costs", window())

    assert {:error, "waiting"} =
             Jobs.run(job.id,
               adapter: CloudMonitor.Adapters.GCP,
               adapter_opts: [http: HTTP, now: ~U[2026-10-17 12:00:00Z]]
             )

    assert Repo.one(Snapshot).revision == snapshot.revision
    assert Store.records("costs", "gcp-main") == Enum.sort_by(rows, & &1["id"])
    persisted = Store.connection("gcp-main")["statuses"]["costs"]
    assert persisted["sourceAsOf"] == status()["sourceAsOf"]
    assert persisted["state"] == "waiting"
  end
end
