# RodarRelease

Version management and release utilities for Rodar projects. Automates semantic version bumping, changelog updates, git commits/tags, and Hex publishing.

## Installation

Add `rodar_release` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rodar_release, "~> 0.1.0"}
  ]
end
```

## Usage

```bash
mix rodar_release <command> [options]
```

### Commands

#### Release

```bash
mix rodar_release patch              # 1.0.8 -> 1.0.9
mix rodar_release minor              # 1.0.8 -> 1.1.0
mix rodar_release major              # 1.0.8 -> 2.0.0
mix rodar_release minor --dry-run    # preview changes
mix rodar_release major --publish    # release + publish to Hex
```

1. Validates the git working directory is clean
2. Bumps the version in `mix.exs`
3. Updates `CHANGELOG.md` with the release date
4. Commits changes with message `release: vX.Y.Z`
5. Creates an annotated git tag `vX.Y.Z`
6. Optionally publishes to Hex

#### Publish

```bash
mix rodar_release publish              # publish current version to Hex
mix rodar_release publish --dry-run    # preview publish
```

Publishes the current version to Hex. Useful when you've already bumped and tagged a release but deferred publishing.

#### Rollback

```bash
mix rodar_release rollback           # undo last release (soft reset)
mix rodar_release rollback --hard    # undo and discard changes
mix rodar_release rollback --dry-run # preview rollback
```

Undoes the last release by deleting its tag and resetting the release commit. Requires the latest commit to be a release commit (`release: vX.Y.Z`).

- **Soft (default):** resets the commit and restores `mix.exs` and `CHANGELOG.md` to the pre-release state.
- **Hard (`--hard`):** discards all release changes entirely.

#### Amend

```bash
mix rodar_release amend              # fold changes into release commit
mix rodar_release amend --dry-run    # preview amend
```

Amends the last release commit with any current changes and re-tags. Useful for fixing a typo or adding a missing file right after releasing.

### Options

| Option      | Applies to          | Description                              |
|-------------|---------------------|------------------------------------------|
| `--dry-run` | all commands        | Preview changes without applying them    |
| `--publish` | patch, minor, major | Publish to Hex after tagging              |
| `--hard`    | rollback            | Discard release changes entirely         |

### Programmatic API

```elixir
RodarRelease.read_version()
#=> "0.1.0"

RodarRelease.bump("1.2.3", :minor)
#=> "1.3.0"

RodarRelease.write_version("1.3.0")
```

