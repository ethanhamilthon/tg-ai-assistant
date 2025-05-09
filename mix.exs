defmodule Exas.MixProject do
  use Mix.Project

  def project do
    [
      app: :exas,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Exas.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dotenv_parser, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:openai, "~> 0.6.2"},
      {:telegex, "~> 1.9.0-rc.0"},
      {:exqlite, "~> 0.27"},
      {:nanoid, "~> 2.0"}

      # {:ecto_sql, "~> 3.11"},
      # {:ecto_sqlite3, "~> 0.13.0"}
      # {:nadia, "~> 0.7.0"}
    ]
  end
end
