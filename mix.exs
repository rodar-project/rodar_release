defmodule RodarRelease.MixProject do
  use Mix.Project

  def project do
    [
      app: :rodar_release,
      version: "1.6.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Version management and release utilities for Rodar projects",
      package: package(),
      docs: docs(),
      source_url: "https://github.com/rodar-project/rodar_release",
      homepage_url: "https://github.com/rodar-project/rodar_release"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "RodarRelease",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp package do
    [
      maintainers: ["Rodrigo Couto <r@rodg.co>"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/rodar-project/rodar_release"},
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
