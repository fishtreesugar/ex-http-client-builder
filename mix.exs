defmodule HttpClientBuilder.MixProject do
  use Mix.Project

  def project do
    [
      app: :http_client_builder,
      version: "1.0.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.9"},
      # for encode plug compat query string
      {:plug, "~> 1.12"},
      {:jason, "~> 1.2", only: [:test]}
    ]
  end
end
