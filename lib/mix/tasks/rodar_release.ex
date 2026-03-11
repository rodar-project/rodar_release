defmodule Mix.Tasks.RodarRelease do
  @shortdoc "Creates a release by bumping version in mix.exs, updating CHANGELOG, and tagging"

  @moduledoc """
  Creates a release by bumping the version in `mix.exs`, updating the CHANGELOG,
  committing, and tagging.

  ## Usage

      mix rodar_release <bump>

  where `<bump>` is one of `patch`, `minor`, or `major`.

  The version in `mix.exs` is the single source of truth (e.g., `version: "1.0.8"`).
  The bump type determines the release version:

    * `mix rodar_release patch` - releases 1.0.9
    * `mix rodar_release minor` - releases 1.1.0
    * `mix rodar_release major` - releases 2.0.0

  ## Options

    * `--dry-run` - show what would happen without making any changes
    * `--publish` - publish the package to Hex after tagging the release

  ## Prerequisites

  The git working directory must be clean (no uncommitted changes).
  """

  use Mix.Task

  @mix_file "mix.exs"
  @changelog_file "CHANGELOG.md"

  @impl Mix.Task
  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args, strict: [dry_run: :boolean, publish: :boolean])

    dry_run = Keyword.get(opts, :dry_run, false)
    publish = Keyword.get(opts, :publish, false)

    bump =
      case positional do
        [b] when b in ~w(patch minor major) ->
          String.to_atom(b)

        _ ->
          Mix.raise("Usage: mix rodar_release <patch|minor|major> [--dry-run] [--publish]")
      end

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
      dry_run_report(release_version, today, publish)
    else
      execute_release(release_version, today, publish)
    end
  end

  defp dry_run_report(release_version, today, publish) do
    Mix.shell().info("[dry-run] Would update mix.exs version to #{release_version}")
    Mix.shell().info("[dry-run] Would update CHANGELOG.md with release date #{today}")
    Mix.shell().info("[dry-run] Would commit: release: v#{release_version}")
    Mix.shell().info("[dry-run] Would tag: v#{release_version}")

    if publish do
      Mix.shell().info("[dry-run] Would publish to Hex")
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
