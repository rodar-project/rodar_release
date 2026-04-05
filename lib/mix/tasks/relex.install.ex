if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Relex.Install do
    @shortdoc "Set up relex in your project"

    @moduledoc """
    Sets up relex in your project.

        mix igniter.install relex

    ## What it does

      * Creates `CHANGELOG.md` with the standard Keep a Changelog structure
        if one does not already exist
      * Optionally configures `:ai_cmd` in `config/config.exs`
      * Suggests installing the `changelog` skill from
        [relex-project/relex_skills](https://github.com/relex-project/relex_skills)
        for AI-assisted dev tools

    ## Options

      * `--ai-cmd` - configure the AI CLI for changelog generation.
        Known presets: `claude`, `gemini`, `gh`, `codex`.
        Unknown values are treated as a command with no extra args.
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :relex,
        example: "mix igniter.install relex",
        schema: [ai_cmd: :string]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> ensure_changelog()
      |> maybe_configure_ai_cmd()
      |> suggest_changelog_skill()
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
            :relex,
            [:ai_cmd],
            ai_preset(name)
          )
      end
    end

    defp ai_preset("claude"), do: {"claude", ["-p"]}
    defp ai_preset("gemini"), do: {"gemini", ["-p"]}
    defp ai_preset("gh"), do: {"gh", ["-p"]}
    defp ai_preset("codex"), do: {"codex", ["e"]}
    defp ai_preset(other), do: {other, []}

    defp suggest_changelog_skill(igniter) do
      Igniter.add_notice(igniter, """
      📋 Recommended: install the changelog skill for AI-assisted dev tools:

          npx skills add relex-project/relex_skills --skill changelog

      See https://www.npmjs.com/package/skills for more options.
      """)
    end

    defp read_current_version do
      Relex.read_version()
    rescue
      _ -> "0.1.0"
    end
  end
end
