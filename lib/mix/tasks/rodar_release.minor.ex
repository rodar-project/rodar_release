defmodule Mix.Tasks.RodarRelease.Minor do
  @shortdoc "Bump the minor version and release"

  @moduledoc """
  Bumps the minor version and creates a release.

      mix rodar_release.minor              # 1.0.8 -> 1.1.0
      mix rodar_release.minor --dry-run    # preview changes
      mix rodar_release.minor --publish    # release + publish to Hex

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--publish` - publish to Hex after tagging
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Tasks.RodarRelease.Bump.run(:minor, args)
  end
end
