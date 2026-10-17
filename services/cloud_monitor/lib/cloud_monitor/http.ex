defmodule CloudMonitor.HTTP do
  @moduledoc "Injectable finite HTTP boundary; no request/response logging or automatic retries."
  @callback request(atom(), String.t(), [{String.t(), String.t()}], term(), keyword()) ::
              {:ok, map()} | {:error, String.t()}
  def request(method, url, headers, body, opts \\ []) do
    uri = URI.parse(url)

    localhost =
      uri.host in ["localhost", "127.0.0.1", "::1"] and Keyword.get(opts, :allow_localhost, false)

    if uri.scheme == "https" or (uri.scheme == "http" and localhost) do
      headers = Enum.map(headers, fn {k, v} -> {String.to_charlist(k), String.to_charlist(v)} end)
      body = if is_binary(body), do: body, else: JSON.encode!(body)

      request =
        if method in [:get, :head, :delete],
          do: {String.to_charlist(url), headers},
          else:
            {String.to_charlist(url), headers,
             opts |> Keyword.get(:content_type, "application/json") |> String.to_charlist(), body}

      http_opts = [
        timeout: Keyword.get(opts, :timeout, 30_000),
        connect_timeout: 10_000,
        autoredirect: false,
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ]

      case :httpc.request(method, request, http_opts, body_format: :binary) do
        {:ok, {{_, status, _}, response_headers, payload}} ->
          if byte_size(payload) <= Keyword.get(opts, :max_body_bytes, 10_000_000) do
            decoded =
              if Keyword.get(opts, :response_format) == :raw,
                do: {:ok, payload},
                else: JSON.decode(payload)

            case decoded do
              {:ok, decoded} ->
                {:ok,
                 %{
                   status: status,
                   headers:
                     Enum.map(response_headers, fn {k, v} -> {to_string(k), to_string(v)} end),
                   body: decoded
                 }}

              _ ->
                {:error, "invalidData"}
            end
          else
            {:error, "responseTooLarge"}
          end

        {:error, _} ->
          {:error, "networkFailure"}
      end
    else
      {:error, "invalidConfiguration"}
    end
  end

  @doc "Bounded pagination; callbacks produce {:ok, records, next_token} or an error."
  def paginate(fetch_page, opts \\ []) do
    limit = min(Keyword.get(opts, :max_pages, 100), Keyword.get(opts, :request_budget, 100))
    do_pages(fetch_page, nil, limit, MapSet.new(), [], 0, Keyword.get(opts, :max_records, 10_000))
  end

  defp do_pages(_, _, 0, _, _, _, _), do: {:error, "requestBudgetExceeded", nil}

  defp do_pages(fetch, token, remaining, seen, pages, count, maximum) do
    if MapSet.member?(seen, token) do
      {:error, "paginationCycle", nil}
    else
      case fetch.(token) do
        {:ok, records, next} when is_list(records) ->
          total = count + length(records)

          cond do
            total > maximum ->
              {:error, "resourceLimitExceeded", nil}

            next == nil ->
              {:ok, pages |> Enum.reverse() |> List.flatten() |> Kernel.++(records)}

            true ->
              do_pages(
                fetch,
                next,
                remaining - 1,
                MapSet.put(seen, token),
                [records | pages],
                total,
                maximum
              )
          end

        {:error, code, retry_after} ->
          {:error, code, retry_after}
      end
    end
  end
end
