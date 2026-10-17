defmodule CloudMonitor.Adapters.GCPLiveTest do
  use ExUnit.Case, async: false
  @moduletag :gcp_live
  unless System.get_env("CLOUD_MONITOR_GCP_LIVE") == "1" do
    @moduletag skip: "opt-in real account validation: CLOUD_MONITOR_GCP_LIVE=1"
  end

  setup_all do
    # Read only this explicit configuration reference; never discover cloud credentials.
    reference = System.fetch_env!("CLOUD_MONITOR_GCP_CONFIG_REF")
    {:ok, raw} = CloudMonitor.Credentials.read(reference)
    {:ok, connection} = JSON.decode(raw)
    true = connection["provider"] == "gcp"
    {:ok, start, _} = DateTime.from_iso8601(System.fetch_env!("CLOUD_MONITOR_GCP_START"))
    {:ok, finish, _} = DateTime.from_iso8601(System.fetch_env!("CLOUD_MONITOR_GCP_END"))
    %{connection: connection, window: %{start: start, end: finish}}
  end

  for dataset <- ~w(costs resources usage) do
    @tag dataset: dataset
    test "real configured #{dataset} source returns usable data", %{
      connection: connection,
      window: window,
      dataset: dataset
    } do
      case CloudMonitor.Adapters.GCP.collect(connection, dataset, window,
             request_budget: 30,
             max_pages: 10,
             max_resources: 100
           ) do
        {:ok, %{records: records, status: %{"state" => state}}} ->
          assert state in ~w(available partial empty)

          if dataset != "resources",
            do: refute(records == [], "source returned no evidence for #{dataset}")

          IO.puts("GCP live #{dataset}: #{length(records)} records; state=#{state}")

        {:error, code, _retry} ->
          flunk("GCP live #{dataset} did not verify: #{code}")
      end
    end
  end
end
