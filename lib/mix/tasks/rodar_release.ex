defmodule Mix.Tasks.RodarRelease do
  @shortdoc "Release management: bump, rollback, or amend releases"

  @moduledoc """
  Release management for Rodar projects.

  ## Usage

      mix rodar_release <command> [options]

  ## Commands

    * `patch`    - bump the patch version and release
    * `minor`    - bump the minor version and release
    * `major`    - bump the major version and release
    * `publish`  - publish the current version to Hex
    * `rollback` - undo the last release (delete tag, reset commit)
    * `amend`    - fold current changes into the last release commit and re-tag

  ## Examples

      mix rodar_release patch              # 1.0.8 -> 1.0.9
      mix rodar_release minor --dry-run    # preview minor bump
      mix rodar_release major --publish    # release + publish to Hex
      mix rodar_release publish            # publish current version to Hex
      mix rodar_release rollback           # undo last release (soft reset)
      mix rodar_release rollback --hard    # undo and discard changes
      mix rodar_release amend              # fold changes into release commit

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--publish` - publish to Hex after tagging (bump commands only)
    * `--hard`    - discard release changes entirely (rollback only)

  ## Prerequisites

  The git working directory must be clean for bump commands.
  """

  use Mix.Task

  @mix_file "mix.exs"
  @changelog_file "CHANGELOG.md"
  @release_commit_pattern ~r/^release: v(\d+\.\d+\.\d+)$/

  @impl Mix.Task
  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args, strict: [dry_run: :boolean, publish: :boolean, hard: :boolean])

    case positional do
      [cmd] when cmd in ~w(patch minor major) ->
        run_bump(String.to_atom(cmd), opts)

      ["publish"] ->
        run_publish(opts)

      ["rollback"] ->
        run_rollback(opts)

      ["amend"] ->
        run_amend(opts)

      _ ->
        Mix.raise(
          "Usage: mix rodar_release <patch|minor|major|publish|rollback|amend> [--dry-run] [--publish] [--hard]"
        )
    end
  end

  # --- Bump ---

  defp run_bump(bump, opts) do
    dry_run = Keyword.get(opts, :dry_run, false)
    publish = Keyword.get(opts, :publish, false)

    current_version = RodarRelease.read_version()

    unless dry_run do
      validate_clean_working_tree!()
    end

    release_version = RodarRelease.bump(current_version, bump)
    today = Date.utc_today() |> Date.to_iso8601()

    Mix.shell().info("Release plan:")
    Mix.shell().info("  Current version:  #{current_version}")
    Mix.shell().info("  Release version:  #{release_version}")
    Mix.shell().info("  Bump type:        #{bump}")
    Mix.shell().info("")

    if dry_run do
      Mix.shell().info("[dry-run] Would update mix.exs version to #{release_version}")
      Mix.shell().info("[dry-run] Would update CHANGELOG.md with release date #{today}")
      Mix.shell().info("[dry-run] Would commit: release: v#{release_version}")
      Mix.shell().info("[dry-run] Would tag: v#{release_version}")

      if publish do
        Mix.shell().info("[dry-run] Would publish to Hex")
      end
    else
      execute_release(release_version, today, publish)
    end
  end

  defp execute_release(release_version, today, publish) do
    step("Updating mix.exs version to #{release_version}", fn ->
      RodarRelease.write_version(release_version)
    end)

    step("Updating CHANGELOG.md with release date", fn ->
      update_changelog(release_version, today)
    end)

    step("Committing release v#{release_version}", fn ->
      git!(["add", @mix_file, @changelog_file])
      git!(["commit", "-m", "release: v#{release_version}"])
    end)

    step("Tagging v#{release_version}", fn ->
      git!(["tag", "-a", "v#{release_version}", "-m", "Release v#{release_version}"])
    end)

    if publish do
      step("Publishing v#{release_version} to Hex", fn ->
        mix!(["hex.publish", "--yes"])
      end)
    end

    Mix.shell().info("")
    Mix.shell().info("Release v#{release_version} complete!")
    Mix.shell().info("")
    Mix.shell().info("Next steps:")
    Mix.shell().info("  git push origin main --tags")
  end

  # --- Publish ---

  defp run_publish(opts) do
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

  # --- Rollback ---

  defp run_rollback(opts) do
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

  # --- Amend ---

  defp run_amend(opts) do
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

  # --- Helpers ---

  defp get_release_commit! do
    {commit_msg, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
    commit_msg = String.trim(commit_msg)

    case Regex.run(@release_commit_pattern, commit_msg) do
      [_, version] ->
        {version, commit_msg}

      nil ->
        Mix.raise(
          "Latest commit is not a release commit.\n" <>
            "Expected commit message matching \"release: vX.Y.Z\", got: #{inspect(commit_msg)}"
        )
    end
  end

  defp validate_clean_working_tree! do
    {output, 0} = System.cmd("git", ["status", "--porcelain"])

    unless output == "" do
      Mix.raise(
        "Working directory is not clean. " <>
          "Please commit or stash your changes before releasing."
      )
    end
  end

  defp update_changelog(version, date) do
    content = File.read!(@changelog_file)

    updated =
      String.replace(
        content,
        "## [Unreleased]",
        "## [Unreleased]\n\n## [#{version}] - #{date}",
        global: false
      )

    File.write!(@changelog_file, updated)
  end

  defp mix!(args) do
    case System.cmd("mix", args, stderr_to_stdout: true) do
      {output, 0} ->
        output

      {output, code} ->
        Mix.raise("mix #{Enum.join(args, " ")} failed (exit #{code}):\n#{output}")
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
