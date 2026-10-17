defmodule CloudMonitor.Domain do
  @moduledoc "Pure exact cost selection, validation and budget evaluation."
  @cost ~w(id connectionId billingScopeId service resourceId start end currency amount basis category estimated source sourcePrecision invoiceMonth recordKind view coverage)
  @resource ~w(id connectionId billingScopeId service type region name tags observedAt state)
  @usage ~w(id resourceId service metric unit start end granularity aggregation value source)
  @states ~w(unconfigured waiting empty partial available stale permissionDenied authenticationFailed unsupported rateLimited failed)
  def states, do: @states

  def decimal(value) when is_binary(value) and byte_size(value) <= 256 do
    if Regex.match?(~r/^-?\d+(\.\d+)?$/, value),
      do: {:ok, Decimal.new(value)},
      else: {:error, "invalidData"}
  end

  def decimal(_), do: {:error, "invalidData"}
  def amount(value), do: value |> Decimal.normalize() |> Decimal.to_string(:normal)

  def timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, time, _} -> {:ok, time}
      _ -> {:error, "invalidQuery"}
    end
  end

  def timestamp(_), do: {:error, "invalidQuery"}

  @doc "Canonical UTC microsecond precision for Ecto and durable window identity."
  def persistence_time(%DateTime{} = time),
    do: time |> DateTime.to_unix(:microsecond) |> DateTime.from_unix!(:microsecond)

  def valid_window?(start, finish),
    do: DateTime.compare(start, finish) == :lt and DateTime.diff(finish, start) <= 93 * 86_400

  def normalize(record, dataset) when is_map(record) do
    fields =
      case dataset do
        "costs" -> @cost
        "resources" -> @resource
        "usage" -> @usage
      end

    required = fields -- ~w(resourceId estimated invoiceMonth state)
    string_fields = required -- ~w(coverage tags)
    valid = Enum.all?(string_fields, &(is_binary(record[&1]) and record[&1] != ""))
    valid = valid and Enum.all?(required, &Map.has_key?(record, &1))

    valid =
      valid and
        case dataset do
          "costs" ->
            match?({:ok, _}, decimal(record["amount"])) and record["recordKind"] == "reported" and
              record["view"] in ~w(period cumulative invoice detail) and
              record["category"] in ~w(usage subscription tax credit refund adjustment unknown) and
              is_list(record["coverage"]) and Enum.all?(record["coverage"], &is_binary/1) and
              record["estimated"] in [nil, true, false] and interval?(record)

          "resources" ->
            is_map(record["tags"]) and
              Enum.all?(record["tags"], fn {k, v} -> is_binary(k) and is_binary(v) end) and
              match?({:ok, _}, timestamp(record["observedAt"]))

          "usage" ->
            match?({:ok, _}, decimal(record["value"])) and interval?(record)
        end

    if valid, do: {:ok, Map.new(fields, &{&1, record[&1]})}, else: {:error, "invalidData"}
  end

  def normalize(_, _), do: {:error, "invalidData"}

  defp interval?(record) do
    with {:ok, start} <- timestamp(record["start"]), {:ok, finish} <- timestamp(record["end"]) do
      DateTime.compare(start, finish) == :lt
    else
      _ -> false
    end
  end

  def authoritative(records, scopes) do
    by_id = Map.new(scopes, &{&1["id"], &1})

    records =
      Enum.filter(records, fn r ->
        r["view"] == "period" and
          get_in(by_id, [r["billingScopeId"], "authoritativeConnectionId"]) == r["connectionId"]
      end)

    unique =
      Enum.reduce(records, %{}, fn r, acc ->
        key = {r["billingScopeId"], r["id"]}

        case acc[key] do
          nil -> Map.put(acc, key, r)
          ^r -> acc
          _ -> raise ArgumentError, "Conflicting records within one snapshot"
        end
      end)
      |> Map.values()

    occupied = MapSet.new(unique, &{&1["billingScopeId"], window_key(&1)})

    Enum.reject(unique, fn r ->
      parent_present?(
        get_in(by_id, [r["billingScopeId"], "parentId"]),
        window_key(r),
        by_id,
        occupied,
        MapSet.new([r["billingScopeId"]])
      )
    end)
  end

  defp parent_present?(nil, _, _, _, _), do: false

  defp parent_present?(id, key, scopes, occupied, seen) do
    if MapSet.member?(seen, id), do: raise(ArgumentError, "Billing scope hierarchy cycle")

    MapSet.member?(occupied, {id, key}) or
      parent_present?(
        get_in(scopes, [id, "parentId"]),
        key,
        scopes,
        occupied,
        MapSet.put(seen, id)
      )
  end

  defp window_key(r),
    do: {r["currency"], r["basis"], canonical_time(r["start"]), canonical_time(r["end"])}

  defp canonical_time(value) do
    {:ok, time} = timestamp(value)
    DateTime.to_unix(time, :microsecond)
  end

  def totals(records, scopes), do: records |> authoritative(scopes) |> sum_totals()

  defp sum_totals(records) do
    exact(fn ->
      records
      |> Enum.group_by(&window_key/1)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {_, [first | _] = rows} ->
        total = Enum.reduce(rows, Decimal.new(0), &Decimal.add(Decimal.new(&1["amount"]), &2))
        first |> Map.take(~w(currency basis start end)) |> Map.put("amount", amount(total))
      end)
    end)
  end

  @doc "Selects native scope coverage before lifting wholly-contained period buckets."
  def window_totals(records, scopes, start, finish) do
    qs = canonical_time(start)
    qe = canonical_time(finish)
    {selected, ambiguous} = query_authority(records, scopes)

    {contained, incompatible} =
      Enum.split_with(selected, fn row ->
        {_, _, rs, re} = window_key(row)
        rs >= qs and re <= qe and not MapSet.member?(ambiguous, scope_window(row))
      end)

    overlapping =
      Enum.filter(incompatible, fn row ->
        {_, _, rs, re} = window_key(row)
        rs < qe and re > qs
      end)

    lifted = Enum.map(contained, &Map.merge(&1, %{"start" => start, "end" => finish}))

    %{
      "totals" => sum_totals(lifted),
      "unmappedTotals" => sum_totals(overlapping),
      "coverage" =>
        if(Enum.any?(overlapping, &MapSet.member?(ambiguous, scope_window(&1))),
          do: ["ambiguousScopeOverlap"],
          else: []
        )
    }
  end

  defp query_authority(records, scopes) do
    scopes = Map.new(scopes, &{&1["id"], &1})
    rows = authoritative(records, Map.values(scopes))
    windows = scope_windows(rows)

    # A containing native parent is authoritative; never allocate its amount to days.
    selected =
      Enum.reject(rows, fn row ->
        {_, _, start, finish} = window_key(row)

        Enum.any?(ancestor_windows(row, scopes, windows), fn {_, {ps, pe}} ->
          ps <= start and pe >= finish
        end)
      end)

    windows = scope_windows(selected)

    ambiguous =
      Enum.reduce(selected, MapSet.new(), fn row, acc ->
        {_, _, start, finish} = window_key(row)

        Enum.reduce(ancestor_windows(row, scopes, windows), acc, fn {parent_key, {ps, pe}}, acc ->
          if ps < finish and pe > start,
            do: acc |> MapSet.put(scope_window(row)) |> MapSet.put(parent_key),
            else: acc
        end)
      end)

    {selected, ambiguous}
  end

  defp scope_window(row), do: {row["billingScopeId"], window_key(row)}

  defp scope_windows(rows) do
    rows
    |> Enum.map(&scope_window/1)
    |> Enum.uniq()
    |> Enum.group_by(fn {scope, {currency, basis, _, _}} -> {scope, currency, basis} end)
  end

  defp ancestor_windows(row, scopes, windows) do
    {currency, basis, _, _} = window_key(row)

    ancestor_ids(row["billingScopeId"], scopes, MapSet.new())
    |> Enum.flat_map(&Map.get(windows, {&1, currency, basis}, []))
    |> Enum.map(fn {_, {_, _, start, finish}} = key -> {key, {start, finish}} end)
  end

  defp ancestor_ids(id, scopes, seen) do
    if MapSet.member?(seen, id), do: raise(ArgumentError, "Billing scope hierarchy cycle")

    case get_in(scopes, [id, "parentId"]) do
      nil -> []
      parent -> [parent | ancestor_ids(parent, scopes, MapSet.put(seen, id))]
    end
  end

  def budget(rule, records, scopes, complete) do
    exact(fn ->
      target = Decimal.new(rule["amount"])

      rows =
        Enum.filter(records, &(&1["billingScopeId"] == rule["billingScopeId"]))
        |> authoritative(scopes)

      sum =
        rows
        |> Enum.filter(&within_budget?(&1, rule))
        |> Enum.reduce(Decimal.new(0), &Decimal.add(Decimal.new(&1["amount"]), &2))

      thresholds =
        Map.get(rule, "thresholds", ["0.8", "1"])
        |> Enum.map(&Decimal.new/1)
        |> Enum.sort(&(Decimal.compare(&1, &2) != :gt))

      state =
        cond do
          Decimal.equal?(target, 0) ->
            "disabled"

          Decimal.compare(sum, Decimal.mult(target, List.last(thresholds))) != :lt ->
            "exceeded"

          length(thresholds) > 1 and
              Decimal.compare(sum, Decimal.mult(target, hd(thresholds))) != :lt ->
            "warning"

          complete ->
            "withinBudget"

          true ->
            "unknown"
        end

      %{"state" => state, "knownAmount" => amount(sum), "complete" => complete}
    end)
  end

  defp within_budget?(row, rule) do
    {currency, basis, start, finish} = window_key(row)
    {rule_currency, rule_basis, rule_start, rule_finish} = window_key(rule)

    currency == rule_currency and basis == rule_basis and start >= rule_start and
      finish <= rule_finish
  end

  defp exact(fun), do: Decimal.Context.with(%{Decimal.Context.get() | precision: 1024}, fun)
end
