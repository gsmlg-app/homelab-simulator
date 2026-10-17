defmodule CloudMonitor.Adapters.GCP.Auth do
  @moduledoc "Exact configured credentials only; OAuth JWT signing uses OTP public_key RS256."
  alias CloudMonitor.Adapters.GCP.Transport
  @endpoint "https://oauth2.googleapis.com/token"
  def authenticate(raw, ctx) do
    case JSON.decode(raw) do
      {:ok, %{"type" => "access_token", "access_token" => token, "expires_at" => expires}}
      when is_binary(token) and token != "" ->
        with {:ok, time, _} <- DateTime.from_iso8601(expires),
             :gt <- DateTime.compare(time, ctx.now) do
          {:ok, %{ctx | token: token}}
        else
          _ -> {:error, "authenticationFailed", nil}
        end

      {:ok, %{"type" => "service_account"} = credential} ->
        exchange(credential, ctx)

      _ ->
        {:error, "invalidConfiguration", nil}
    end
  end

  defp exchange(credential, ctx) do
    with {:ok, assertion} <- assertion(credential, ctx.now),
         {:ok, result, ctx} <-
           Transport.request(
             ctx,
             :post,
             @endpoint,
             URI.encode_query(%{
               "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
               "assertion" => assertion
             }),
             %{},
             content_type: "application/x-www-form-urlencoded"
           ),
         token when is_binary(token) and token != "" <- result["access_token"],
         expires when is_integer(expires) and expires > 0 <- result["expires_in"] do
      {:ok, %{ctx | token: token}}
    else
      {:error, "invalidData", nil} -> {:error, "authenticationFailed", nil}
      {:error, _, _} = error -> error
      _ -> {:error, "authenticationFailed", nil}
    end
  end

  defp assertion(credential, now) do
    with email when is_binary(email) and email != "" <- credential["client_email"],
         true <- Map.get(credential, "token_uri", @endpoint) == @endpoint,
         pem when is_binary(pem) <- credential["private_key"],
         [entry] <- :public_key.pem_decode(pem) do
      key = :public_key.pem_entry_decode(entry)
      true = elem(key, 0) == :RSAPrivateKey
      header = %{"alg" => "RS256", "typ" => "JWT"}

      header =
        if is_binary(credential["private_key_id"]),
          do: Map.put(header, "kid", credential["private_key_id"]),
          else: header

      issued = DateTime.to_unix(now)

      claims = %{
        "iss" => email,
        "scope" => "https://www.googleapis.com/auth/cloud-platform",
        "aud" => @endpoint,
        "iat" => issued,
        "exp" => issued + 3600
      }

      signed = encode(header) <> "." <> encode(claims)

      {:ok,
       signed <> "." <> Base.url_encode64(:public_key.sign(signed, :sha256, key), padding: false)}
    else
      _ -> {:error, "invalidConfiguration", nil}
    end
  rescue
    _ -> {:error, "invalidConfiguration", nil}
  end

  defp encode(data), do: data |> JSON.encode!() |> Base.url_encode64(padding: false)
end
