defmodule Relex do
  @moduledoc """
  Version management and release utilities.

  The version lives directly in `mix.exs` as the single source of truth.
  At release time, `mix relex.patch|minor|major` bumps it, updates
  CHANGELOG.md (including comparison links), and commits. Stable releases
  are also tagged; pre-release versions skip tagging by default to avoid
  polluting the tags list. Use `--no-tag` to skip tagging on any release.

  ## Semantic Versioning

  Versions follow [Semantic Versioning](https://semver.org) (`MAJOR.MINOR.PATCH`):

    * `:patch` — backward-compatible bug fixes
    * `:minor` — new functionality, backward-compatible
    * `:major` — breaking changes

  Pre-release suffixes (`-rc.1`, `-beta.1`, `-dev.1`) are automatically inferred
  from the current git branch:

    * `main` / `master` — stable (no suffix)
    * `develop` — `-dev`
    * `release/*` — `-rc`
    * `hotfix/*` — `-rc`
    * custom mappings via `config :relex, :branch_pre, %{...}`

  ## Releasing

      mix relex.patch              # bug fix (on main)
      mix relex.minor              # new feature (on main)
      mix relex.major              # breaking change (on main)
      mix relex.minor              # on develop: 1.1.0 -> 1.2.0-dev.1
      mix relex.patch              # on develop: 1.2.0-dev.1 -> 1.2.0-dev.2
      mix relex.patch              # on release/*: 1.2.0-dev.3 -> 1.2.0-rc.1
      mix relex.patch --dry-run    # preview

  ## Post-merge promotion

  After merging a development branch into `main`, the version will have a
  pre-release suffix (e.g. `1.5.1-dev.3`). Use `mix relex.merge` to
  promote it to a stable release:

      mix relex.merge              # 1.5.1-dev.3 -> 1.5.1
      mix relex.merge minor        # 1.5.1-dev.3 -> 1.6.0
      mix relex.merge major        # 1.5.1-dev.3 -> 2.0.0

  The regular `patch/minor/major` tasks will detect a leftover pre-release
  suffix on a stable branch and point you to `merge` instead.

  If `CHANGELOG.md` has no entries under `[Unreleased]`, the release task will
  offer to generate one using an AI CLI based on the git history since the
  last tag. You are prompted to confirm before anything is written.

  The AI CLI defaults to Claude Code (`{"claude", ["-p"]}`) and can be
  configured via:

      config :relex, :ai_cmd, {"codex", ["e"]}

  ## Installation

  If your project uses [Igniter](https://hex.pm/packages/igniter):

      mix igniter.install relex

  Otherwise, create a `CHANGELOG.md` with the
  [Keep a Changelog](https://keepachangelog.com) structure and optionally
  configure `:ai_cmd` in `config/config.exs`:

      config :relex, :ai_cmd, {"gemini", ["-p"]}

  Custom branch-to-suffix mappings can also be configured:

      config :relex, :branch_pre, %{
        "staging" => "rc",
        ~r/^preview\\// => "beta"
      }

  See the [README](https://github.com/relex-project/relex#without-igniter)
  for full manual setup instructions.

  ## Rollback & Amend

      mix relex.rollback           # undo last release (soft reset)
      mix relex.rollback --hard    # undo and discard changes
      mix relex.amend              # fold changes into release commit

  Run `mix help relex` for the full list of commands.
  """

  @version_pattern ~r/version:\s*"(\d+\.\d+\.\d+(?:-[a-zA-Z0-9]+\.\d+)?)"/

  @doc """
  Reads the current version from a mix.exs file.

  ## Options

    * `:file` - path to mix.exs (default: `"mix.exs"`)

  ## Examples

      iex> File.write!("test_mix.exs", ~s|version: "1.2.3"|)
      iex> Relex.read_version(file: "test_mix.exs")
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

      iex> Relex.bump("1.0.8", :patch)
      "1.0.9"

      iex> Relex.bump("1.0.8", :minor)
      "1.1.0"

      iex> Relex.bump("1.0.8", :major)
      "2.0.0"

      iex> Relex.bump("1.1.0", :minor, "rc")
      "1.2.0-rc.1"

      iex> Relex.bump("1.2.0-rc.1", :patch, "rc")
      "1.2.0-rc.2"

      iex> Relex.bump("1.2.0-rc.2", :patch)
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

  @doc """
  Promotes a pre-release version to stable.

  Without a segment, strips the suffix and returns the base version.
  With a segment, bumps the base version by that segment — useful when
  the merge represents a higher-level change than the original pre-release.

  ## Examples

      iex> Relex.promote("1.5.1-dev.3")
      "1.5.1"

      iex> Relex.promote("1.5.1-dev.3", :minor)
      "1.6.0"

      iex> Relex.promote("1.5.1-dev.3", :major)
      "2.0.0"

  """
  def promote(version, segment \\ nil)

  def promote(version, nil) do
    unless has_pre?(version) do
      raise ArgumentError,
            "promote/2 expects a pre-release version, got #{inspect(version)}"
    end

    {base, _label, _counter} = parse_version(version)
    base
  end

  def promote(version, segment) when segment in [:patch, :minor, :major] do
    unless has_pre?(version) do
      raise ArgumentError,
            "promote/2 expects a pre-release version, got #{inspect(version)}"
    end

    {base, _label, _counter} = parse_version(version)
    bump(base, segment)
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

  @doc """
  Returns whether a version string contains a pre-release suffix.

  ## Examples

      iex> Relex.has_pre?("1.0.0-rc.1")
      true

      iex> Relex.has_pre?("1.0.0")
      false

  """
  def has_pre?(version), do: String.contains?(version, "-")

  defp validate_pre!(pre) do
    unless Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9]*$/, pre) do
      raise ArgumentError,
            "Invalid pre-release label #{inspect(pre)}. Must be alphanumeric, starting with a letter."
    end
  end
end
