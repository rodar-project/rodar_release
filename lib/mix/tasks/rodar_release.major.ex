defmodule Mix.Tasks.RodarRelease.Major do
  @shortdoc "Bump the major version and release"

  @moduledoc """
  Bumps the major version and creates a release.

      mix rodar_release.major              # 1.0.8 -> 2.0.0
      mix rodar_release.major --dry-run    # preview changes
      mix rodar_release.major --publish    # release + publish to Hex

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--publish` - publish to Hex after tagging
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Tasks.RodarRelease.Bump.run(:major, args)
  end
end
