defmodule Mix.Tasks.Relex.Rollback do
  @shortdoc "Undo the last release"

  @moduledoc """
  Undoes the last release by deleting its tag and resetting the release commit.

      mix relex.rollback           # soft reset (keep changes staged)
      mix relex.rollback --hard    # discard all release changes
      mix relex.rollback --dry-run # preview rollback

  Requires the latest commit to be a release commit (`release: vX.Y.Z`).

  ## Modes

    * **Soft (default)** - resets the commit and restores `mix.exs` and `CHANGELOG.md`
      to the pre-release state.
    * **Hard (`--hard`)** - discards all release changes entirely.

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--hard`    - discard release changes entirely
  """

  use Mix.Task

  import Relex.Helpers

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [dry_run: :boolean, hard: :boolean])
    dry_run = Keyword.get(opts, :dry_run, false)
    hard = Keyword.get(opts, :hard, false)

    {release_version, commit_msg} = get_release_commit!()
    tag = "v#{release_version}"

    Mix.shell().info("Rollback plan:")
    Mix.shell().info("  Release to rollback: #{tag}")

    Mix.shell().info(
      "  Reset mode:          #{if hard, do: "hard (discard changes)", else: "soft (keep changes staged)"}"
    )

    Mix.shell().info("")

    if dry_run do
      Mix.shell().info("[dry-run] Would delete tag #{tag}")
      Mix.shell().info("[dry-run] Would reset commit: #{commit_msg}")

      if hard do
        Mix.shell().info("[dry-run] Would discard all release changes")
      else
        Mix.shell().info("[dry-run] Would keep release changes staged")
      end
    else
      step("Deleting tag #{tag}", fn ->
        git!(["tag", "-d", tag])
      end)

      reset_mode = if hard, do: "--hard", else: "--soft"

      step("Resetting release commit (#{reset_mode})", fn ->
        git!(["reset", reset_mode, "HEAD~1"])
      end)

      if hard do
        Mix.shell().info("")
        Mix.shell().info("Rollback complete! Release #{tag} has been fully undone.")
      else
        step("Restoring mix.exs and CHANGELOG.md from pre-release state", fn ->
          git!(["checkout", "HEAD", "--", "mix.exs", "CHANGELOG.md"])
        end)

        Mix.shell().info("")
        Mix.shell().info("Rollback complete! Release #{tag} has been undone.")
        Mix.shell().info("The working tree is clean and back to the pre-release state.")
      end
    end
  end
end
