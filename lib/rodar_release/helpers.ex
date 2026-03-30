defmodule RodarRelease.Helpers do
  @moduledoc false

  @mix_file "mix.exs"
  @changelog_file "CHANGELOG.md"
  @release_commit_pattern ~r/^release: v(\d+\.\d+\.\d+(?:-[a-zA-Z0-9]+\.\d+)?)$/

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

  def validate_tag_available!(version) do
    {output, 0} = System.cmd("git", ["tag", "-l", "v#{version}"])

    unless String.trim(output) == "" do
      Mix.raise(
        "Tag v#{version} already exists. " <>
          "This version has already been released."
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
      content
      |> String.replace(
        "## [Unreleased]",
        "## [Unreleased]\n\n## [#{version}] - #{date}",
        global: false
      )
      |> strip_empty_unreleased()
      |> update_comparison_links(version)

    File.write!(@changelog_file, updated)
  end

  defp strip_empty_unreleased(content) do
    # Remove the [Unreleased] heading when it has no entries beneath it
    String.replace(content, ~r/## \[Unreleased\]\n\n(?=## \[)/, "")
  end

  defp update_comparison_links(content, version) do
    # Update [Unreleased] link to compare from the new version tag
    content =
      Regex.replace(
        ~r/\[Unreleased\]: (https:\/\/github\.com\/[^\/]+\/[^\/]+)\/compare\/v[^\s]+\.\.\.HEAD/,
        content,
        "[Unreleased]: \\1/compare/v#{version}...HEAD"
      )

    # Insert the new version comparison link after the [Unreleased] link
    # It compares from the previous version tag to the new one
    case Regex.run(
           ~r/\[Unreleased\]: (https:\/\/github\.com\/[^\/]+\/[^\/]+)\/compare\/v#{Regex.escape(version)}\.\.\.HEAD\n(?:\[([^\]]+)\]: )?/,
           content
         ) do
      [_, base_url, prev_version] ->
        String.replace(
          content,
          "[Unreleased]: #{base_url}/compare/v#{version}...HEAD\n[#{prev_version}]:",
          "[Unreleased]: #{base_url}/compare/v#{version}...HEAD\n[#{version}]: #{base_url}/compare/v#{prev_version}...v#{version}\n[#{prev_version}]:",
          global: false
        )

      [_, _base_url] ->
        # No previous version link exists, nothing to insert
        content

      nil ->
        # No [Unreleased] link found, nothing to update
        content
    end
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

  @default_branch_pre %{
    "main" => nil,
    "master" => nil,
    "develop" => "dev",
    "dev" => "dev"
  }

  @default_branch_pre_patterns [
    {~r/^release\//, "rc"},
    {~r/^rc\//, "rc"},
    {~r/^beta\//, "beta"},
    {~r/^alpha\//, "alpha"}
  ]

  def current_branch do
    {branch, 0} = System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"])
    String.trim(branch)
  end

  @doc """
  Resolves the effective pre-release label based on the current branch and the
  explicit `--pre` flag value.

  Returns `{:ok, pre}` where `pre` is `nil` (stable) or a label string,
  or `{:error, reason}` for invalid combinations.
  """
  def resolve_pre(branch, explicit_pre) do
    branch_pre = branch_pre_config()
    mapped = lookup_branch_pre(branch, branch_pre)

    case {mapped, explicit_pre} do
      # Main branch: stable only, reject --pre
      {nil, nil} when branch in ["main", "master"] ->
        {:ok, nil}

      {nil, _pre} when branch in ["main", "master"] ->
        {:error,
         "Cannot use --pre on #{branch}. Release candidates should have their own branch."}

      # Unmapped branch: block releases
      {:unmapped, _} ->
        {:error,
         "Releases are not allowed from branch \"#{branch}\".\n" <>
           "Use main for stable releases or a mapped branch (develop, release/*, etc.) for pre-releases.\n" <>
           "Configure custom branch mappings via: config :rodar_release, :branch_pre, %{...}"}

      # Mapped branch: use mapped suffix, allow --pre to override
      {suffix, nil} when is_binary(suffix) ->
        {:ok, suffix}

      {_suffix, explicit} when is_binary(explicit) ->
        {:ok, explicit}
    end
  end

  defp lookup_branch_pre(branch, {exact, patterns}) do
    case Map.fetch(exact, branch) do
      {:ok, value} -> value
      :error -> match_branch_pattern(branch, patterns)
    end
  end

  defp match_branch_pattern(_branch, []), do: :unmapped

  defp match_branch_pattern(branch, [{pattern, suffix} | rest]) do
    if Regex.match?(pattern, branch) do
      suffix
    else
      match_branch_pattern(branch, rest)
    end
  end

  defp branch_pre_config do
    custom = Application.get_env(:rodar_release, :branch_pre, %{})

    {custom_exact, custom_patterns} =
      Enum.split_with(custom, fn {k, _v} -> is_binary(k) end)

    exact = Map.merge(@default_branch_pre, Map.new(custom_exact))

    patterns =
      Enum.map(custom_patterns, fn {regex, suffix} -> {regex, suffix} end) ++
        @default_branch_pre_patterns

    {exact, patterns}
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

  def execute_release(release_version, today) do
    maybe_generate_changelog_entry()

    step("Updating mix.exs version to #{release_version}", fn ->
      RodarRelease.write_version(release_version)
    end)

    step("Updating CHANGELOG.md with release date", fn ->
      update_changelog(release_version, today)
    end)

    step("Committing release v#{release_version}", fn ->
      git!(["add", mix_file(), changelog_file()])
      git!(["commit", "-m", "release: v#{release_version}"])
    end)

    step("Tagging v#{release_version}", fn ->
      git!(["tag", "-a", "v#{release_version}", "-m", "Release v#{release_version}"])
    end)

    Mix.shell().info("")
    Mix.shell().info("Release v#{release_version} complete!")
    Mix.shell().info("")
    Mix.shell().info("Next steps:")
    Mix.shell().info("  git push origin #{current_branch()} --tags")
  end
end
