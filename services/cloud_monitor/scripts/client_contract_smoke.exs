# Isolated offline native-client protocol smoke. No provider identity is loaded.
alias CloudMonitor.{Repo, Store}

unless Repo.config()[:database] == "homelab_cloud_monitor_dev" and
         Application.get_env(:cloud_monitor, :scheduler_enabled) == false and
         Application.get_env(:cloud_monitor, :connections) == [] do
  raise "Requires isolated development database, no configured providers and scheduler disabled"
end

# Synthetic identities must never dispatch the registered real adapters.
Application.put_env(:cloud_monitor, :adapters, %{})

root = Path.expand("../../..", __DIR__)

fixture =
  root |> Path.join("docs/cloud-center/fixtures/demo-v1.json") |> File.read!() |> JSON.decode!()

connection = Enum.find(fixture["connections"], &(&1["id"] == "aws-main"))
scope = Enum.find(fixture["scopes"], &(&1["id"] == connection["billingScopeId"]))

connection =
  Map.merge(connection, %{"id" => "client-contract", "billingScopeId" => "client-contract-scope"})

scope =
  Map.merge(scope, %{
    "id" => "client-contract-scope",
    "parentId" => nil,
    "authoritativeConnectionId" => "client-contract"
  })

:ok = Store.configure(%{"connections" => [connection], "scopes" => [scope]})
window = %{start: ~U[2026-10-01 00:00:00Z], end: ~U[2026-11-01 00:00:00Z]}

status =
  Map.merge(Store.blank_status("available"), %{
    "complete" => true,
    "sourceAsOf" => "2026-10-12T00:00:00Z"
  })

rewrite =
  &Map.merge(&1, %{
    "connectionId" => "client-contract",
    "billingScopeId" => "client-contract-scope"
  })

costs = fixture["costs"] |> Enum.filter(&(&1["connectionId"] == "aws-main")) |> Enum.map(rewrite)

resources =
  fixture["resources"]
  |> Enum.filter(&(&1["connectionId"] == "aws-main"))
  |> Enum.take(2)
  |> Enum.map(rewrite)
  |> Enum.sort_by(& &1["id"])

{:ok, _} = Store.publish("client-contract", "costs", window, %{records: costs, status: status})

{:ok, _} =
  Store.publish("client-contract", "resources", window, %{records: resources, status: status})

usage =
  fixture["usage"]
  |> hd()
  |> Map.merge(%{
    "id" => "client-contract-usage",
    "resourceId" => hd(resources)["id"],
    "value" => "12.5"
  })

{:ok, _} = Store.publish("client-contract", "usage", window, %{records: [usage], status: status})

{:ok, _} =
  Store.save_budget(
    "client-contract-budget",
    hd(fixture["budgets"]) |> Map.put("billingScopeId", "client-contract-scope")
  )

{output, code} =
  System.cmd("dart", ["run", "tool/cloud_center_backend_smoke.dart"],
    cd: root,
    env: [{"CLOUD_CONTRACT_FIXTURE", "true"}],
    stderr_to_stdout: true
  )

IO.write(output)
if code != 0, do: raise("Dart contract smoke exited #{code}")
