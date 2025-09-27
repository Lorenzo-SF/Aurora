defmodule Aurora.MixProject do
  use Mix.Project

  def project do
    [
      app: :aurora,
      version: "1.0.4",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs"],
      description: description(),
      package: package(),
      source_url: "https://github.com/lorenzo-sf/aurora",
      homepage_url: "https://hex.pm/packages/aurora",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.3", only: :dev},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:propcheck, "~> 1.4", only: :test},
      {:credo, "~> 1.7.11", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:jason, "~> 1.4"}
    ]
  end

  defp description do
    """
    Aurora ofrece herramientas para formateo de textos en terminal, incluyendo
    colores, alineación y la capacidad de procesar textos en bloques o por trozos.
    Ideal para crear interfaces CLI/TUI limpias y dinámicas.
    """
  end

  defp package do
    [
      name: "aurora",
      licenses: ["Apache-2.0"],
      maintainers: ["Lorenzo Sánchez Fraile"],
      links: %{
        "GitHub" => "https://github.com/lorenzo-sf/aurora",
        "Docs" => "https://hexdocs.pm/aurora"
      },
      files: ~w(lib mix.exs README.md LICENSE .dialyzer_ignore.exs)
    ]
  end

  defp aliases do
    [
      quality: [
        "deps.get",
        "clean",
        "compile --warnings-as-errors",
        "cmd MIX_ENV=test mix test",
        "credo --strict",
        "dialyzer"
      ],
      ci: [
        "deps.get",
        "clean",
        "compile --warnings-as-errors",
        "cmd MIX_ENV=test mix test",
        "credo --strict"
      ]
    ]
  end
end
