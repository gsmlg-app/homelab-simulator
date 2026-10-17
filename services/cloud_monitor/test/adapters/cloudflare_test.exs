defmodule CloudMonitor.Adapters.CloudflareTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.Adapters.Cloudflare
  alias CloudMonitor.Domain

  defmodule HTTP do
    def request(method, url, headers, body, opts),
      do: Keyword.fetch!(opts, :handler).(method, URI.parse(url), headers, body)
  end

  @window %{start: ~U[2026-10-01 00:00:00Z], end: ~U[2026-10-17 00:00:00Z]}
  @now ~U[2026-10-17 12:00:00Z]
  @moduletag :tmp_dir
  setup %{tmp_dir: dir} do
    path = Path.join(dir, "token")
    File.write!(path, "explicit-test-token\n")

    connection = %{
      "id" => "cf",
      "provider" => "cloudflare",
      "billingScopeId" => "cf-account",
      "credentialRef" => "file:" <> path,
      "settings" => %{"accountId" => "account"}
    }

    %{connection: connection}
  end

  defp response(result, extra \\ %{}),
    do:
      {:ok,
       %{
         status: 200,
         headers: [],
         body: Map.merge(%{"success" => true, "result" => result}, extra)
       }}

  defp info,
    do: %{
      "covered" => true,
      "subscriptions" => [
        %{
          "id" => "sub",
          "billing_cycle_anchor_timestamp" => "2026-09-15T00:00:00Z",
          "start_timestamp" => "2026-01-15T00:00:00Z"
        }
      ]
    }

  defp cost(overrides \\ %{}) do
    Map.merge(
      %{
        "BillingCurrency" => "USD",
        "ServiceName" => "Unknown new service",
        "ChargePeriodStart" => "2026-10-01T00:00:00Z",
        "ChargePeriodEnd" => "2026-10-02T00:00:00Z",
        "BillingPeriodStart" => "2026-09-15T00:00:00Z",
        "ContractedCost" => 1.25,
        "CumulatedContractedCost" => 9.5,
        "SubscriptionId" => "sub",
        "ChargeCategory" => "Usage"
      },
      overrides
    )
  end

  defp opts(handler, extra \\ []),
    do: Keyword.merge([http: HTTP, handler: handler, now: @now], extra)

  test "real GET billing path includes anchor and preserves separate period/cumulative costs", %{
    connection: c
  } do
    handler = fn :get, uri, headers, _ ->
      assert {"authorization", "Bearer explicit-test-token"} in headers

      case uri.path do
        "/client/v4/accounts/account/billable-usage/info" ->
          response(info())

        "/client/v4/accounts/account/billable-usage" ->
          assert %{"from" => "2026-09-15", "to" => "2026-10-17"} = URI.decode_query(uri.query)
          response([cost()])
      end
    end

    assert {:ok, %{records: records, status: status}} =
             Cloudflare.collect(c, "costs", @window, opts(handler))

    assert [
             %{"amount" => "1.25", "view" => "period"} = period,
             %{"amount" => "9.5", "view" => "cumulative"} = cumulative
           ] = records

    assert period["service"] == "Unknown new service"
    assert cumulative["start"] == "2026-09-15T00:00:00Z"
    assert period["resourceId"] == nil
    assert status["state"] == "partial"
    assert status["complete"] == false
    assert status["sourceAsOf"] == nil
    assert status["reason"] =~ "fixedSubscriptionsUncovered"
    assert {:ok, ^period} = Domain.normalize(period, "costs")
    assert {:ok, ^cumulative} = Domain.normalize(cumulative, "costs")
  end

  test "billing adjustments replace stable identities and unsupported services are retained", %{
    connection: c
  } do
    fetch = fn amount ->
      handler = fn :get, uri, _, _ ->
        if String.ends_with?(uri.path, "/info"),
          do: response(info()),
          else: response([cost(%{"ContractedCost" => amount})])
      end

      Cloudflare.collect(c, "costs", @window, opts(handler))
    end

    assert {:ok, %{records: [before | _]}} = fetch.("123456789.123456789")
    assert {:ok, %{records: [after_adjustment | _]}} = fetch.("-2.25")
    assert before["id"] == after_adjustment["id"]
    assert before["amount"] == "123456789.123456789"
    assert after_adjustment["amount"] == "-2.25"
  end

  test "billing emptiness, absent prices and unsupported coverage never claim zero", %{
    connection: c
  } do
    for {result, state} <- [
          {[], "waiting"},
          {[Map.delete(cost(), "ContractedCost")], "unsupported"}
        ] do
      handler = fn :get, uri, _, _ ->
        if String.ends_with?(uri.path, "/info"), do: response(info()), else: response(result)
      end

      assert {:error, ^state, nil} =
               Cloudflare.collect(c, "costs", @window, opts(handler))
    end

    assert {:error, "unsupported", nil} =
             Cloudflare.collect(
               c,
               "costs",
               @window,
               opts(fn _, _, _, _ -> response(%{"covered" => false, "subscriptions" => []}) end)
             )
  end

  test "invalid credentials or scopes make no requests", %{connection: c} do
    handler = fn _, _, _, _ -> flunk("unexpected HTTP call") end

    assert {:error, "unconfigured", nil} =
             Cloudflare.collect(Map.put(c, "credentialRef", nil), "costs", @window, opts(handler))

    assert {:error, "invalidConfiguration", nil} =
             Cloudflare.collect(
               put_in(c, ["settings", "accountId"], ""),
               "resources",
               @window,
               opts(handler)
             )

    assert {:error, "invalidQuery", nil} =
             Cloudflare.collect(c, "costs", %{@window | end: @window.start}, opts(handler))
  end

  test "authentication, permission, rate limit and server failures are sanitized", %{
    connection: c
  } do
    for {code, expected} <- [
          {401, "authenticationFailed"},
          {403, "permissionDenied"},
          {429, "rateLimited"},
          {503, "failed"}
        ] do
      handler = fn _, _, _, _ ->
        {:ok,
         %{
           status: code,
           headers: [{"Retry-After", "17"}],
           body: %{"errors" => [%{"message" => "secret upstream detail"}]}
         }}
      end

      assert {:error, ^expected, retry} = Cloudflare.collect(c, "costs", @window, opts(handler))
      assert retry == if(code == 429 or code == 503, do: 17, else: nil)
    end
  end

  defp inventory_handler(method, uri, _, _) do
    assert method == :get
    q = URI.decode_query(uri.query || "")

    case uri.path do
      "/client/v4/zones" ->
        assert q["account.id"] == "account"
        page = q["page"] || "1"

        response(
          [
            %{
              "id" => "zone" <> page,
              "name" => "example" <> page <> ".test",
              "status" => "active",
              "account" => %{"id" => "account"}
            }
          ],
          %{"result_info" => %{"page" => String.to_integer(page), "total_pages" => 2}}
        )

      "/client/v4/accounts/account/workers/scripts" ->
        response([%{"id" => "worker", "tags" => ["production"]}])

      "/client/v4/accounts/account/r2/buckets" ->
        if q["cursor"] == "next",
          do:
            response(%{"buckets" => [%{"name" => "archive"}]}, %{
              "result_info" => %{"cursor" => ""}
            }),
          else:
            response(%{"buckets" => [%{"name" => "images"}]}, %{
              "result_info" => %{"cursor" => "next"}
            })
    end
  end

  test "complete account-scoped inventories paginate zones and R2 and preserve stable IDs", %{
    connection: c
  } do
    assert {:ok, %{records: records, status: %{"state" => "available", "complete" => true}}} =
             Cloudflare.collect(c, "resources", @window, opts(&inventory_handler/4))

    assert Enum.map(records, & &1["type"]) == ["zone", "zone", "worker", "r2Bucket", "r2Bucket"]

    assert Enum.map(records, & &1["id"]) == [
             "cloudflare:account:zone:zone1",
             "cloudflare:account:zone:zone2",
             "cloudflare:account:worker:worker",
             "cloudflare:account:r2:default:images",
             "cloudflare:account:r2:default:archive"
           ]

    for record <- records, do: assert({:ok, ^record} = Domain.normalize(record, "resources"))
  end

  test "inventory failures or caps return no partial snapshot", %{connection: c} do
    handler = fn method, uri, headers, body ->
      if uri.path == "/client/v4/zones" and URI.decode_query(uri.query)["page"] == "2",
        do: {:ok, %{status: 403, headers: [], body: %{}}},
        else: inventory_handler(method, uri, headers, body)
    end

    assert {:error, "permissionDenied", nil} =
             Cloudflare.collect(c, "resources", @window, opts(handler))

    assert {:error, "requestBudgetExceeded", nil} =
             Cloudflare.collect(
               c,
               "resources",
               @window,
               opts(&inventory_handler/4, request_budget: 1)
             )

    assert {:error, "resourceLimitExceeded", nil} =
             Cloudflare.collect(
               c,
               "resources",
               @window,
               opts(&inventory_handler/4, max_resources: 1)
             )
  end

  test "R2 pagination cycles are rejected", %{connection: c} do
    handler = fn _, uri, _, _ ->
      cond do
        uri.path == "/client/v4/zones" ->
          response([], %{"result_info" => %{"page" => 1, "total_pages" => 1}})

        String.ends_with?(uri.path, "/scripts") ->
          response([])

        true ->
          response(%{"buckets" => []}, %{"result_info" => %{"cursor" => "same"}})
      end
    end

    assert {:error, "paginationCycle", nil} =
             Cloudflare.collect(c, "resources", @window, opts(handler))
  end

  test "known empty inventory differs from unknown billing emptiness", %{connection: c} do
    handler = fn _, uri, _, _ ->
      if String.ends_with?(uri.path, "/buckets"),
        do: response(%{"buckets" => []}),
        else: response([])
    end

    assert {:ok, %{records: [], status: %{"state" => "empty", "complete" => true}}} =
             Cloudflare.collect(c, "resources", @window, opts(handler))
  end

  test "configured Workers and R2 metrics use real GraphQL with units and native storage time", %{
    connection: c
  } do
    c = put_in(c, ["settings", "metrics"], %{"workers" => ["worker"], "r2Buckets" => ["images"]})
    window = %{start: ~U[2026-10-16 00:00:00Z], end: ~U[2026-10-17 00:00:00Z]}

    handler = fn :post, uri, _, body ->
      assert uri.path == "/client/v4/graphql"
      assert body["variables"]["accountTag"] == "account"
      assert body["query"] =~ "datetime_leq: \"2026-10-16T23:59:59.999999Z\""

      {dataset, data} =
        cond do
          body["query"] =~ "workersInvocationsAdaptive" ->
            {"workersInvocationsAdaptive", [%{"sum" => %{"requests" => 17, "errors" => 2}}]}

          body["query"] =~ "r2OperationsAdaptiveGroups" ->
            {"r2OperationsAdaptiveGroups", [%{"sum" => %{"requests" => 30}}]}

          body["query"] =~ "r2StorageAdaptiveGroups" ->
            assert body["query"] =~ "datetime_DESC"

            {"r2StorageAdaptiveGroups",
             [
               %{
                 "max" => %{"payloadSize" => 1234, "metadataSize" => 100},
                 "dimensions" => %{"datetime" => "2026-10-16T04:00:00Z"}
               }
             ]}
        end

      {:ok,
       %{
         status: 200,
         headers: [],
         body: %{"data" => %{"viewer" => %{"accounts" => [%{dataset => data}]}}, "errors" => nil}
       }}
    end

    assert {:ok, %{records: records, status: %{"state" => "partial", "sourceAsOf" => nil}}} =
             Cloudflare.collect(c, "usage", window, opts(handler))

    assert [
             %{"metric" => "requests", "unit" => "count", "value" => "17"},
             %{"metric" => "errors", "unit" => "count", "value" => "2"},
             %{"metric" => "operations", "unit" => "count", "value" => "30"},
             %{
               "metric" => "storedBytes",
               "unit" => "bytes",
               "value" => "1234",
               "aggregation" => "maximum",
               "start" => "2026-10-16T04:00:00Z"
             },
             %{"metric" => "metadataBytes", "unit" => "bytes", "value" => "100"}
           ] = records

    for record <- records, do: assert({:ok, ^record} = Domain.normalize(record, "usage"))
  end

  test "GraphQL partial data with errors is not published and unconfigured metrics make no calls",
       %{connection: c} do
    assert {:error, "unconfigured", nil} =
             Cloudflare.collect(
               c,
               "usage",
               @window,
               opts(fn _, _, _, _ -> flunk("metrics are opt-in") end)
             )

    c = put_in(c, ["settings", "metrics"], %{"workers" => ["worker"]})

    handler = fn _, _, _, _ ->
      {:ok,
       %{
         status: 200,
         headers: [],
         body: %{"data" => %{}, "errors" => [%{"message" => "not authorized"}]}
       }}
    end

    assert {:error, "permissionDenied", nil} =
             Cloudflare.collect(c, "usage", @window, opts(handler))
  end

  test "missing anchors wait, explicit operator anchors work without the info capability", %{
    connection: c
  } do
    handler = fn :get, uri, _, _ ->
      if String.ends_with?(uri.path, "/info") do
        {:ok, %{status: 403, headers: [], body: %{}}}
      else
        assert URI.decode_query(uri.query)["from"] == "2026-09-15"
        response([cost()])
      end
    end

    c = put_in(c, ["settings", "billingAnchors"], ["2026-09-15T00:00:00Z"])
    assert {:ok, %{records: [_, _]}} = Cloudflare.collect(c, "costs", @window, opts(handler))
    c = update_in(c, ["settings"], &Map.delete(&1, "billingAnchors"))

    assert {:error, "waiting", nil} =
             Cloudflare.collect(
               c,
               "costs",
               @window,
               opts(fn _, _, _, _ -> response(%{"covered" => true, "subscriptions" => []}) end)
             )
  end

  test "configured Zone counters use a zone query and configured empty metrics preserve prior samples",
       %{connection: c} do
    c = put_in(c, ["settings", "metrics"], %{"zones" => ["zone1"]})

    handler = fn :post, _, _, body ->
      assert body["query"] =~ "httpRequests1hGroups"
      assert body["query"] =~ "zoneTag: $name"

      {:ok,
       %{
         status: 200,
         headers: [],
         body: %{
           "data" => %{
             "viewer" => %{
               "zones" => [%{"httpRequests1hGroups" => [%{"sum" => %{"requests" => 12}}]}]
             }
           }
         }
       }}
    end

    assert {:ok,
            %{
              records: [%{"value" => "12", "source" => "cloudflare:graphql:httpRequests1hGroups"}]
            }} = Cloudflare.collect(c, "usage", @window, opts(handler))

    empty = fn _, _, _, _ ->
      {:ok,
       %{
         status: 200,
         headers: [],
         body: %{"data" => %{"viewer" => %{"zones" => [%{"httpRequests1hGroups" => []}]}}}
       }}
    end

    assert {:error, "waiting", nil} = Cloudflare.collect(c, "usage", @window, opts(empty))
  end

  test "malformed metric configuration and unidentifiable inventory are rejected", %{
    connection: c
  } do
    for metrics <- ["all", %{"workers" => "not-a-list"}, %{"r2Buckets" => [nil]}] do
      assert {:error, "invalidConfiguration", nil} =
               Cloudflare.collect(
                 put_in(c, ["settings", "metrics"], metrics),
                 "usage",
                 @window,
                 opts(fn _, _, _, _ -> flunk("invalid config") end)
               )
    end

    handler = fn _, _, _, _ ->
      response([%{"name" => "example.test", "account" => %{"id" => "account"}}])
    end

    assert {:error, "invalidData", nil} =
             Cloudflare.collect(c, "resources", @window, opts(handler))
  end

  test "normalized record limit applies to period plus cumulative rows", %{connection: c} do
    handler = fn _, uri, _, _ ->
      if String.ends_with?(uri.path, "/info"), do: response(info()), else: response([cost()])
    end

    assert {:error, "resourceLimitExceeded", nil} =
             Cloudflare.collect(c, "costs", @window, opts(handler, max_records: 1))
  end
end
