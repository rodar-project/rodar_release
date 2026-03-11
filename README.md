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

Run the mix task to create a release:

```bash
mix rodar_release <patch|minor|major> [--dry-run] [--publish]
```

### Options

- `patch` / `minor` / `major` - Semantic version bump type
- `--dry-run` - Preview changes without applying them
- `--publish` - Publish to Hex after tagging

### What it does

1. Validates the git working directory is clean
2. Bumps the version in `mix.exs`
3. Updates `CHANGELOG.md` with the release date
4. Commits changes with message `release: vX.Y.Z`
5. Creates an annotated git tag `vX.Y.Z`
6. Optionally publishes to Hex

### Programmatic API

```elixir
# Read current version from mix.exs
RodarRelease.read_version("path/to/mix.exs")
#=> {:ok, "0.1.0"}

# Bump version
RodarRelease.bump("1.2.3", :minor)
#=> {:ok, "1.3.0"}

# Write new version to mix.exs
RodarRelease.write_version("path/to/mix.exs", "1.3.0")
#=> :ok
```

