defmodule CloudMonitor.Adapters.CloudflareSnapshotTest do
  use CloudMonitor.DataCase, async: true
  @moduletag :tmp_dir

  defmodule HTTP do
    def request(:get, url, _, _, opts) do
      result =
        if String.ends_with?(url, "/info") do
          %{
            "covered" => true,
            "subscriptions" => [%{"billing_cycle_anchor_timestamp" => "2026-10-01T00:00:00Z"}]
          }
        else
          Keyword.fetch!(opts, :billing_response)
        end

      {:ok, %{status: 200, headers: [], body: %{"success" => true, "result" => result}}}
    end
  end

  for {name, body, state} <- [
        {"ambiguous empty", [], "waiting"},
        {"missing prices", [%{}], "unsupported"}
      ] do
    @tag billing_response: body, expected_state: state
    test "#{name} preserves persisted costs and source times", tags do
      data = fixture()
      path = Path.join(tags.tmp_dir, "explicit-token")
      File.write!(path, "test-token")

      connections =
        Enum.map(data["connections"], fn
          %{"id" => "cf-main"} = c ->
            Map.merge(c, %{
              "credentialRef" => "file:" <> path,
              "settings" => %{"accountId" => "account"}
            })

          c ->
            c
        end)

      :ok = Store.configure(%{data | "connections" => connections})
      rows = Enum.filter(data["costs"], &(&1["connectionId"] == "cf-main"))

      assert {:ok, snapshot} =
               Store.publish("cf-main", "costs", window(), %{records: rows, status: status()})

      assert {:ok, job} = Jobs.enqueue("cf-main", "costs", window())
      expected = tags.expected_state

      assert {:error, ^expected} =
               Jobs.run(job.id,
                 adapter: CloudMonitor.Adapters.Cloudflare,
                 adapter_opts: [http: HTTP, billing_response: tags.billing_response]
               )

      assert Repo.one(Snapshot).revision == snapshot.revision
      assert Store.records("costs", "cf-main") == Enum.sort_by(rows, & &1["id"])

      assert Store.connection("cf-main")["statuses"]["costs"]["sourceAsOf"] ==
               status()["sourceAsOf"]

      assert Store.connection("cf-main")["statuses"]["costs"]["state"] == expected
    end
  end
end
