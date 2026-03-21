defmodule Mix.Tasks.RodarRelease do
  @shortdoc "Release management for Rodar projects"

  @moduledoc """
  Release management for Rodar projects.

  ## Available tasks

      mix rodar_release.patch      - bump the patch version and release
      mix rodar_release.minor      - bump the minor version and release
      mix rodar_release.major      - bump the major version and release
      mix rodar_release.publish    - publish the current version to Hex
      mix rodar_release.rollback   - undo the last release
      mix rodar_release.amend      - fold changes into the last release commit

  Run `mix help rodar_release.<command>` for details on each command.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info(@moduledoc)
  end
end
