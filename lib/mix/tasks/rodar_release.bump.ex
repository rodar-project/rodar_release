defmodule Mix.Tasks.RodarRelease.Bump do
  @moduledoc false

  import RodarRelease.Helpers

  def run(bump, args) do
    {opts, _, _} =
      OptionParser.parse(args, strict: [dry_run: :boolean, pre: :string])

    dry_run = Keyword.get(opts, :dry_run, false)
    pre = Keyword.get(opts, :pre)

    current_version = RodarRelease.read_version()

    unless dry_run do
      validate_clean_working_tree!()
    end

    release_version = RodarRelease.bump(current_version, bump, pre)
    today = Date.utc_today() |> Date.to_iso8601()

    Mix.shell().info("Release plan:")
    Mix.shell().info("  Current version:  #{current_version}")
    Mix.shell().info("  Release version:  #{release_version}")

    Mix.shell().info(
      "  Bump type:        #{bump}#{if pre, do: " (pre-release: #{pre})", else: ""}"
    )

    Mix.shell().info("")

    if dry_run do
      Mix.shell().info("[dry-run] Would update mix.exs version to #{release_version}")
      Mix.shell().info("[dry-run] Would update CHANGELOG.md with release date #{today}")
      Mix.shell().info("[dry-run] Would commit: release: v#{release_version}")
      Mix.shell().info("[dry-run] Would tag: v#{release_version}")
    else
      execute_release(release_version, today)
    end
  end

  defp execute_release(release_version, today) do
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
    Mix.shell().info("  git push origin main --tags")
  end
end
