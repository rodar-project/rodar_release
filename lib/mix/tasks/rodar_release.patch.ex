defmodule Mix.Tasks.RodarRelease.Patch do
  @shortdoc "Bump the patch version and release"

  @moduledoc """
  Bumps the patch version and creates a release.

      mix rodar_release.patch              # 1.0.8 -> 1.0.9
      mix rodar_release.patch --dry-run    # preview changes
      mix rodar_release.patch --publish    # release + publish to Hex

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--publish` - publish to Hex after tagging
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Tasks.RodarRelease.Bump.run(:patch, args)
  end
end
