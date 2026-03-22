# Changelog

## [Unreleased]

### Added

- AI-generated changelog entries via Claude Code when `[Unreleased]` is empty or absent at release time
- Igniter integration for automatic project setup (`mix igniter.install rodar_release`)

### Removed

- `mix rodar_release.publish` task and `--publish` flag (use `mix hex.publish` directly)

## [1.1.0] - 2026-03-22

### Removed

- `mix rodar_release.publish` task and `--publish` option from release commands

### Added

- Semantic versioning documentation to README and module docs

## [1.0.3] - 2026-03-21

### Added

- `ex_doc` as a dev dependency for documentation generation

## [1.0.2] - 2026-03-21

### Changed

- Add maintainer info to package metadata

## [1.0.1] - 2026-03-21

### Added

- MIT license and Hex package metadata for publishing

## [1.0.0] - 2026-03-21

### Changed

- Refactored mix tasks to use idiomatic Elixir dot notation (e.g., `mix rodar_release.patch` instead of `mix rodar_release patch`)

## [0.2.1] - 2026-03-21

### Changed

- Consolidated `rollback` and `amend` into subcommands of the unified `mix rodar_release` task

## [0.2.0] - 2026-03-21

### Added

- `mix rodar_release rollback` command to undo the last release
- `mix rodar_release amend` command to fold changes into the last release commit

## [0.1.0] - 2026-03-11

### Added

- Mix task `mix rodar_release` for automated semantic version releases
- Version reading, writing, and bumping via `RodarRelease` module
- Changelog update support with ISO 8601 release dates
- Git commit and annotated tag creation
- `--dry-run` option to preview changes
