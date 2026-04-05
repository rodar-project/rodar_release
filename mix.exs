defmodule Relex.MixProject do
  use Mix.Project

  def project do
    [
      app: :relex,
      version: "1.6.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Relaxed release management for Elixir projects",
      package: package(),
      docs: docs(),
      source_url: "https://github.com/relex-project/relex",
      homepage_url: "https://github.com/relex-project/relex"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "Relex",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp package do
    [
      maintainers: ["Rodrigo Couto <r@rodg.co>"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/relex-project/relex"},
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:igniter, "~> 0.6", optional: true}
    ]
  end
end
