defmodule Mix.Tasks.RodarRelease.Publish do
  @shortdoc "Publish the current version to Hex"

  @moduledoc """
  Publishes the current version to Hex.

      mix rodar_release.publish            # publish current version
      mix rodar_release.publish --dry-run  # preview publish

  Useful when you've already bumped and tagged a release but deferred publishing.

  ## Options

    * `--dry-run` - show what would happen without making any changes
  """

  use Mix.Task

  import RodarRelease.Helpers

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [dry_run: :boolean])
    dry_run = Keyword.get(opts, :dry_run, false)
    current_version = RodarRelease.read_version()

    Mix.shell().info("Publish plan:")
    Mix.shell().info("  Version: #{current_version}")
    Mix.shell().info("")

    if dry_run do
      Mix.shell().info("[dry-run] Would publish v#{current_version} to Hex")
    else
      step("Publishing v#{current_version} to Hex", fn ->
        mix!(["hex.publish", "--yes"])
      end)

      Mix.shell().info("")
      Mix.shell().info("Published v#{current_version} to Hex!")
    end
  end
end
