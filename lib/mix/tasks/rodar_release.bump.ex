defmodule Mix.Tasks.RodarRelease.Bump do
  @moduledoc false

  import RodarRelease.Helpers

  def run(bump, args) do
    {opts, _, _} =
      OptionParser.parse(args, strict: [dry_run: :boolean, pre: :string, no_tag: :boolean])

    dry_run = Keyword.get(opts, :dry_run, false)
    explicit_pre = Keyword.get(opts, :pre)
    no_tag = Keyword.get(opts, :no_tag, false)

    branch = current_branch()

    case resolve_pre(branch, explicit_pre) do
      {:ok, pre} ->
        do_run(bump, pre, branch, dry_run, no_tag: no_tag)

      {:error, reason} ->
        Mix.raise(reason)
    end
  end

  defp do_run(bump, pre, branch, dry_run, opts) do
    current_version = RodarRelease.read_version()

    if pre == nil and RodarRelease.has_pre?(current_version) do
      Mix.raise(
        "Current version #{current_version} has a pre-release suffix on #{branch}.\n" <>
          "This typically happens after merging a development branch.\n\n" <>
          "Use `mix rodar_release.merge` to promote the pre-release version."
      )
    end

    unless dry_run do
      validate_clean_working_tree!()
    end

    release_version = RodarRelease.bump(current_version, bump, pre)
    today = Date.utc_today() |> Date.to_iso8601()

    Mix.shell().info("Release plan:")
    Mix.shell().info("  Branch:           #{branch}")
    Mix.shell().info("  Current version:  #{current_version}")
    Mix.shell().info("  Release version:  #{release_version}")

    Mix.shell().info(
      "  Bump type:        #{bump}#{if pre, do: " (pre-release: #{pre})", else: ""}"
    )

    Mix.shell().info("")

    no_tag = Keyword.get(opts, :no_tag, false)
    is_prerelease = pre != nil
    skip_tag = no_tag or is_prerelease

    if dry_run do
      Mix.shell().info("[dry-run] Would update mix.exs version to #{release_version}")
      Mix.shell().info("[dry-run] Would update CHANGELOG.md with release date #{today}")
      Mix.shell().info("[dry-run] Would commit: release: v#{release_version}")

      if skip_tag do
        Mix.shell().info("[dry-run] Would skip tagging (pre-release or --no-tag)")
      else
        Mix.shell().info("[dry-run] Would tag: v#{release_version}")
      end
    else
      unless skip_tag do
        validate_tag_available!(release_version)
      end

      execute_release(release_version, today, no_tag: no_tag)
    end
  end
end
