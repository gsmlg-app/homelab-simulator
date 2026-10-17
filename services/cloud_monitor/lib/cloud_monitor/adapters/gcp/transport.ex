defmodule CloudMonitor.Adapters.GCP.Transport do
  @moduledoc false
  def request(ctx, method, url, body \\ "", query \\ %{}, extra \\ [])

  def request(%{remaining: n}, _, _, _, _, _) when n <= 0,
    do: {:error, "requestBudgetExceeded", nil}

  def request(ctx, method, url, body, query, extra) do
    url = url <> if(map_size(query) == 0, do: "", else: "?" <> URI.encode_query(query))
    headers = if ctx.token, do: [{"authorization", "Bearer " <> ctx.token}], else: []

    case ctx.http.request(method, url, headers, body, Keyword.merge(ctx.opts, extra)) do
      {:ok, %{status: status, body: payload} = response} ->
        code =
          if is_map(payload) and is_map(payload["error"]),
            do: payload["error"]["code"] || status,
            else: status

        cond do
          code == 401 -> {:error, "authenticationFailed", nil}
          code == 403 -> {:error, "permissionDenied", nil}
          code == 404 -> {:error, "notFound", nil}
          code == 429 -> {:error, "rateLimited", retry(response[:headers] || [])}
          code >= 500 -> {:error, "failed", retry(response[:headers] || [])}
          code < 200 or code >= 300 -> {:error, "invalidData", nil}
          not is_map(payload) or Map.has_key?(payload, "error") -> {:error, "invalidData", nil}
          is_list(payload["errors"]) and payload["errors"] != [] -> {:error, "invalidData", nil}
          true -> {:ok, payload, %{ctx | remaining: ctx.remaining - 1}}
        end

      {:error, code} ->
        {:error, code, nil}
    end
  end

  defp retry(headers) do
    with {_, value} <-
           Enum.find(headers, fn {k, _} -> String.downcase(to_string(k)) == "retry-after" end),
         {n, ""} when n >= 0 <- Integer.parse(to_string(value)) do
      min(n, 86_400)
    else
      _ -> nil
    end
  end
end
