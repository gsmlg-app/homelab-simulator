defmodule CloudMonitor.Adapter do
  @moduledoc "Read-only provider boundary. Return records only after every page has succeeded."
  @callback collect(map(), String.t(), %{start: DateTime.t(), end: DateTime.t()}, keyword()) ::
              {:ok, %{records: [map()], status: map()}}
              | {:error, String.t(), non_neg_integer() | nil}
end

defmodule CloudMonitor.Credentials do
  @moduledoc "Reads only the exact operator-configured reference. Never persisted or logged."
  def read("env:" <> name) do
    case System.get_env(name) do
      nil -> {:error, "unconfigured"}
      "" -> {:error, "unconfigured"}
      value -> {:ok, value}
    end
  end

  def read("file:" <> path) do
    with true <- Path.type(path) == :absolute,
         {:ok, %{size: size}} when size <= 65_536 <- File.stat(path),
         {:ok, value} <- File.read(path) do
      {:ok, String.trim(value)}
    else
      _ -> {:error, "unconfigured"}
    end
  end

  def read(_), do: {:error, "unconfigured"}
end
