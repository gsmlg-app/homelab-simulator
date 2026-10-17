# Read-only live probe. Never run as an implicit fallback or as part of mix test.
unless System.get_env("CLOUD_MONITOR_AWS_LIVE") == "1" do
  IO.puts(:stderr, "AWS live smoke disabled; set CLOUD_MONITOR_AWS_LIVE=1 explicitly.")
  System.halt(2)
end

path = System.fetch_env!("CLOUD_MONITOR_AWS_LIVE_CONFIG")
config = path |> File.read!() |> JSON.decode!()
connection = Map.fetch!(config, "connection")
datasets = Map.get(config, "datasets", ["costs", "resources", "usage"])

if datasets == [] or not Enum.all?(datasets, &(&1 in ~w(costs resources usage))),
  do: raise("Invalid datasets")

for app <- [:aws_signature, :inets, :ssl, :xmerl], do: Application.ensure_all_started(app)
today = Date.utc_today()
finish = Map.get(config, "end", Date.to_iso8601(today) <> "T00:00:00Z")
start = Map.get(config, "start", Date.to_iso8601(Date.add(today, -3)) <> "T00:00:00Z")
{:ok, start, _} = DateTime.from_iso8601(start)
{:ok, finish, _} = DateTime.from_iso8601(finish)
window = %{start: start, end: finish}

opts = [
  request_budget: min(Map.get(config, "requestBudget", 20), 100),
  max_pages: 20,
  max_resources: Map.get(config, "maxResources", 1000)
]

failed =
  Enum.reduce(datasets, false, fn dataset, failed ->
    case CloudMonitor.Adapters.AWS.collect(connection, dataset, window, opts) do
      {:ok, %{records: rows, status: status}} ->
        IO.puts(
          "AWS #{dataset}: #{length(rows)} records; state=#{status["state"]}; complete=#{status["complete"]}; source watermark unknown"
        )

        failed

      {:error, code, _} ->
        IO.puts(:stderr, "AWS #{dataset}: #{code}")
        true
    end
  end)

if failed, do: System.halt(1)
