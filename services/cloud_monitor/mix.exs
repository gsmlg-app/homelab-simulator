defmodule CloudMonitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :cloud_monitor,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application,
    do: [
      mod: {CloudMonitor.Application, []},
      extra_applications: [:logger, :crypto, :inets, :ssl, :xmerl]
    ]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8.1"},
      {:bandit, "~> 1.8"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:decimal, "~> 3.2"},
      {:aws_signature, "~> 0.4.3"}
    ]
  end

  defp aliases,
    do: [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
end
