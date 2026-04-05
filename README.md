# Relex

Relaxed release management for Elixir projects. Automates semantic version bumping, changelog updates, git commits/tags.

**Rel**ease + Eli**x**ir = **Relex** — because shipping versions should feel like a `mix` away from relaxing.

## Installation

Add `relex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:relex, "~> 0.1.0"}
  ]
end
```

### With Igniter

If your project uses [Igniter](https://hex.pm/packages/igniter), you can install with automatic setup:

```bash
mix igniter.install relex
```

This creates a `CHANGELOG.md` with the standard [Keep a Changelog](https://keepachangelog.com) structure if one doesn't exist. To also configure a custom AI CLI:

```bash
mix igniter.install relex --ai-cmd gemini
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
    config :relex, :ai_cmd, {"claude", ["-p"]}   # default (Claude Code)
    config :relex, :ai_cmd, {"gemini", ["-p"]}   # Gemini CLI
    config :relex, :ai_cmd, {"codex", ["e"]}     # OpenAI Codex
    config :relex, :ai_cmd, {"gh", ["-p"]}       # GitHub Copilot
    ```

    If omitted, [Claude Code](https://claude.com/claude-code) is used by default.

3. **(Recommended) Install the changelog skill** for AI-assisted dev tools:

    ```bash
    npx skills add relex-project/relex_skills --skill changelog
    ```

## Semantic Versioning

This tool follows [Semantic Versioning](https://semver.org) (`MAJOR.MINOR.PATCH`):

- **Patch** (`mix relex.patch`) — backward-compatible bug fixes. Use when you fix a bug without changing the public API.
- **Minor** (`mix relex.minor`) — new functionality that is backward-compatible. Use when you add a feature, deprecate something, or make non-breaking changes.
- **Major** (`mix relex.major`) — breaking changes. Use when you remove or change existing behavior in a way that requires consumers to update their code.

### Pre-release versions

Pre-release identifiers (e.g. `1.2.0-rc.1`) are supported and automatically inferred from the current git branch:

| Branch | Suffix | Example |
|---|---|---|
| `main` / `master` | (none) | `1.2.0` |
| `develop` / `dev` | `-dev.N` | `1.2.0-dev.1` |
| `release/*` / `rc/*` | `-rc.N` | `1.2.0-rc.1` |
| `beta/*` | `-beta.N` | `1.2.0-beta.1` |
| `alpha/*` | `-alpha.N` | `1.2.0-alpha.1` |

The full lifecycle looks like:

```
main:    1.1.0 (stable)
              ↓ branch develop
develop: 1.2.0-dev.1 → 1.2.0-dev.2 → 1.2.0-dev.3
                                       ↓ branch release/1.2.0
release: 1.2.0-rc.1  → 1.2.0-rc.2
                         ↓ merge to main
main:    1.2.0 (stable)
```

**Rules:**
- `--pre` is **rejected on `main`/`master`** — release candidates should have their own branch
- Releases from **unmapped branches** (feature branches, etc.) are blocked
- `--pre` on a mapped branch **overrides** the auto-inferred suffix
- Labels must be alphanumeric and start with a letter (e.g., `rc`, `beta`, `dev`, `alpha`)

Custom branch mappings can be configured in `config.exs`:

```elixir
config :relex, :branch_pre, %{
  "staging" => "rc",
  ~r/^preview\// => "beta"
}
```

> Build metadata (e.g. `1.0.0+build.42`) is part of the semver spec but is not currently supported by this tool.

## Usage

```bash
mix relex              # list available commands
mix help relex.patch   # help for a specific command
```

### Commands

#### Release

```bash
mix relex.patch              # bug fix:         1.0.8 -> 1.0.9
mix relex.minor              # new feature:     1.0.8 -> 1.1.0
mix relex.major              # breaking change: 1.0.8 -> 2.0.0
mix relex.minor --pre rc     # pre-release:     1.1.0 -> 1.2.0-rc.1
mix relex.minor --dry-run    # preview changes
```

1. Resolves the pre-release suffix from the current branch (or `--pre` flag)
2. Validates the git working directory is clean
3. If `[Unreleased]` in `CHANGELOG.md` is empty, offers to generate an entry using [Claude Code](https://claude.com/claude-code) (requires `claude` CLI)
4. Bumps the version in `mix.exs`
5. Updates `CHANGELOG.md` with the release date and comparison links
6. Commits changes with message `release: vX.Y.Z`
7. Creates an annotated git tag `vX.Y.Z` (stable releases only — pre-releases skip tagging by default)

#### AI-generated changelog

When releasing with an empty `[Unreleased]` section, the tool gathers the git log and diff since the last tag and asks an AI CLI to suggest a changelog entry using [Keep a Changelog](https://keepachangelog.com) headings (`### Added`, `### Changed`, `### Fixed`, `### Removed`). You are prompted to confirm before anything is written.

By default it uses [Claude Code](https://claude.com/claude-code). To use a different AI CLI, configure the command and args in your `config.exs`:

```elixir
config :relex, :ai_cmd, {"claude", ["-p"]}   # default
config :relex, :ai_cmd, {"gemini", ["-p"]}   # Gemini CLI
config :relex, :ai_cmd, {"codex", ["e"]}     # OpenAI Codex
```

The prompt is appended as the last argument.

#### Merge (post-merge promotion)

```bash
mix relex.merge              # 1.5.1-dev.3 -> 1.5.1
mix relex.merge minor        # 1.5.1-dev.3 -> 1.6.0
mix relex.merge major        # 1.5.1-dev.3 -> 2.0.0
mix relex.merge --dry-run    # preview changes
mix relex.merge --no-tag     # promote without tagging
```

Promotes a pre-release version to stable after merging a development branch into `main`/`master`. Without arguments, strips the pre-release suffix. Pass a segment to bump higher.

If you run `mix relex.patch` (or `minor`/`major`) on a stable branch and the current version has a pre-release suffix, the task will detect this and suggest using `merge` instead.

#### Tagging behavior

By default, **stable releases** create an annotated git tag (`vX.Y.Z`) and suggest pushing only that specific tag. **Pre-release versions** skip tagging entirely to avoid polluting the tags list with `-dev.N`, `-rc.N`, etc.

Use `--no-tag` to skip tagging on any release, including stable ones.

#### Rollback

```bash
mix relex.rollback           # undo last release (soft reset)
mix relex.rollback --hard    # undo and discard changes
mix relex.rollback --dry-run # preview rollback
```

Undoes the last release by deleting its tag and resetting the release commit. Requires the latest commit to be a release commit (`release: vX.Y.Z`).

- **Soft (default):** resets the commit and restores `mix.exs` and `CHANGELOG.md` to the pre-release state.
- **Hard (`--hard`):** discards all release changes entirely.

#### Amend

```bash
mix relex.amend              # fold changes into release commit
mix relex.amend --dry-run    # preview amend
```

Amends the last release commit with any current changes and re-tags. Useful for fixing a typo or adding a missing file right after releasing.

### Options

| Option         | Applies to                    | Description                                                  |
|----------------|-------------------------------|--------------------------------------------------------------|
| `--dry-run`    | all commands                  | Preview changes without applying them                        |
| `--pre LABEL`  | patch, minor, major           | Create a pre-release version (e.g., `--pre rc`, `--pre beta`) |
| `--no-tag`     | patch, minor, major, merge    | Skip creating a git tag for the release                      |
| `--hard`       | rollback                      | Discard release changes entirely                             |

### Programmatic API

```elixir
Relex.read_version()
#=> "1.2.0"

Relex.bump("1.2.3", :minor)
#=> "1.3.0"

Relex.bump("1.1.0", :minor, "rc")
#=> "1.2.0-rc.1"

Relex.bump("1.2.0-rc.1", :patch, "rc")
#=> "1.2.0-rc.2"

Relex.bump("1.2.0-rc.2", :patch)
#=> "1.2.0"

Relex.promote("1.5.1-dev.3", :minor)
#=> "1.6.0"

Relex.has_pre?("1.2.0-rc.1")
#=> true

Relex.write_version("1.3.0")
```
