defmodule Mix.Tasks.RodarRelease.Patch do
  @shortdoc "Bump the patch version and release"

  @moduledoc """
  Bumps the patch version and creates a release.

  Use for backward-compatible bug fixes that don't add new functionality.

      mix rodar_release.patch              # 1.0.8 -> 1.0.9
      mix rodar_release.patch --pre rc     # 1.0.8 -> 1.0.9-rc.1
      mix rodar_release.patch              # 1.0.9-rc.1 -> 1.0.9 (promote)
      mix rodar_release.patch --dry-run    # preview changes

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--pre LABEL` - create a pre-release version with the given label (e.g., rc, beta, dev)
    * `--no-tag` - skip creating a git tag for the release
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Tasks.RodarRelease.Bump.run(:patch, args)
  end
end
