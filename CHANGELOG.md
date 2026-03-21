# Changelog

## [Unreleased]

## [0.2.1] - 2026-03-21

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
- `--publish` option for Hex publishing
