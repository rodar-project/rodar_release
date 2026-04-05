defmodule Mix.Tasks.Relex do
  @shortdoc "Release management for Elixir projects"

  @moduledoc """
  Release management for Elixir projects.

  ## Available tasks

      mix relex.patch      - bump the patch version and release
      mix relex.minor      - bump the minor version and release
      mix relex.major      - bump the major version and release
      mix relex.merge      - promote a pre-release version after merging
      mix relex.rollback   - undo the last release
      mix relex.amend      - fold changes into the last release commit
      mix relex.install    - set up relex (via Igniter)

  Run `mix help relex.<command>` for details on each command.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info(@moduledoc)
  end
end
