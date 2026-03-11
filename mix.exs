defmodule RodarRelease.MixProject do
  use Mix.Project

  def project do
    [
      app: :rodar_release,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Version management and release utilities for Rodar projects"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
