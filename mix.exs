defmodule Relex.MixProject do
  use Mix.Project

  def project do
    [
      app: :relex,
      version: "1.6.0",
      elixir: "~> 1.16"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
