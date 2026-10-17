defmodule CloudMonitor.Adapters.CloudflareLiveTest do
  use ExUnit.Case, async: false
  @moduletag :cloudflare_live
  unless System.get_env("CLOUD_MONITOR_CF_LIVE") == "1" do
    @moduletag skip: "opt-in real account validation: CLOUD_MONITOR_CF_LIVE=1"
  end

  setup_all do
    # Only these explicit identities/references are read; no discovery/default credentials.
    account = System.fetch_env!("CLOUD_MONITOR_CF_ACCOUNT_ID")
    reference = System.fetch_env!("CLOUD_MONITOR_CF_CREDENTIAL_REF")
    {:ok, start, _} = DateTime.from_iso8601(System.fetch_env!("CLOUD_MONITOR_CF_START"))
    {:ok, finish, _} = DateTime.from_iso8601(System.fetch_env!("CLOUD_MONITOR_CF_END"))
    names = fn key -> System.get_env(key, "") |> String.split(",", trim: true) end

    settings = %{
      "accountId" => account,
      "billingAnchors" => names.("CLOUD_MONITOR_CF_BILLING_ANCHORS"),
      "metrics" => %{
        "workers" => names.("CLOUD_MONITOR_CF_WORKERS"),
        "r2Buckets" => names.("CLOUD_MONITOR_CF_R2_BUCKETS"),
        "zones" => names.("CLOUD_MONITOR_CF_ZONES")
      }
    }

    %{
      connection: %{
        "id" => "cf-live",
        "provider" => "cloudflare",
        "billingScopeId" => "cf-live-account",
        "credentialRef" => reference,
        "settings" => settings
      },
      window: %{start: start, end: finish}
    }
  end

  for dataset <- ~w(costs resources usage) do
    @tag dataset: dataset
    test "real configured #{dataset} source returns usable data", %{
      connection: c,
      window: window,
      dataset: dataset
    } do
      case CloudMonitor.Adapters.Cloudflare.collect(c, dataset, window,
             request_budget: 20,
             max_pages: 10,
             max_resources: 100
           ) do
        {:ok, %{records: records, status: %{"state" => state}}} ->
          assert state in ~w(available partial empty)

          if dataset != "resources",
            do: refute(records == [], "source returned no evidence for #{dataset}")

          IO.puts(
            "Cloudflare live #{dataset}: #{length(records)} records; state=#{state}; fixed subscription costs remain uncovered"
          )

        {:error, code, _retry} ->
          flunk("Cloudflare live #{dataset} did not verify: #{code}")
      end
    end
  end
end
