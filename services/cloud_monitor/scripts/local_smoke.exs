# Offline integration evidence only. Never loads a real provider credential.
alias CloudMonitor.{Store, Jobs, Repo, HTTP}
alias CloudMonitor.Schema.Job

unless Repo.config()[:database] in ["homelab_cloud_monitor_dev", "homelab_cloud_monitor_test"] and
         Application.get_env(:cloud_monitor, :scheduler_enabled) == false and
         Application.get_env(:cloud_monitor, :connections) == [] do
  raise "Local smoke requires an isolated development/test database, no configured providers, and scheduler disabled"
end

# This fixture smoke intentionally exercises framework recovery without providers.
Application.put_env(:cloud_monitor, :adapters, %{})

assert = fn condition, label ->
  unless condition, do: raise("Local smoke failed: " <> label)
  IO.puts("PASS " <> label)
end

token = System.fetch_env!("CLOUD_MONITOR_TOKEN")
base = "http://127.0.0.1:" <> System.get_env("PORT", "4100") <> "/v1"

request = fn method, path, body, authorized ->
  headers = if authorized, do: [{"authorization", "Bearer " <> token}], else: []
  {:ok, response} = HTTP.request(method, base <> path, headers, body, allow_localhost: true)
  response
end

fixture =
  Path.expand("../../../docs/cloud-center/fixtures/demo-v1.json", __DIR__)
  |> File.read!()
  |> JSON.decode!()

connection_id = "cc04-local-smoke"
scope_id = "cc04-local-smoke-scope"

connection = %{
  "id" => connection_id,
  "provider" => "aws",
  "displayName" => "Offline fixture smoke only",
  "billingScopeId" => scope_id
}

scope = %{
  "id" => scope_id,
  "provider" => "aws",
  "accountId" => "offline-fixture",
  "parentId" => nil,
  "authoritativeConnectionId" => connection_id
}

:ok = Store.configure(%{"connections" => [connection], "scopes" => [scope]})

rows =
  fixture["costs"]
  |> Enum.filter(&(&1["connectionId"] == "aws-main"))
  |> Enum.map(&Map.merge(&1, %{"connectionId" => connection_id, "billingScopeId" => scope_id}))

window = %{start: ~U[2026-10-01 00:00:00.000Z], end: ~U[2026-11-01 00:00:00.000Z]}

status =
  Map.merge(Store.blank_status("available"), %{
    "complete" => true,
    "sourceAsOf" => "2026-10-12T00:00:00.000Z"
  })

{:ok, snapshot} = Store.publish(connection_id, "costs", window, %{records: rows, status: status})
expected = Store.records("costs", connection_id)
resource_id = "aws:offline:us-east-1:instance/i-smoke"

usage = %{
  "id" => "cc04-smoke-usage",
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

{:ok, _} = Store.publish(connection_id, "usage", window, %{records: [usage], status: status})

usage_response =
  request.(:get, "/resources/" <> URI.encode_www_form(resource_id) <> "/usage", "", true)

assert.(
  usage_response.status == 200 and usage_response.body["data"] == [usage],
  "localhost encoded provider identifier preserves slash"
)

[rule] = fixture["budgets"]

{:ok, budget} =
  Store.save_budget("cc04-local-smoke-budget", Map.put(rule, "billingScopeId", scope_id))

assert.(
  request.(:get, "/connections", "", false).status == 401,
  "localhost bearer authentication"
)

response = request.(:get, "/connections/#{connection_id}/costs", "", true)

assert.(
  response.status == 200 and response.body["data"] == expected,
  "localhost HTTP reads exact persisted fixture costs"
)

{:ok, job} = Jobs.enqueue(connection_id, "costs", window, cooldown_seconds: 0)
{:ok, duplicate} = Jobs.enqueue(connection_id, "costs", window, cooldown_seconds: 0)
assert.(job.id == duplicate.id, "durable manual job deduplication")
{:ok, _} = Jobs.claim(job.id)

:ok = Ecto.Adapters.SQL.disconnect_all(Repo, 0)

assert.(
  Repo.query!("SELECT 1").rows == [[1]] and Store.records("costs", connection_id) == expected,
  "PostgreSQL pool disconnect and reconnect preserves snapshot"
)

:ok = Application.stop(:cloud_monitor)
Application.put_env(:cloud_monitor, :scheduler_enabled, true)
{:ok, _} = Application.ensure_all_started(:cloud_monitor)
# Recovery happens synchronously at scheduler initialization, before its first tick.
recovered = Repo.get!(Job, job.id)

assert.(
  recovered.state == "queued" and recovered.attempts == 1,
  "application restart recovers interrupted durable job"
)

assert.(
  Store.connection(connection_id)["displayName"] == "Offline fixture smoke only" and
    Store.records("costs", connection_id) == expected and budget in Store.budgets(),
  "application restart retains configuration, snapshot and local budget"
)

# Freeze the recovered queue for inspection; never dispatch a provider.
:sys.replace_state(CloudMonitor.Scheduler, &%{&1 | enabled: false})
response = request.(:get, "/sync-jobs/" <> job.id, "", true)

assert.(
  response.status == 200 and response.body["data"]["state"] == "queued",
  "localhost HTTP exposes recovered job"
)

{:ok, claimed} = Jobs.claim(job.id)
{:error, "unconfigured"} = Jobs.fail(claimed, "unconfigured", nil)

assert.(
  Repo.get!(Job, job.id).state == "failed" and Store.records("costs", connection_id) == expected,
  "missing real configuration preserves prior snapshot"
)

response = request.(:get, "/connections/#{connection_id}/costs", "", true)

assert.(
  response.status == 200 and response.body["data"] == expected,
  "localhost HTTP remains available after restart"
)

IO.puts("OFFLINE ONLY: snapshot #{snapshot.id}; no cloud authorization was attempted")
:ok = Application.stop(:cloud_monitor)
