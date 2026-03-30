defmodule Mix.Tasks.RodarRelease.Major do
  @shortdoc "Bump the major version and release"

  @moduledoc """
  Bumps the major version and creates a release.

  Use when introducing breaking changes that require consumers to update their code.

      mix rodar_release.major              # 1.0.8 -> 2.0.0
      mix rodar_release.major --pre rc     # 1.0.8 -> 2.0.0-rc.1
      mix rodar_release.major --dry-run    # preview changes

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--pre LABEL` - create a pre-release version with the given label (e.g., rc, beta, dev)
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Tasks.RodarRelease.Bump.run(:major, args)
  end
end
