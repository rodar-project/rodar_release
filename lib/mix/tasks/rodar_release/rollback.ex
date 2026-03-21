defmodule Mix.Tasks.RodarRelease.Rollback do
  @shortdoc "Rolls back the last release by removing its tag and undoing the release commit"

  @moduledoc """
  Rolls back the last release by removing its tag and undoing the release commit.

  ## Usage

      mix rodar_release.rollback

  This will:

    1. Verify the latest commit is a release commit (message matches `release: vX.Y.Z`)
    2. Delete the corresponding git tag
    3. Reset the release commit (keeping changes staged via `git reset --soft HEAD~1`)
    4. Restore the previous version in `mix.exs`
    5. Restore the previous `CHANGELOG.md`

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--hard`   - discard the release changes entirely (`git reset --hard HEAD~1`)
  """

  use Mix.Task

  @release_commit_pattern ~r/^release: v(\d+\.\d+\.\d+)$/

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [dry_run: :boolean, hard: :boolean])

    dry_run = Keyword.get(opts, :dry_run, false)
    hard = Keyword.get(opts, :hard, false)

    {commit_msg, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
    commit_msg = String.trim(commit_msg)

    release_version =
      case Regex.run(@release_commit_pattern, commit_msg) do
        [_, version] ->
          version

        nil ->
          Mix.raise(
            "Latest commit is not a release commit.\n" <>
              "Expected commit message matching \"release: vX.Y.Z\", got: #{inspect(commit_msg)}"
          )
      end

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

  defp git!(args) do
    case System.cmd("git", args, stderr_to_stdout: true) do
      {output, 0} ->
        output

      {output, code} ->
        Mix.raise("git #{Enum.join(args, " ")} failed (exit #{code}):\n#{output}")
    end
  end

  defp step(description, fun) do
    Mix.shell().info("=> #{description}")
    fun.()
  end
end
