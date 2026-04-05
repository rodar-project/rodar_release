defmodule Mix.Tasks.Relex.Merge do
  @shortdoc "Promote a pre-release version after merging into a stable branch"
  @moduledoc """
  Promotes a pre-release version to stable after merging a development branch.

      mix relex.merge              # 1.5.1-dev.3 → 1.5.1
      mix relex.merge minor        # 1.5.1-dev.3 → 1.6.0
      mix relex.merge major        # 1.5.1-dev.3 → 2.0.0

  Without a segment argument, the pre-release suffix is stripped and the base
  version is used as-is. Pass `patch`, `minor`, or `major` to bump higher.

  This task is intended for use on stable branches (`main`/`master`) after
  merging a branch that carries a pre-release version (e.g. `develop`).

  ## Options

    * `--dry-run` - Preview the release without making changes
    * `--no-tag` - Skip creating a git tag for the release

  """
  use Mix.Task

  import Relex.Helpers

  @impl Mix.Task
  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args, strict: [dry_run: :boolean, no_tag: :boolean])

    dry_run = Keyword.get(opts, :dry_run, false)
    no_tag = Keyword.get(opts, :no_tag, false)
    segment = parse_segment!(positional)
    branch = current_branch()

    validate_stable_branch!(branch)

    current_version = Relex.read_version()
    validate_has_pre!(current_version)

    unless dry_run do
      validate_clean_working_tree!()
    end

    release_version = Relex.promote(current_version, segment)
    today = Date.utc_today() |> Date.to_iso8601()

    Mix.shell().info("Merge promotion plan:")
    Mix.shell().info("  Branch:           #{branch}")
    Mix.shell().info("  Current version:  #{current_version}")
    Mix.shell().info("  Release version:  #{release_version}")

    if segment do
      Mix.shell().info("  Bump type:        #{segment}")
    end

    Mix.shell().info("")

    if dry_run do
      Mix.shell().info("[dry-run] Would update mix.exs version to #{release_version}")
      Mix.shell().info("[dry-run] Would update CHANGELOG.md with release date #{today}")
      Mix.shell().info("[dry-run] Would commit: release: v#{release_version}")

      if no_tag do
        Mix.shell().info("[dry-run] Would skip tagging (--no-tag)")
      else
        Mix.shell().info("[dry-run] Would tag: v#{release_version}")
      end
    else
      unless no_tag do
        validate_tag_available!(release_version)
      end

      execute_release(release_version, today, no_tag: no_tag)
    end
  end

  defp parse_segment!([segment]) when segment in ~w(patch minor major) do
    String.to_existing_atom(segment)
  end

  defp parse_segment!([invalid]) do
    Mix.raise("Invalid segment #{inspect(invalid)}. Expected one of: patch, minor, major")
  end

  defp parse_segment!([]), do: nil

  defp parse_segment!(_) do
    Mix.raise(
      "Too many arguments.\n\n" <>
        "Usage: mix relex.merge [patch|minor|major]"
    )
  end

  defp validate_stable_branch!(branch) do
    unless branch in ["main", "master"] do
      Mix.raise(
        "merge must be run from main or master, got #{inspect(branch)}.\n" <>
          "Switch to your stable branch after merging, then run this task."
      )
    end
  end

  defp validate_has_pre!(version) do
    unless Relex.has_pre?(version) do
      Mix.raise(
        "Current version #{version} is not a pre-release.\n" <>
          "Use `mix relex.patch|minor|major` for regular releases."
      )
    end
  end
end
