defmodule Mix.Tasks.RodarRelease.Amend do
  @shortdoc "Fold changes into the last release commit"

  @moduledoc """
  Amends the last release commit with any current changes and re-tags.

      mix rodar_release.amend              # fold changes into release commit
      mix rodar_release.amend --dry-run    # preview amend

  Useful for fixing a typo or adding a missing file right after releasing.

  Requires the latest commit to be a release commit (`release: vX.Y.Z`)
  and the working tree to have uncommitted changes.

  ## Options

    * `--dry-run` - show what would happen without making any changes
  """

  use Mix.Task

  import RodarRelease.Helpers

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [dry_run: :boolean])
    dry_run = Keyword.get(opts, :dry_run, false)

    {release_version, commit_msg} = get_release_commit!()
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
end
