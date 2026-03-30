# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Pre-release version suffixes via `--pre` flag (e.g., `mix rodar_release.minor --pre rc` produces `1.2.0-rc.1`)
- Support for incrementing pre-release counters, switching labels, and promoting to stable
- Pre-release version validation (alphanumeric labels starting with a letter)

## [1.3.0] - 2026-03-29

### Added

- Automatic update of comparison links at the bottom of `CHANGELOG.md` during releases

## [1.2.2] - 2026-03-22

### Changed

- Add manual setup instructions for projects not using Igniter
- Replace ollama example with codex in AI CLI documentation
- Rename `gh-copilot` AI preset to `gh`

## [1.2.1] - 2026-03-22

### Added

- Recommend [rodar-project/rodar_skills](https://github.com/rodar-project/rodar_skills) changelog skill in README for AI-assisted dev tools
- Suggest installing the changelog skill via `npx skills` after Igniter setup

### Changed

- Gitignore Claude Code and agent skills artifacts (`.claude/`, `.agents/`, `skills-lock.json`)

## [1.2.0] - 2026-03-22

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

[Unreleased]: https://github.com/rodar-project/rodar_release/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/rodar-project/rodar_release/compare/v1.2.3...v1.3.0
[1.2.3]: https://github.com/rodar-project/rodar_release/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/rodar-project/rodar_release/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/rodar-project/rodar_release/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/rodar-project/rodar_release/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/rodar-project/rodar_release/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/rodar-project/rodar_release/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/rodar-project/rodar_release/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/rodar-project/rodar_release/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/rodar-project/rodar_release/compare/v0.2.1...v1.0.0
[0.2.1]: https://github.com/rodar-project/rodar_release/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/rodar-project/rodar_release/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/rodar-project/rodar_release/releases/tag/v0.1.0
