defmodule Aurora.MixProject do
  use Mix.Project

  def project do
    [
      app: :aurora,
      version: "1.0.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      {:credo, "~> 1.7.11", only: [:dev, :test], runtime: false},
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
      files: ~w(lib c_src priv mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
