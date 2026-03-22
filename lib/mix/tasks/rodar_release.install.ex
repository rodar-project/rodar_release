if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.RodarRelease.Install do
    @shortdoc "Set up rodar_release in your project"

    @moduledoc """
    Sets up rodar_release in your project.

        mix igniter.install rodar_release

    ## What it does

      * Creates `CHANGELOG.md` with the standard Keep a Changelog structure
        if one does not already exist
      * Optionally configures `:ai_cmd` in `config/config.exs`

    ## Options

      * `--ai-cmd` - configure the AI CLI for changelog generation.
        Known presets: `claude`, `gemini`, `gh-copilot`, `codex`.
        Unknown values are treated as a command with no extra args.
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :rodar_release,
        example: "mix igniter.install rodar_release",
        schema: [ai_cmd: :string]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> ensure_changelog()
      |> maybe_configure_ai_cmd()
    end

    defp ensure_changelog(igniter) do
      if Igniter.exists?(igniter, "CHANGELOG.md") do
        igniter
      else
        version = read_current_version()
        today = Date.utc_today() |> Date.to_iso8601()

        content = """
        # Changelog

        All notable changes to this project will be documented in this file.

        The format is based on [Keep a Changelog](https://keepachangelog.com),
        and this project adheres to [Semantic Versioning](https://semver.org).

        ## [Unreleased]

        ## [#{version}] - #{today}

        ### Added

        - Initial release
        """

        Igniter.create_new_file(igniter, "CHANGELOG.md", String.trim_leading(content))
      end
    end

    defp maybe_configure_ai_cmd(igniter) do
      case igniter.args.options[:ai_cmd] do
        nil ->
          igniter

        name ->
          Igniter.Project.Config.configure(
            igniter,
            "config.exs",
            :rodar_release,
            [:ai_cmd],
            ai_preset(name)
          )
      end
    end

    defp ai_preset("claude"), do: {"claude", ["-p"]}
    defp ai_preset("gemini"), do: {"gemini", ["-p"]}
    defp ai_preset("gh-copilot"), do: {"gh", ["-p"]}
    defp ai_preset("codex"), do: {"codex", ["e"]}
    defp ai_preset(other), do: {other, []}

    defp read_current_version do
      RodarRelease.read_version()
    rescue
      _ -> "0.1.0"
    end
  end
end
