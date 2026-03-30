defmodule RodarRelease do
  @moduledoc """
  Version management and release utilities.

  The version lives directly in `mix.exs` as the single source of truth.
  At release time, `mix rodar_release.patch|minor|major` bumps it, updates
  CHANGELOG.md (including comparison links), commits, and tags.

  ## Semantic Versioning

  Versions follow [Semantic Versioning](https://semver.org) (`MAJOR.MINOR.PATCH`):

    * `:patch` — backward-compatible bug fixes
    * `:minor` — new functionality, backward-compatible
    * `:major` — breaking changes

  Pre-release suffixes (`-rc.1`, `-beta.1`, `-dev.1`) are automatically inferred
  from the current git branch. `develop` → `-dev`, `release/*` → `-rc`, etc.
  See `RodarRelease.Helpers.resolve_pre/2` for the full mapping.

  ## Releasing

      mix rodar_release.patch              # bug fix (on main)
      mix rodar_release.minor              # new feature (on main)
      mix rodar_release.major              # breaking change (on main)
      mix rodar_release.minor              # on develop: 1.1.0 -> 1.2.0-dev.1
      mix rodar_release.patch              # on develop: 1.2.0-dev.1 -> 1.2.0-dev.2
      mix rodar_release.patch              # on release/*: 1.2.0-dev.3 -> 1.2.0-rc.1
      mix rodar_release.patch --dry-run    # preview

  If `CHANGELOG.md` has no entries under `[Unreleased]`, the release task will
  offer to generate one using an AI CLI based on the git history since the
  last tag. You are prompted to confirm before anything is written.

  The AI CLI defaults to Claude Code (`{"claude", ["-p"]}`) and can be
  configured via:

      config :rodar_release, :ai_cmd, {"codex", ["e"]}

  ## Installation

  If your project uses [Igniter](https://hex.pm/packages/igniter):

      mix igniter.install rodar_release

  Otherwise, create a `CHANGELOG.md` with the
  [Keep a Changelog](https://keepachangelog.com) structure and optionally
  configure `:ai_cmd` in `config/config.exs`:

      config :rodar_release, :ai_cmd, {"gemini", ["-p"]}

  Custom branch-to-suffix mappings can also be configured:

      config :rodar_release, :branch_pre, %{
        "staging" => "rc",
        ~r/^preview\\// => "beta"
      }

  See the [README](https://github.com/rodar-project/rodar_release#without-igniter)
  for full manual setup instructions.

  ## Rollback & Amend

      mix rodar_release.rollback           # undo last release (soft reset)
      mix rodar_release.rollback --hard    # undo and discard changes
      mix rodar_release.amend              # fold changes into release commit

  Run `mix help rodar_release` for the full list of commands.
  """

  @version_pattern ~r/version:\s*"(\d+\.\d+\.\d+(?:-[a-zA-Z0-9]+\.\d+)?)"/

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
      [_, version] ->
        version

      nil ->
        raise "Could not find version in #{file}. Expected `version: \"x.y.z\"` or `version: \"x.y.z-pre.n\"`."
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
  Bumps a version string by the given segment, with optional pre-release label.

  ## Version transitions

    * **Stable + no pre** — normal bump: `bump("1.0.8", :patch)` → `"1.0.9"`
    * **Stable + `--pre`** — bump and start pre-release: `bump("1.1.0", :minor, "rc")` → `"1.2.0-rc.1"`
    * **Pre-release + same label** — increment counter: `bump("1.2.0-rc.1", :patch, "rc")` → `"1.2.0-rc.2"`
    * **Pre-release + different label** — switch label: `bump("1.2.0-dev.1", :patch, "rc")` → `"1.2.0-rc.1"`
    * **Pre-release + no pre** — promote to stable: `bump("1.2.0-rc.2", :patch)` → `"1.2.0"`

  ## Examples

      iex> RodarRelease.bump("1.0.8", :patch)
      "1.0.9"

      iex> RodarRelease.bump("1.0.8", :minor)
      "1.1.0"

      iex> RodarRelease.bump("1.0.8", :major)
      "2.0.0"

      iex> RodarRelease.bump("1.1.0", :minor, "rc")
      "1.2.0-rc.1"

      iex> RodarRelease.bump("1.2.0-rc.1", :patch, "rc")
      "1.2.0-rc.2"

      iex> RodarRelease.bump("1.2.0-rc.2", :patch)
      "1.2.0"

  """
  def bump(version, segment, pre \\ nil)

  def bump(version, segment, nil) when segment in [:patch, :minor, :major] do
    {base, _label, _counter} = parse_version(version)

    [major, minor, patch] =
      base
      |> String.split(".")
      |> Enum.map(&String.to_integer/1)

    if has_pre?(version) do
      # Promote to stable: strip suffix
      base
    else
      case segment do
        :patch -> "#{major}.#{minor}.#{patch + 1}"
        :minor -> "#{major}.#{minor + 1}.0"
        :major -> "#{major + 1}.0.0"
      end
    end
  end

  def bump(version, segment, pre) when segment in [:patch, :minor, :major] do
    validate_pre!(pre)
    {base, current_label, counter} = parse_version(version)

    if current_label == pre do
      # Same label: increment counter
      "#{base}-#{pre}.#{(counter || 0) + 1}"
    else
      if has_pre?(version) do
        # Different label: switch label, reset counter
        "#{base}-#{pre}.1"
      else
        # Stable version: bump segment, start pre-release
        bumped = bump(version, segment, nil)
        "#{bumped}-#{pre}.1"
      end
    end
  end

  defp parse_version(version) do
    case String.split(version, "-", parts: 2) do
      [base] ->
        {base, nil, nil}

      [base, pre_release] ->
        case String.split(pre_release, ".") do
          [label, counter] -> {base, label, String.to_integer(counter)}
          [label] -> {base, label, nil}
        end
    end
  end

  defp has_pre?(version), do: String.contains?(version, "-")

  defp validate_pre!(pre) do
    unless Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9]*$/, pre) do
      raise ArgumentError,
            "Invalid pre-release label #{inspect(pre)}. Must be alphanumeric, starting with a letter."
    end
  end
end
