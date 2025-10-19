defmodule Aurora.MixProject do
  use Mix.Project

  def project do
    [
      app: :aurora,
      version: "1.0.6",
      elixir: "~> 1.18.4-otp-28",
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
        extras: ["README.md", "CHANGELOG.md", "LICENSE"],
        source_ref: "v1.0.4",
        source_url: "https://github.com/lorenzo-sf/aurora"
      ],
      escript: [main_module: Aurora.CLI]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      gen: [
        "escript.build",
        "deploy"
      ],
      deploy: fn _ ->
        dest_dir = Path.expand("~/.Ypsilon")
        File.mkdir_p!(dest_dir)
        File.cp!("aurora", Path.join(dest_dir, "aurora"))
        IO.puts("✅ Escript instalado en #{dest_dir}/aurora")
      end,
      credo: ["format --check-formatted", "credo --strict --format=oneline"],
      quality: [
        "deps.get",
        "credo",
        "compile --warnings-as-errors",
        "cmd 'echo \"✅ mix compile terminado\"'",
        "cmd MIX_ENV=test mix test",
        "cmd 'echo \"✅ mix test terminado\"'",
        "credo --strict",
        "cmd 'echo \"✅ mix credo terminado\"'",
        "dialyzer",
        "cmd 'echo \"✅ quality terminado\"'"
      ],
      hex_prepare: [
        "quality",
        "docs",
        "cmd mix hex.build"
      ],
      hex_publish: [
        "hex_prepare",
        "cmd mix hex.publish"
      ]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.3", only: :dev},
      {:changex, "~> 0.3.0"},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:propcheck, "~> 1.4", only: :test},
      {:credo, "~> 1.7.11", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.34", runtime: false},
      {:jason, "~> 1.4"}
    ]
  end

  def escript do
    [
      main_module: Aurora.CLI
    ]
  end

  defp description do
    """
    Aurora ofrece herramientas para formateo ANSI de textos en terminal, incluyendo
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
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE .dialyzer_ignore.exs)
    ]
  end
end
