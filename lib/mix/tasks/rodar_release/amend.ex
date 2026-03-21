defmodule Mix.Tasks.RodarRelease.Amend do
  @shortdoc "Amends the last release commit and re-tags it"

  @moduledoc """
  Amends the last release commit with any staged or unstaged changes, then
  moves the release tag to point at the amended commit.

  ## Usage

      mix rodar_release.amend

  This is useful when you notice a small mistake right after releasing (e.g.,
  a typo in docs, a missing file) and want to fold the fix into the release
  commit rather than creating a separate commit.

  ## What it does

    1. Verifies the latest commit is a release commit (`release: vX.Y.Z`)
    2. Stages all current changes (`git add -A`)
    3. Amends the release commit (keeps the original message)
    4. Deletes and re-creates the annotated tag on the amended commit

  ## Options

    * `--dry-run` - show what would happen without making any changes
  """

  use Mix.Task

  @release_commit_pattern ~r/^release: v(\d+\.\d+\.\d+)$/

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [dry_run: :boolean])
    dry_run = Keyword.get(opts, :dry_run, false)

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

    {status_output, 0} = System.cmd("git", ["status", "--porcelain"])

    if String.trim(status_output) == "" do
      Mix.raise("No changes to amend. The working tree is clean.")
    end

    Mix.shell().info("Amend plan:")
    Mix.shell().info("  Release commit: #{commit_msg}")
    Mix.shell().info("  Tag:            #{tag}")
    Mix.shell().info("")
    Mix.shell().info("Changes to fold in:")
    Mix.shell().info(String.trim(status_output))
    Mix.shell().info("")

    if dry_run do
      Mix.shell().info("[dry-run] Would stage all changes")
      Mix.shell().info("[dry-run] Would amend commit: #{commit_msg}")
      Mix.shell().info("[dry-run] Would re-tag #{tag} on amended commit")
    else
      step("Staging all changes", fn ->
        git!(["add", "-A"])
      end)

      step("Amending release commit", fn ->
        git!(["commit", "--amend", "--no-edit"])
      end)

      step("Re-tagging #{tag}", fn ->
        git!(["tag", "-d", tag])
        git!(["tag", "-a", tag, "-m", "Release #{tag}"])
      end)

      Mix.shell().info("")
      Mix.shell().info("Release #{tag} amended successfully!")
      Mix.shell().info("")
      Mix.shell().info("If you had already pushed, you will need to force-push:")
      Mix.shell().info("  git push origin main --force-with-lease --tags")
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
