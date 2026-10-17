defmodule CloudMonitor.Adapters.GCPTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.Adapters.GCP
  alias CloudMonitor.Domain
  @moduletag :tmp_dir
  @window %{start: ~U[2026-10-01 00:00:00Z], end: ~U[2026-10-17 00:00:00Z]}
  @now ~U[2026-10-17 12:00:00Z]
  @columns ~w(project_id service sku_id start end currency invoice_month cost_type cost credits export_time)

  defmodule HTTP do
    def request(method, url, headers, body, opts),
      do: Keyword.fetch!(opts, :handler).(method, URI.parse(url), headers, body, opts)
  end

  setup %{tmp_dir: dir} do
    path = Path.join(dir, "explicit-credential")

    File.write!(
      path,
      JSON.encode!(%{
        "type" => "access_token",
        "access_token" => "explicit-token",
        "expires_at" => "2026-10-18T00:00:00Z"
      })
    )

    settings = %{
      "queryProject" => "query-project",
      "exportTable" => "billing-project.billing.export_table",
      "billingAccountId" => "ABCDEF-123456-ABCDEF",
      "projects" => ["resource-project"],
      "location" => "US",
      "cloudRunLocations" => ["us-central1"]
    }

    %{
      connection: %{
        "id" => "gcp",
        "provider" => "gcp",
        "billingScopeId" => "gcp-billing",
        "credentialRef" => "file:" <> path,
        "settings" => settings
      },
      credential_path: path
    }
  end

  defp ok(body), do: {:ok, %{status: 200, headers: [], body: body}}

  defp opts(handler, extra \\ []),
    do: Keyword.merge([http: HTTP, handler: handler, now: @now], extra)

  defp row(overrides \\ %{}) do
    values =
      Map.merge(
        %{
          "project_id" => "resource-project",
          "service" => "New Service",
          "sku_id" => "sku",
          "start" => "2026-10-01T00:00:00Z",
          "end" => "2026-10-02T00:00:00Z",
          "currency" => "USD",
          "invoice_month" => "202611",
          "cost_type" => "regular",
          "cost" => "100.123456789",
          "credits" => "-15.25",
          "export_time" => "2026-10-16T05:00:00Z"
        },
        overrides
      )

    %{"f" => Enum.map(@columns, &%{"v" => values[&1]})}
  end

  defp query_result(rows, extra \\ %{}) do
    Map.merge(
      %{
        "jobComplete" => true,
        "jobReference" => %{
          "projectId" => "query-project",
          "jobId" => "job_1",
          "location" => "US"
        },
        "schema" => %{"fields" => Enum.map(@columns, &%{"name" => &1, "type" => "STRING"})},
        "rows" => rows,
        "totalRows" => to_string(length(rows))
      },
      extra
    )
  end

  defp metadata, do: %{"timePartitioning" => %{"field" => "usage_start_time"}, "location" => "US"}

  test "BigQuery query is fixed, parameterized, byte bounded and credits preaggregate per source row",
       %{connection: c} do
    handler = fn method, uri, headers, body, _ ->
      assert {"authorization", "Bearer explicit-token"} in headers

      if method == :get do
        assert uri.path ==
                 "/bigquery/v2/projects/billing-project/datasets/billing/tables/export_table"

        ok(metadata())
      else
        assert uri.path == "/bigquery/v2/projects/query-project/queries"
        assert body["useLegacySql"] == false
        assert body["maximumBytesBilled"] == "1000000000"
        assert body["jobTimeoutMs"] == "60000"
        assert body["query"] =~ "FROM `billing-project.billing.export_table`"
        assert body["query"] =~ "FROM UNNEST(credits)"
        assert body["query"] =~ "SUM(CAST(credit.amount AS NUMERIC))"
        assert body["query"] =~ "SUM(base_cost)"
        assert body["query"] =~ "AS `start`"
        assert body["query"] =~ "AS `end`"
        refute body["query"] =~ ", UNNEST(credits)"
        params = Map.new(body["queryParameters"], &{&1["name"], &1["parameterValue"]})
        assert params["billingAccount"]["value"] == "ABCDEF-123456-ABCDEF"
        assert params["projects"]["arrayValues"] == [%{"value" => "resource-project"}]
        ok(query_result([row()]))
      end
    end

    assert {:ok, %{records: [base, credit], status: status}} =
             GCP.collect(c, "costs", @window, opts(handler))

    assert base["amount"] == "100.123456789"
    assert credit["amount"] == "-15.25"
    assert credit["category"] == "credit"
    assert base["invoiceMonth"] == "202611"
    assert base["service"] == "New Service"
    assert base["resourceId"] == nil
    assert base["sourcePrecision"] =~ "Float64"
    assert status["sourceAsOf"] == "2026-10-16T05:00:00Z"
    assert status["state"] == "partial" and not status["complete"]
    for r <- [base, credit], do: assert({:ok, ^r} = Domain.normalize(r, "costs"))

    assert Decimal.equal?(
             Decimal.add(Decimal.new(base["amount"]), Decimal.new(credit["amount"])),
             Decimal.new("84.873456789")
           )
  end

  test "BigQuery polling and page tokens retain full result and adjustment identities", %{
    connection: c
  } do
    handler = fn method, uri, _, _, _ ->
      cond do
        String.contains?(uri.path, "/tables/") ->
          ok(metadata())

        method == :post ->
          ok(%{
            "jobComplete" => false,
            "jobReference" => %{
              "projectId" => "query-project",
              "jobId" => "job_1",
              "location" => "US"
            }
          })

        URI.decode_query(uri.query || "")["pageToken"] == "next" ->
          ok(
            query_result(
              [
                row(%{
                  "service" => "Adjustment",
                  "cost_type" => "adjustment",
                  "cost" => "-2.5",
                  "credits" => "0"
                })
              ],
              %{"totalRows" => "2"}
            )
          )

        true ->
          ok(query_result([row()], %{"pageToken" => "next", "totalRows" => "2"}))
      end
    end

    assert {:ok, %{records: [_, _, adjustment]}} = GCP.collect(c, "costs", @window, opts(handler))
    assert adjustment["category"] == "adjustment" and adjustment["amount"] == "-2.5"
    a = row(%{"cost" => "9", "credits" => "0"})
    b = row(%{"cost" => "8", "credits" => "0"})

    collect = fn source ->
      GCP.collect(
        c,
        "costs",
        @window,
        opts(fn _, uri, _, _, _ ->
          if String.contains?(uri.path, "/tables/"),
            do: ok(metadata()),
            else: ok(query_result([source]))
        end)
      )
    end

    assert {:ok, %{records: [before]}} = collect.(a)
    assert {:ok, %{records: [after_adjustment]}} = collect.(b)
    assert before["id"] == after_adjustment["id"]
  end

  test "empty or missing export waits and late page failure publishes no partial costs", %{
    connection: c
  } do
    assert {:error, "waiting", nil} =
             GCP.collect(
               c,
               "costs",
               @window,
               opts(fn _, uri, _, _, _ ->
                 if String.contains?(uri.path, "/tables/"),
                   do: ok(metadata()),
                   else: ok(query_result([]))
               end)
             )

    assert {:error, "waiting", nil} =
             GCP.collect(
               c,
               "costs",
               @window,
               opts(fn _, _, _, _, _ -> {:ok, %{status: 404, headers: [], body: %{}}} end)
             )

    handler = fn method, uri, _, _, _ ->
      cond do
        String.contains?(uri.path, "/tables/") -> ok(metadata())
        method == :post -> ok(query_result([row()], %{"pageToken" => "next", "totalRows" => "2"}))
        true -> {:ok, %{status: 403, headers: [], body: %{}}}
      end
    end

    assert {:error, "permissionDenied", nil} = GCP.collect(c, "costs", @window, opts(handler))
  end

  test "query identifiers and allowed scope reject SQL injection before HTTP", %{connection: c} do
    for {key, value} <- [
          {"exportTable", "a.b.c`; DROP TABLE x;--"},
          {"queryProject", "x/../../"},
          {"projects", ["x\" OR TRUE"]},
          {"billingAccountId", "' OR TRUE"}
        ] do
      assert {:error, "invalidConfiguration", nil} =
               GCP.collect(
                 put_in(c, ["settings", key], value),
                 "costs",
                 @window,
                 opts(fn _, _, _, _, _ -> flunk("unsafe identifier") end)
               )
    end
  end

  test "ingestion partition scan includes late export time and does not cut at usage end", %{
    connection: c
  } do
    handler = fn method, _, _, body, _ ->
      if method == :get,
        do: ok(%{"timePartitioning" => %{}, "location" => "US"}),
        else:
          (
            assert body["query"] =~ "_PARTITIONTIME"
            assert body["query"] =~ "@asOf"
            ok(query_result([row()]))
          )
    end

    assert {:ok, _} = GCP.collect(c, "costs", @window, opts(handler))
  end

  test "HTTP errors, quota and finite BigQuery polling are explicit", %{connection: c} do
    for {status, code} <- [
          {401, "authenticationFailed"},
          {403, "permissionDenied"},
          {429, "rateLimited"}
        ] do
      assert {:error, ^code, retry} =
               GCP.collect(
                 c,
                 "costs",
                 @window,
                 opts(fn _, _, _, _, _ ->
                   {:ok, %{status: status, headers: [{"retry-after", "8"}], body: %{}}}
                 end)
               )

      assert retry == if(status == 429, do: 8, else: nil)
    end

    handler = fn _, uri, _, _, _ ->
      if String.contains?(uri.path, "/tables/"),
        do: ok(metadata()),
        else:
          ok(%{
            "jobComplete" => false,
            "jobReference" => %{
              "projectId" => "query-project",
              "jobId" => "job_1",
              "location" => "US"
            }
          })
    end

    assert {:error, "waiting", nil} =
             GCP.collect(c, "costs", @window, opts(handler, max_polls: 2))

    assert {:error, "requestBudgetExceeded", nil} =
             GCP.collect(c, "costs", @window, opts(handler, request_budget: 1))
  end

  defp inventory(method, uri, _, _, _) do
    assert method == :get

    cond do
      String.ends_with?(uri.path, "/aggregated/instances") ->
        ok(%{
          "items" => %{
            "zones/us-central1-a" => %{
              "instances" => [
                %{
                  "id" => "123",
                  "name" => "vm",
                  "zone" => "zones/us-central1-a",
                  "status" => "RUNNING",
                  "labels" => %{"team" => "ops"}
                }
              ]
            }
          }
        })

      String.ends_with?(uri.path, "/aggregated/disks") ->
        ok(%{"items" => %{}})

      uri.host == "storage.googleapis.com" ->
        ok(%{"items" => [%{"id" => "bucket", "name" => "bucket", "location" => "US"}]})

      uri.host == "run.googleapis.com" ->
        if URI.decode_query(uri.query || "")["pageToken"] == "second",
          do: ok(%{"services" => []}),
          else:
            ok(%{
              "services" => [
                %{
                  "name" => "projects/resource-project/locations/us-central1/services/app",
                  "uid" => "uid",
                  "labels" => %{}
                }
              ],
              "nextPageToken" => "second"
            })
    end
  end

  test "Compute, Storage and regional Run inventories complete every page with stable identity",
       %{connection: c} do
    assert {:ok, %{records: [vm, bucket, run], status: %{"complete" => true}}} =
             GCP.collect(c, "resources", @window, opts(&inventory/5))

    assert vm["id"] == "gcp:compute:resource-project:us-central1-a:123"
    assert bucket["id"] == "gcp:storage:resource-project:bucket"
    assert run["id"] == "gcp:projects/resource-project/locations/us-central1/services/app"
    for r <- [vm, bucket, run], do: assert({:ok, ^r} = Domain.normalize(r, "resources"))

    assert {:error, "resourceLimitExceeded", nil} =
             GCP.collect(c, "resources", @window, opts(&inventory/5, max_resources: 1))
  end

  test "known empty inventories publish empty but partial aggregated scopes fail", %{
    connection: c
  } do
    assert {:ok, %{records: [], status: %{"state" => "empty"}}} =
             GCP.collect(c, "resources", @window, opts(fn _, _, _, _, _ -> ok(%{}) end))

    assert {:error, "failed", nil} =
             GCP.collect(
               c,
               "resources",
               @window,
               opts(fn _, _, _, _, _ -> ok(%{"unreachables" => ["zone"]}) end)
             )
  end

  test "Monitoring validates descriptors and preserves CPU units and source sample intervals", %{
    connection: c
  } do
    metric = %{
      "project" => "resource-project",
      "kind" => "gceCpu",
      "instanceId" => "123",
      "zone" => "us-central1-a"
    }

    c = put_in(c, ["settings", "metrics"], [metric])

    handler = fn :get, uri, _, _, _ ->
      if String.contains?(uri.path, "/metricDescriptors/") do
        ok(%{
          "type" => "compute.googleapis.com/instance/cpu/utilization",
          "metricKind" => "GAUGE",
          "valueType" => "DOUBLE",
          "unit" => "10^2.%"
        })
      else
        q = URI.decode_query(uri.query)
        assert q["filter"] =~ "resource.labels.instance_id = \"123\""
        assert q["aggregation.perSeriesAligner"] == "ALIGN_MEAN"

        ok(%{
          "timeSeries" => [
            %{
              "resource" => %{
                "type" => "gce_instance",
                "labels" => %{
                  "project_id" => "resource-project",
                  "instance_id" => "123",
                  "zone" => "us-central1-a"
                }
              },
              "points" => [
                %{
                  "interval" => %{"endTime" => "2026-10-16T01:00:00Z"},
                  "value" => %{"doubleValue" => 0.25}
                }
              ]
            }
          ]
        })
      end
    end

    assert {:ok, %{records: [r], status: %{"state" => "partial"}}} =
             GCP.collect(c, "usage", @window, opts(handler))

    assert r["value"] == "0.25" and r["unit"] == "10^2.%"
    assert r["resourceId"] == "gcp:compute:resource-project:us-central1-a:123"
    assert r["aggregation"] == "mean"
    assert {:ok, ^r} = Domain.normalize(r, "usage")
  end

  test "unconfigured, unsafe metric filters and descriptor mismatches make no fabricated samples",
       %{connection: c} do
    assert {:error, "unconfigured", nil} =
             GCP.collect(c, "usage", @window, opts(fn _, _, _, _, _ -> flunk("not enabled") end))

    metric = %{
      "project" => "other-project",
      "kind" => "gceCpu",
      "instanceId" => "123",
      "zone" => "us-central1-a"
    }

    assert {:error, "invalidConfiguration", nil} =
             GCP.collect(
               put_in(c, ["settings", "metrics"], [metric]),
               "usage",
               @window,
               opts(fn _, _, _, _, _ -> flunk("outside allowed project") end)
             )

    metric = %{metric | "project" => "resource-project"}

    assert {:error, "unsupported", nil} =
             GCP.collect(
               put_in(c, ["settings", "metrics"], [metric]),
               "usage",
               @window,
               opts(fn _, _, _, _, _ -> ok(%{"unit" => "wrong"}) end)
             )
  end

  test "network, daily Storage capacity and Run request metrics retain correct units and intervals",
       %{connection: c} do
    scopes = [
      {%{
         "project" => "resource-project",
         "kind" => "gceNetworkReceived",
         "instanceId" => "123",
         "zone" => "us-central1-a"
       }, "compute.googleapis.com/instance/network/received_bytes_count", "DELTA", "By",
       "gce_instance", %{"instance_id" => "123", "zone" => "us-central1-a"}, "ALIGN_SUM", "300s"},
      {%{"project" => "resource-project", "kind" => "gcsStorage", "bucket" => "bucket"},
       "storage.googleapis.com/storage/total_bytes", "GAUGE", "By", "gcs_bucket",
       %{"bucket_name" => "bucket"}, "ALIGN_MAX", "86400s"},
      {%{
         "project" => "resource-project",
         "kind" => "cloudRunRequests",
         "service" => "app",
         "location" => "us-central1"
       }, "run.googleapis.com/request_count", "DELTA", "1", "cloud_run_revision",
       %{"service_name" => "app", "location" => "us-central1", "revision_name" => "app-1"},
       "ALIGN_SUM", "300s"}
    ]

    for {scope, type, kind, unit, resource_type, labels, aligner, period} <- scopes do
      handler = fn _, uri, _, _, _ ->
        if String.contains?(uri.path, "/metricDescriptors/") do
          ok(%{"type" => type, "metricKind" => kind, "valueType" => "INT64", "unit" => unit})
        else
          q = URI.decode_query(uri.query)
          assert q["aggregation.perSeriesAligner"] == aligner
          assert q["aggregation.alignmentPeriod"] == period

          interval =
            if kind == "GAUGE",
              do: %{"endTime" => "2026-10-16T00:00:00Z"},
              else: %{"startTime" => "2026-10-16T00:00:00Z", "endTime" => "2026-10-16T00:05:00Z"}

          ok(%{
            "timeSeries" => [
              %{
                "metric" => %{"type" => type},
                "resource" => %{
                  "type" => resource_type,
                  "labels" => Map.put(labels, "project_id", "resource-project")
                },
                "points" => [%{"interval" => interval, "value" => %{"int64Value" => "1024"}}]
              }
            ]
          })
        end
      end

      assert {:ok, %{records: [sample]}} =
               GCP.collect(
                 put_in(c, ["settings", "metrics"], [scope]),
                 "usage",
                 @window,
                 opts(handler)
               )

      assert sample["unit"] == unit and sample["value"] == "1024"
      assert sample["granularity"] == period
      assert {:ok, ^sample} = Domain.normalize(sample, "usage")
    end
  end

  test "BQ pagination cycles and foreign job identities cannot publish data", %{connection: c} do
    for mode <- [:cycle, :foreign] do
      handler = fn _, uri, _, _, _ ->
        if String.contains?(uri.path, "/tables/") do
          ok(metadata())
        else
          result = query_result([row()], %{"totalRows" => "2", "pageToken" => "again"})

          if mode == :foreign,
            do: ok(put_in(result, ["jobReference", "projectId"], "other-project")),
            else: ok(result)
        end
      end

      expected = if mode == :cycle, do: "paginationCycle", else: "invalidData"
      assert {:error, ^expected, nil} = GCP.collect(c, "costs", @window, opts(handler))
    end
  end

  test "Monitoring later-page errors return no partial samples", %{connection: c} do
    scope = %{
      "project" => "resource-project",
      "kind" => "gceCpu",
      "instanceId" => "123",
      "zone" => "us-central1-a"
    }

    handler = fn _, uri, _, _, _ ->
      cond do
        String.contains?(uri.path, "/metricDescriptors/") ->
          ok(%{
            "type" => "compute.googleapis.com/instance/cpu/utilization",
            "metricKind" => "GAUGE",
            "valueType" => "DOUBLE",
            "unit" => "10^2.%"
          })

        URI.decode_query(uri.query)["pageToken"] == "next" ->
          {:ok, %{status: 403, headers: [], body: %{}}}

        true ->
          ok(%{"timeSeries" => [], "nextPageToken" => "next"})
      end
    end

    assert {:error, "permissionDenied", nil} =
             GCP.collect(
               put_in(c, ["settings", "metrics"], [scope]),
               "usage",
               @window,
               opts(handler)
             )
  end

  test "billing-account unallocated taxes are retained without assigning a project or resource",
       %{connection: c} do
    handler = fn method, _, _, body, _ ->
      if method == :get do
        ok(metadata())
      else
        assert body["query"] =~ "project.id IS NULL"
        assert body["query"] =~ "COALESCE(project.id, '__billing_account_unallocated__')"

        ok(
          query_result([
            row(%{
              "project_id" => "__billing_account_unallocated__",
              "cost_type" => "tax",
              "cost" => "3.5",
              "credits" => "0"
            }),
            row(%{"cost_type" => "tax", "cost" => "3.5", "credits" => "0"})
          ])
        )
      end
    end

    assert {:ok, %{records: [tax, project_tax]}} = GCP.collect(c, "costs", @window, opts(handler))
    assert tax["category"] == "tax" and tax["resourceId"] == nil
    assert "billingAccountUnallocated" in tax["coverage"]
    assert "project=resource-project" in project_tax["coverage"]
    refute tax["id"] == project_tax["id"]

    aliases = Enum.map([tax, project_tax], &%{&1 | "connectionId" => "gcp-alias"})
    scopes = [%{"id" => c["billingScopeId"], "authoritativeConnectionId" => c["id"]}]
    authoritative = Domain.authoritative([tax, project_tax] ++ aliases, scopes)
    assert Enum.sort_by(authoritative, & &1["id"]) == Enum.sort_by([tax, project_tax], & &1["id"])
  end
end
