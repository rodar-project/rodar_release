defmodule Mix.Tasks.RodarRelease.Minor do
  @shortdoc "Bump the minor version and release"

  @moduledoc """
  Bumps the minor version and creates a release.

  Use when adding new features or deprecating existing functionality in a backward-compatible way.

      mix rodar_release.minor              # 1.0.8 -> 1.1.0
      mix rodar_release.minor --pre rc     # 1.0.8 -> 1.1.0-rc.1
      mix rodar_release.minor --dry-run    # preview changes

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--pre LABEL` - create a pre-release version with the given label (e.g., rc, beta, dev)
    * `--no-tag` - skip creating a git tag for the release
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Tasks.RodarRelease.Bump.run(:minor, args)
  end
end
