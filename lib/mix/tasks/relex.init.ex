defmodule Mix.Tasks.Relex.Init do
  @shortdoc "Set up relex in your project"

  @moduledoc """
  Initializes relex in your project.

      mix relex.init
      mix relex.init --ai-cmd gemini

  ## What it does

    * Creates `CHANGELOG.md` with the Keep a Changelog structure (if missing)
    * Creates `.relex.exs` config template (if missing)

  ## Options

    * `--ai-cmd NAME` — set the AI CLI preset in `.relex.exs`.
      Known presets: `claude` (default), `gemini`, `gh`, `codex`.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [ai_cmd: :string])

    ensure_changelog()
    ensure_config(opts)
  end

  defp ensure_changelog do
    if File.exists?("CHANGELOG.md") do
      Mix.shell().info("CHANGELOG.md already exists, skipping.")
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

      File.write!("CHANGELOG.md", String.trim_leading(content))
      Mix.shell().info("Created CHANGELOG.md")
    end
  end

  defp ensure_config(opts) do
    if File.exists?(".relex.exs") do
      Mix.shell().info(".relex.exs already exists, skipping.")
    else
      ai_cmd = ai_preset(opts[:ai_cmd])
      content = build_config(ai_cmd)

      File.write!(".relex.exs", content)
      Mix.shell().info("Created .relex.exs")
    end
  end

  defp build_config(nil) do
    """
    # Relex configuration
    # See: https://github.com/relex-project/relex
    [
      # AI CLI for changelog generation (default: Claude Code)
      # ai_cmd: {"claude", ["-p"]},

      # Custom branch-to-suffix mappings
      # branch_pre: %{
      #   "staging" => "rc",
      #   ~r/^preview\\// => "beta"
      # }
    ]
    """
  end

  defp build_config(ai_cmd) do
    """
    # Relex configuration
    # See: https://github.com/relex-project/relex
    [
      # AI CLI for changelog generation
      ai_cmd: #{inspect(ai_cmd)},

      # Custom branch-to-suffix mappings
      # branch_pre: %{
      #   "staging" => "rc",
      #   ~r/^preview\\// => "beta"
      # }
    ]
    """
  end

  defp ai_preset("claude"), do: {"claude", ["-p"]}
  defp ai_preset("gemini"), do: {"gemini", ["-p"]}
  defp ai_preset("gh"), do: {"gh", ["-p"]}
  defp ai_preset("codex"), do: {"codex", ["e"]}
  defp ai_preset(nil), do: nil
  defp ai_preset(other), do: {other, []}

  defp read_current_version do
    Relex.read_version()
  rescue
    _ -> "0.1.0"
  end
end
