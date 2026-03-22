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

  def maybe_generate_changelog_entry do
    content = File.read!(@changelog_file)

    if unreleased_empty?(content) do
      Mix.shell().info("Changelog has no entries under [Unreleased].")

      case generate_changelog_entry() do
        {:ok, entry} ->
          Mix.shell().info("")
          Mix.shell().info("Suggested changelog entry:")
          Mix.shell().info("")
          Mix.shell().info(entry)
          Mix.shell().info("")

          if Mix.shell().yes?("Add this entry to the changelog?") do
            updated =
              String.replace(content, "## [Unreleased]", "## [Unreleased]\n\n#{entry}",
                global: false
              )

            File.write!(@changelog_file, updated)
            Mix.shell().info("Changelog updated.")
          end

        {:error, reason} ->
          Mix.shell().info("Could not generate changelog entry: #{reason}")
      end
    end
  end

  defp unreleased_empty?(content) do
    case String.split(content, "## [Unreleased]", parts: 2) do
      [_, after_unreleased] ->
        after_unreleased
        |> String.split(~r/^## \[/m, parts: 2)
        |> List.first()
        |> String.trim()
        |> Kernel.==("")

      _ ->
        false
    end
  end

  defp generate_changelog_entry do
    {last_tag, 0} = System.cmd("git", ["describe", "--tags", "--abbrev=0"])
    last_tag = String.trim(last_tag)

    {log, 0} = System.cmd("git", ["log", "#{last_tag}..HEAD", "--pretty=format:%s"])
    {diff, 0} = System.cmd("git", ["diff", "#{last_tag}..HEAD"])

    prompt = """
    Based on the following git commits and diff since #{last_tag}, write a short changelog entry.

    Use the appropriate Keep a Changelog heading(s): ### Added, ### Changed, ### Fixed, ### Removed.
    Each entry should be a single concise bullet point.
    Output ONLY the markdown heading(s) and bullet(s), nothing else.

    ## Commits

    #{log}

    ## Diff

    #{diff}
    """

    {cmd, args} = ai_cmd()
    args = args ++ [prompt]

    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {output, 0} -> {:ok, String.trim(output)}
      {output, _} -> {:error, String.trim(output)}
    end
  end

  defp ai_cmd do
    Application.get_env(:rodar_release, :ai_cmd, {"claude", ["-p"]})
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
