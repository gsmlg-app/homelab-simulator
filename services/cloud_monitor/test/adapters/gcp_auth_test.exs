defmodule CloudMonitor.Adapters.GCP.AuthTest do
  use ExUnit.Case, async: true
  alias CloudMonitor.Adapters.GCP.Auth
  @now ~U[2026-10-17 12:00:00Z]
  defmodule HTTP do
    def request(method, url, headers, body, opts),
      do: Keyword.fetch!(opts, :handler).(method, url, headers, body, opts)
  end

  setup_all do
    private = :public_key.generate_key({:rsa, 2048, 65_537})
    pem = :public_key.pem_encode([:public_key.pem_entry_encode(:PrivateKeyInfo, private)])
    %{private: private, pem: pem, public: {:RSAPublicKey, elem(private, 2), elem(private, 3)}}
  end

  defp credential(pem),
    do: %{
      "type" => "service_account",
      "client_email" => "reader@example.iam.gserviceaccount.com",
      "private_key" => pem,
      "private_key_id" => "test-key",
      "token_uri" => "https://oauth2.googleapis.com/token"
    }

  defp ctx(handler),
    do: %{http: HTTP, opts: [handler: handler], now: @now, token: nil, remaining: 5}

  test "PKCS8 service account RS256 signature and exact OAuth exchange verify deterministically",
       %{pem: pem, public: public} do
    handler = fn :post, url, headers, body, opts ->
      assert url == "https://oauth2.googleapis.com/token"
      assert headers == []
      assert opts[:content_type] == "application/x-www-form-urlencoded"
      params = URI.decode_query(body)
      assert params["grant_type"] == "urn:ietf:params:oauth:grant-type:jwt-bearer"
      assertion = params["assertion"]
      [head, claims, signature] = String.split(assertion, ".")

      assert %{"alg" => "RS256", "kid" => "test-key"} =
               head |> Base.url_decode64!(padding: false) |> JSON.decode!()

      assert %{
               "iss" => "reader@example.iam.gserviceaccount.com",
               "aud" => "https://oauth2.googleapis.com/token",
               "iat" => 1_792_238_400,
               "exp" => 1_792_242_000
             } = claims |> Base.url_decode64!(padding: false) |> JSON.decode!()

      assert :public_key.verify(
               head <> "." <> claims,
               :sha256,
               Base.url_decode64!(signature, padding: false),
               public
             )

      send(self(), {:assertion, assertion})

      {:ok,
       %{
         status: 200,
         headers: [],
         body: %{"access_token" => "exchanged-token", "expires_in" => 3600}
       }}
    end

    raw = JSON.encode!(credential(pem))
    assert {:ok, %{token: "exchanged-token", remaining: 4}} = Auth.authenticate(raw, ctx(handler))
    assert_receive {:assertion, first}
    assert {:ok, %{token: "exchanged-token"}} = Auth.authenticate(raw, ctx(handler))
    assert_receive {:assertion, ^first}
    refute first =~ pem
  end

  test "expired tokens, bad keys and non-Google token endpoints cannot issue authenticated calls",
       %{pem: pem} do
    context = ctx(fn _, _, _, _, _ -> flunk("credential must be rejected locally") end)

    expired = %{
      "type" => "access_token",
      "access_token" => "expired",
      "expires_at" => "2026-10-17T11:59:59Z"
    }

    assert {:error, "authenticationFailed", nil} =
             Auth.authenticate(JSON.encode!(expired), context)

    assert {:error, "invalidConfiguration", nil} =
             Auth.authenticate(
               JSON.encode!(%{credential(pem) | "token_uri" => "https://example.invalid/token"}),
               context
             )

    assert {:error, "invalidConfiguration", nil} =
             Auth.authenticate(
               JSON.encode!(%{credential(pem) | "private_key" => "invalid"}),
               context
             )

    assert {:error, "invalidConfiguration", nil} = Auth.authenticate("not json", context)
  end

  test "OAuth invalid grant is authentication failure rather than a publishable result", %{
    pem: pem
  } do
    context =
      ctx(fn _, _, _, _, _ ->
        {:ok,
         %{
           status: 400,
           headers: [],
           body: %{
             "error" => "invalid_grant",
             "error_description" => "never expose upstream secrets"
           }
         }}
      end)

    assert {:error, "authenticationFailed", nil} =
             Auth.authenticate(JSON.encode!(credential(pem)), context)
  end
end
