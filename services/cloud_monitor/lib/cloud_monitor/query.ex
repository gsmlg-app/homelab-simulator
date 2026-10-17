defmodule CloudMonitor.Query do
  alias CloudMonitor.Domain
  @filters ~w(start end service region project search basis cursor limit)
  def parse(params) do
    query = Map.take(params, @filters)

    limit =
      case query["limit"] do
        nil ->
          {:ok, 50}

        n when is_integer(n) ->
          {:ok, n}

        n when is_binary(n) ->
          case Integer.parse(n) do
            {v, ""} -> {:ok, v}
            _ -> :error
          end

        _ ->
          :error
      end

    with {:ok, limit} <- limit,
         true <- limit in 1..100,
         {:ok, window} <- parse_window(query),
         true <-
           Enum.all?(Map.drop(query, ~w(limit)), fn {_, v} ->
             is_binary(v) and byte_size(v) <= 2048
           end) do
      {:ok, Map.merge(query, window) |> Map.put("limit", limit)}
    else
      _ -> {:error, "invalidQuery"}
    end
  end

  defp parse_window(%{"start" => start, "end" => finish}) do
    with {:ok, start} <- Domain.timestamp(start),
         {:ok, finish} <- Domain.timestamp(finish),
         true <- Domain.valid_window?(start, finish) do
      {:ok, %{"start" => DateTime.to_iso8601(start), "end" => DateTime.to_iso8601(finish)}}
    else
      _ -> {:error, "invalidQuery"}
    end
  end

  defp parse_window(query) do
    if Map.has_key?(query, "start") or Map.has_key?(query, "end"),
      do: {:error, "invalidQuery"},
      else: {:ok, %{}}
  end

  def filter(records, query) do
    Enum.filter(records, fn row ->
      Enum.all?(~w(service region basis), fn key ->
        query[key] == nil or row[key] == query[key]
      end) and
        (query["project"] == nil or row["project"] == query["project"] or
           row["billingScopeId"] == query["project"]) and
        (query["search"] == nil or
           String.contains?(
             String.downcase((row["name"] || "") <> " " <> row["id"]),
             String.downcase(query["search"])
           )) and in_window?(row, query)
    end)
  end

  defp in_window?(%{"start" => start, "end" => finish}, %{"start" => qs, "end" => qe}) do
    {:ok, start} = Domain.timestamp(start)
    {:ok, finish} = Domain.timestamp(finish)
    {:ok, qs} = Domain.timestamp(qs)
    {:ok, qe} = Domain.timestamp(qe)
    DateTime.compare(start, qs) != :lt and DateTime.compare(finish, qe) != :gt
  end

  defp in_window?(_, _), do: true

  def envelope(data, revision, query \\ %{}, next_cursor \\ nil),
    do: %{
      "schemaVersion" => 1,
      "revision" => revision,
      "query" => query,
      "data" => data,
      "nextCursor" => next_cursor
    }

  def page(records, query, identity, revision) do
    hash =
      :crypto.hash(
        :sha256,
        :erlang.term_to_binary({identity, query |> Map.delete("cursor") |> Enum.sort()})
      )
      |> Base.url_encode64(padding: false)

    with {:ok, offset} <- offset(query["cursor"], revision, hash) do
      filtered = filter(records, query)
      items = Enum.slice(filtered, offset, query["limit"])
      next_offset = offset + length(items)

      next =
        if next_offset < length(filtered),
          do:
            Phoenix.Token.sign(CloudMonitorWeb.Endpoint, "cloud-page", %{
              revision: revision,
              hash: hash,
              offset: next_offset
            }),
          else: nil

      {:ok,
       %{
         "schemaVersion" => 1,
         "revision" => revision,
         "query" => query,
         "data" => items,
         "nextCursor" => next
       }}
    end
  end

  defp offset(nil, _, _), do: {:ok, 0}

  defp offset(token, revision, hash) do
    case Phoenix.Token.verify(CloudMonitorWeb.Endpoint, "cloud-page", token, max_age: 3600) do
      {:ok, %{revision: ^revision, hash: ^hash, offset: n}} when is_integer(n) and n >= 0 ->
        {:ok, n}

      {:ok, %{revision: other}} when other != revision ->
        {:error, "revisionExpired"}

      _ ->
        {:error, "invalidCursor"}
    end
  end
end
