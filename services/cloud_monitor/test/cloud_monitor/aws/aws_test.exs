defmodule CloudMonitor.Adapters.AWSTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.Adapters.AWS
  @moduletag :tmp_dir
  @window %{start: ~U[2026-10-01 00:00:00Z], end: ~U[2026-10-03 00:00:00Z]}
  setup %{tmp_dir: dir} do
    file = Path.join(dir, "explicit-test-credential.json")

    File.write!(
      file,
      JSON.encode!(%{
        "accessKeyId" => "AKIDEXAMPLE",
        "secretAccessKey" => "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
        "sessionToken" => "fixture-session"
      })
    )

    connection = %{
      "id" => "aws-test",
      "provider" => "aws",
      "billingScopeId" => "billing",
      "credentialRef" => "file:" <> file,
      "settings" => %{
        "accountId" => "123456789012",
        "linkedAccountIds" => ["123456789012"],
        "regions" => ["us-east-1"]
      }
    }

    {:ok, connection: connection}
  end

  defp sts,
    do:
      "<GetCallerIdentityResponse><GetCallerIdentityResult><Account>123456789012</Account><Arn>arn:aws:iam::123456789012:role/test</Arn></GetCallerIdentityResult></GetCallerIdentityResponse>"

  defp ok(body), do: {:ok, %{status: 200, headers: [], body: body}}

  defp page(amount, token \\ nil) do
    %{
      "ResultsByTime" => [
        %{
          "TimePeriod" => %{"Start" => "2026-10-01", "End" => "2026-10-02"},
          "Estimated" => true,
          "Groups" => [
            %{
              "Keys" => ["An unknown AWS service", "123456789012"],
              "Metrics" => %{"UnblendedCost" => %{"Amount" => amount, "Unit" => "USD"}}
            }
          ]
        }
      ],
      "NextPageToken" => token
    }
  end

  test "actual signed CE request has exact scope two groups and preserves service adjustments", %{
    connection: c
  } do
    owner = self()

    http = fn method, url, headers, body, opts ->
      send(owner, {:request, method, url, headers, body, opts})
      if String.contains?(url, "sts."), do: ok(sts()), else: ok(page("-1.250000001"))
    end

    assert {:ok, %{records: [row], status: status}} =
             AWS.collect(c, "costs", @window, http: http, now: ~U[2026-10-17 12:00:00Z])

    assert row["amount"] == "-1.250000001"
    assert row["service"] == "An unknown AWS service"
    assert row["basis"] == "UnblendedCost"
    assert row["resourceId"] == nil
    assert row["estimated"] == true
    assert row["category"] == "unknown"
    assert status["sourceAsOf"] == nil
    assert status["complete"] == false
    assert_receive {:request, :post, _, _, _, _}
    assert_receive {:request, :post, "https://ce.us-east-1.amazonaws.com/", headers, body, _}
    request = JSON.decode!(body)
    assert request["Granularity"] == "DAILY"
    assert request["Metrics"] == ["UnblendedCost"]

    assert request["GroupBy"] == [
             %{"Type" => "DIMENSION", "Key" => "SERVICE"},
             %{"Type" => "DIMENSION", "Key" => "LINKED_ACCOUNT"}
           ]

    assert request["Filter"] == %{
             "Dimensions" => %{"Key" => "LINKED_ACCOUNT", "Values" => ["123456789012"]}
           }

    assert {"x-amz-security-token", "fixture-session"} in headers

    assert Enum.any?(headers, fn {k, v} ->
             String.downcase(k) == "authorization" and
               String.contains?(v, "/us-east-1/ce/aws4_request")
           end)
  end

  test "pagination all succeeds or returns no partial snapshot; costs request budget is shared",
       %{connection: c} do
    http = fn _, url, _, body, _ ->
      cond do
        String.contains?(url, "sts.") ->
          ok(sts())

        JSON.decode!(body)["NextPageToken"] == nil ->
          ok(page("0.1", "next"))

        true ->
          ok(%{
            "ResultsByTime" => [
              %{
                "TimePeriod" => %{"Start" => "2026-10-02", "End" => "2026-10-03"},
                "Estimated" => false,
                "Groups" => [
                  %{
                    "Keys" => ["EC2", "123456789012"],
                    "Metrics" => %{"UnblendedCost" => %{"Amount" => "0.2", "Unit" => "USD"}}
                  }
                ]
              }
            ]
          })
      end
    end

    assert {:ok, %{records: [_, _]}} = AWS.collect(c, "costs", @window, http: http)

    assert {:error, "requestBudgetExceeded", nil} =
             AWS.collect(c, "costs", @window, http: http, request_budget: 2)

    fail = fn method, url, headers, body, opts ->
      if not String.contains?(url, "sts.") and JSON.decode!(body)["NextPageToken"] == "next",
        do: {:ok, %{status: 403, headers: [], body: %{"__type" => "AccessDeniedException"}}},
        else: http.(method, url, headers, body, opts)
    end

    assert {:error, "permissionDenied", nil} = AWS.collect(c, "costs", @window, http: fail)
  end

  test "empty incomplete bill data is waiting and errors are classified without upstream secrets",
       %{connection: c} do
    for {code, expected} <- [
          {401, "authenticationFailed"},
          {403, "permissionDenied"},
          {429, "rateLimited"},
          {500, "failed"}
        ] do
      http = fn _, url, _, _, _ ->
        if String.contains?(url, "sts."),
          do: ok(sts()),
          else:
            {:ok,
             %{
               status: code,
               headers: [{"retry-after", "23"}],
               body: %{"message" => "never expose this secret"}
             }}
      end

      assert {:error, ^expected, retry} = AWS.collect(c, "costs", @window, http: http)
      assert retry == if(code == 429, do: 23, else: nil)
    end

    http = fn _, url, _, _, _ ->
      if String.contains?(url, "sts."), do: ok(sts()), else: ok(%{"ResultsByTime" => []})
    end

    assert {:error, "waiting", nil} =
             AWS.collect(c, "costs", @window, http: http)

    assert {:error, "unconfigured", nil} =
             AWS.collect(Map.delete(c, "credentialRef"), "costs", @window, [])
  end

  test "adjustments keep stable IDs and source flags; unrequested linked account is rejected", %{
    connection: c
  } do
    original = fn _, url, _, _, _ ->
      if String.contains?(url, "sts."), do: ok(sts()), else: ok(page("10.123456789"))
    end

    adjusted = fn _, url, _, _, _ ->
      if String.contains?(url, "sts."), do: ok(sts()), else: ok(page("-2.5"))
    end

    assert {:ok, %{records: [before]}} = AWS.collect(c, "costs", @window, http: original)
    assert {:ok, %{records: [after_row]}} = AWS.collect(c, "costs", @window, http: adjusted)
    assert before["id"] == after_row["id"]
    assert before["amount"] == "10.123456789"
    assert after_row["amount"] == "-2.5"
    assert after_row["estimated"] == true

    unexpected = fn _, url, _, _, _ ->
      if String.contains?(url, "sts.") do
        ok(sts())
      else
        [bucket] = page("1")["ResultsByTime"]
        [group] = bucket["Groups"]

        ok(%{
          "ResultsByTime" => [
            %{bucket | "Groups" => [%{group | "Keys" => ["EC2", "999999999999"]}]}
          ]
        })
      end
    end

    assert {:error, "invalidData", nil} = AWS.collect(c, "costs", @window, http: unexpected)
  end

  test "account identity mismatch and expired signed credentials are never silently accepted", %{
    connection: c
  } do
    mismatch = fn _, _, _, _, _ ->
      ok(
        "<GetCallerIdentityResponse><GetCallerIdentityResult><Account>999999999999</Account></GetCallerIdentityResult></GetCallerIdentityResponse>"
      )
    end

    assert {:error, "configurationError", nil} = AWS.collect(c, "costs", @window, http: mismatch)

    expired = fn _, _, _, _, _ ->
      {:ok,
       %{
         status: 403,
         headers: [],
         body:
           "<ErrorResponse><Error><Code>ExpiredToken</Code><Message>redacted</Message></Error></ErrorResponse>"
       }}
    end

    assert {:error, "authenticationFailed", nil} = AWS.collect(c, "costs", @window, http: expired)
  end
end
