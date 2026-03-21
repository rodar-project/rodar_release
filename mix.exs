defmodule RodarRelease.MixProject do
  use Mix.Project

  def project do
    [
      app: :rodar_release,
      version: "1.0.1",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Version management and release utilities for Rodar projects",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
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
    []
  end
end
