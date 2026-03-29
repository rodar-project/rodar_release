# RodarRelease

Version management and release utilities for Rodar projects. Automates semantic version bumping, changelog updates, git commits/tags.

## Installation

Add `rodar_release` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rodar_release, "~> 0.1.0"}
  ]
end
```

### With Igniter

If your project uses [Igniter](https://hex.pm/packages/igniter), you can install with automatic setup:

```bash
mix igniter.install rodar_release
```

This creates a `CHANGELOG.md` with the standard [Keep a Changelog](https://keepachangelog.com) structure if one doesn't exist. To also configure a custom AI CLI:

```bash
mix igniter.install rodar_release --ai-cmd gemini
```

### Without Igniter

If your project does not use Igniter, follow these steps after adding the dependency:

1. **Create `CHANGELOG.md`** in your project root with the [Keep a Changelog](https://keepachangelog.com) structure:

    ```markdown
    # Changelog

    All notable changes to this project will be documented in this file.

    The format is based on [Keep a Changelog](https://keepachangelog.com),
    and this project adheres to [Semantic Versioning](https://semver.org).

    ## [Unreleased]

    ## [0.1.0] - 2026-01-01

    ### Added

    - Initial release
    ```

    Replace `0.1.0` with your current version and `2026-01-01` with today's date.

2. **(Optional) Configure AI CLI** for changelog generation in `config/config.exs`:

    ```elixir
    config :rodar_release, :ai_cmd, {"claude", ["-p"]}   # default (Claude Code)
    config :rodar_release, :ai_cmd, {"gemini", ["-p"]}   # Gemini CLI
    config :rodar_release, :ai_cmd, {"codex", ["e"]}     # OpenAI Codex
    config :rodar_release, :ai_cmd, {"gh", ["-p"]}       # GitHub Copilot
    ```

    If omitted, [Claude Code](https://claude.com/claude-code) is used by default.

3. **(Recommended) Install the changelog skill** for AI-assisted dev tools:

    ```bash
    npx skills add rodar-project/rodar_skills --skill changelog
    ```

## Semantic Versioning

This tool follows [Semantic Versioning](https://semver.org) (`MAJOR.MINOR.PATCH`):

- **Patch** (`mix rodar_release.patch`) — backward-compatible bug fixes. Use when you fix a bug without changing the public API.
- **Minor** (`mix rodar_release.minor`) — new functionality that is backward-compatible. Use when you add a feature, deprecate something, or make non-breaking changes.
- **Major** (`mix rodar_release.major`) — breaking changes. Use when you remove or change existing behavior in a way that requires consumers to update their code.

> Pre-release identifiers (e.g. `1.0.0-rc.1`) and build metadata (e.g. `1.0.0+build.42`) are part of the semver spec but are not currently supported by this tool.

## Usage

```bash
mix rodar_release              # list available commands
mix help rodar_release.patch   # help for a specific command
```

### Commands

#### Release

```bash
mix rodar_release.patch              # bug fix:        1.0.8 -> 1.0.9
mix rodar_release.minor              # new feature:    1.0.8 -> 1.1.0
mix rodar_release.major              # breaking change: 1.0.8 -> 2.0.0
mix rodar_release.minor --dry-run    # preview changes
```

1. Validates the git working directory is clean
2. If `[Unreleased]` in `CHANGELOG.md` is empty, offers to generate an entry using [Claude Code](https://claude.com/claude-code) (requires `claude` CLI)
3. Bumps the version in `mix.exs`
4. Updates `CHANGELOG.md` with the release date and comparison links
5. Commits changes with message `release: vX.Y.Z`
6. Creates an annotated git tag `vX.Y.Z`

#### AI-generated changelog

When releasing with an empty `[Unreleased]` section, the tool gathers the git log and diff since the last tag and asks an AI CLI to suggest a changelog entry using [Keep a Changelog](https://keepachangelog.com) headings (`### Added`, `### Changed`, `### Fixed`, `### Removed`). You are prompted to confirm before anything is written.

By default it uses [Claude Code](https://claude.com/claude-code). To use a different AI CLI, configure the command and args in your `config.exs`:

```elixir
config :rodar_release, :ai_cmd, {"claude", ["-p"]}   # default
config :rodar_release, :ai_cmd, {"gemini", ["-p"]}   # Gemini CLI
config :rodar_release, :ai_cmd, {"codex", ["e"]}     # OpenAI Codex
```

The prompt is appended as the last argument.

#### Rollback

```bash
mix rodar_release.rollback           # undo last release (soft reset)
mix rodar_release.rollback --hard    # undo and discard changes
mix rodar_release.rollback --dry-run # preview rollback
```

Undoes the last release by deleting its tag and resetting the release commit. Requires the latest commit to be a release commit (`release: vX.Y.Z`).

- **Soft (default):** resets the commit and restores `mix.exs` and `CHANGELOG.md` to the pre-release state.
- **Hard (`--hard`):** discards all release changes entirely.

#### Amend

```bash
mix rodar_release.amend              # fold changes into release commit
mix rodar_release.amend --dry-run    # preview amend
```

Amends the last release commit with any current changes and re-tags. Useful for fixing a typo or adding a missing file right after releasing.

### Options

| Option      | Applies to          | Description                           |
|-------------|---------------------|---------------------------------------|
| `--dry-run` | all commands        | Preview changes without applying them |
| `--hard`    | rollback            | Discard release changes entirely      |

### Programmatic API

```elixir
RodarRelease.read_version()
#=> "0.1.0"

RodarRelease.bump("1.2.3", :minor)
#=> "1.3.0"

RodarRelease.write_version("1.3.0")
```
