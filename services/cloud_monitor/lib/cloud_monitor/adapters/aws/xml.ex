defmodule CloudMonitor.Adapters.AWS.XML do
  @moduledoc false
  require Record

  Record.defrecordp(
    :element,
    :xmlElement,
    Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  )

  Record.defrecordp(
    :text_node,
    :xmlText,
    Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  )

  def parse(xml) when is_binary(xml) and byte_size(xml) <= 10_000_000 do
    if String.contains?(String.upcase(xml), ["<!DOCTYPE", "<!ENTITY"]) do
      {:error, "invalidData"}
    else
      try do
        {doc, rest} = :xmerl_scan.string(String.to_charlist(xml), quiet: true, validation: false)
        if String.trim(to_string(rest)) == "", do: {:ok, doc}, else: {:error, "invalidData"}
      rescue
        _ -> {:error, "invalidData"}
      catch
        _, _ -> {:error, "invalidData"}
      end
    end
  end

  def parse(_), do: {:error, "invalidData"}
  def name(node), do: node |> element(:name) |> to_string() |> String.split(":") |> List.last()

  def children(nil, _), do: []

  def children(node, name) do
    for child <- element(node, :content),
        is_tuple(child),
        elem(child, 0) == :xmlElement,
        child |> element(:name) |> to_string() |> String.split(":") |> List.last() == name,
        do: child
  end

  def path(node, []), do: node
  def path(node, [name | rest]), do: path(List.first(children(node, name)), rest)
  def value(nil), do: nil

  def value(node) do
    for(
      child <- element(node, :content),
      is_tuple(child),
      elem(child, 0) == :xmlText,
      into: "",
      do: to_string(text_node(child, :value))
    )
    |> String.trim()
  end

  def value(node, path), do: node |> path(path) |> value()
end
