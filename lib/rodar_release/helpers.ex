defmodule RodarRelease.Helpers do
  @moduledoc false

  @mix_file "mix.exs"
  @changelog_file "CHANGELOG.md"
  @release_commit_pattern ~r/^release: v(\d+\.\d+\.\d+)$/

  def mix_file, do: @mix_file
  def changelog_file, do: @changelog_file

  def get_release_commit! do
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

  def validate_clean_working_tree! do
    {output, 0} = System.cmd("git", ["status", "--porcelain"])

    unless output == "" do
      Mix.raise(
        "Working directory is not clean. " <>
          "Please commit or stash your changes before releasing."
      )
    end
  end

  def update_changelog(version, date) do
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

  def mix!(args) do
    case System.cmd("mix", args, stderr_to_stdout: true) do
      {output, 0} ->
        output

      {output, code} ->
        Mix.raise("mix #{Enum.join(args, " ")} failed (exit #{code}):\n#{output}")
    end
  end

  def git!(args) do
    case System.cmd("git", args, stderr_to_stdout: true) do
      {output, 0} ->
        output

      {output, code} ->
        Mix.raise("git #{Enum.join(args, " ")} failed (exit #{code}):\n#{output}")
    end
  end

  def step(description, fun) do
    Mix.shell().info("=> #{description}")
    fun.()
  end
end
