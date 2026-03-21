defmodule Mix.Tasks.RodarRelease.Bump do
  @moduledoc false

  import RodarRelease.Helpers

  def run(bump, args) do
    {opts, _, _} =
      OptionParser.parse(args, strict: [dry_run: :boolean, publish: :boolean])

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
      git!(["add", mix_file(), changelog_file()])
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
end
