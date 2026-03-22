defmodule RodarRelease do
  @moduledoc """
  Version management and release utilities.

  The version lives directly in `mix.exs` as the single source of truth.
  At release time, `mix rodar_release.patch|minor|major` bumps it, updates
  CHANGELOG.md, commits, and tags.

  ## Semantic Versioning

  Versions follow [Semantic Versioning](https://semver.org) (`MAJOR.MINOR.PATCH`):

    * `:patch` — backward-compatible bug fixes
    * `:minor` — new functionality, backward-compatible
    * `:major` — breaking changes

  Pre-release and build metadata (e.g. `1.0.0-rc.1`) are not currently supported.

  ## Releasing

      mix rodar_release.patch              # bug fix
      mix rodar_release.minor              # new feature
      mix rodar_release.major              # breaking change
      mix rodar_release.patch --dry-run    # preview

  If `CHANGELOG.md` has no entries under `[Unreleased]`, the release task will
  offer to generate one using an AI CLI based on the git history since the
  last tag. You are prompted to confirm before anything is written.

  The AI CLI defaults to Claude Code (`{"claude", ["-p"]}`) and can be
  configured via:

      config :rodar_release, :ai_cmd, {"ollama", ["run", "llama3"]}

  ## Rollback & Amend

      mix rodar_release.rollback           # undo last release (soft reset)
      mix rodar_release.rollback --hard    # undo and discard changes
      mix rodar_release.amend              # fold changes into release commit

  Run `mix help rodar_release` for the full list of commands.
  """

  @version_pattern ~r/version:\s*"(\d+\.\d+\.\d+)"/

  @doc """
  Reads the current version from a mix.exs file.

  ## Options

    * `:file` - path to mix.exs (default: `"mix.exs"`)

  ## Examples

      iex> File.write!("test_mix.exs", ~s|version: "1.2.3"|)
      iex> RodarRelease.read_version(file: "test_mix.exs")
      "1.2.3"
      iex> File.rm!("test_mix.exs")

  """
  def read_version(opts \\ []) do
    file = Keyword.get(opts, :file, "mix.exs")

    content =
      case File.read(file) do
        {:ok, c} -> c
        {:error, _} -> raise "Could not read #{file}"
      end

    case Regex.run(@version_pattern, content) do
      [_, version] -> version
      nil -> raise "Could not find version in #{file}. Expected `version: \"x.y.z\"`."
    end
  end

  @doc """
  Writes a new version into a mix.exs file, replacing the existing version string.

  ## Options

    * `:file` - path to mix.exs (default: `"mix.exs"`)

  """
  def write_version(new_version, opts \\ []) do
    file = Keyword.get(opts, :file, "mix.exs")

    content =
      case File.read(file) do
        {:ok, c} -> c
        {:error, _} -> raise "Could not read #{file}"
      end

    updated =
      Regex.replace(@version_pattern, content, ~s|version: "#{new_version}"|, global: false)

    File.write!(file, updated)
  end

  @doc """
  Bumps a version string by the given segment.

  ## Examples

      iex> RodarRelease.bump("1.0.8", :patch)
      "1.0.9"

      iex> RodarRelease.bump("1.0.8", :minor)
      "1.1.0"

      iex> RodarRelease.bump("1.0.8", :major)
      "2.0.0"

  """
  def bump(version, segment) when segment in [:patch, :minor, :major] do
    [major, minor, patch] =
      version
      |> String.split(".")
      |> Enum.map(&String.to_integer/1)

    case segment do
      :patch -> "#{major}.#{minor}.#{patch + 1}"
      :minor -> "#{major}.#{minor + 1}.0"
      :major -> "#{major + 1}.0.0"
    end
  end
end
