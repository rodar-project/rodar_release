# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **BREAKING:** Relex is now distributed as a mix archive instead of a hex dependency — install with `mix archive.install hex relex`
- **BREAKING:** Configuration moved from `config :relex` in `config.exs` to `.relex.exs` dotfile in project root
- `mix relex.install` (Igniter) replaced by `mix relex.init` (no dependencies required)
- Renamed project from `rodar_release` to `relex` — **Rel**ease + Eli**x**ir, a nod to keeping releases relaxed
- All modules renamed: `RodarRelease` → `Relex`, `RodarRelease.Helpers` → `Relex.Helpers`
- All mix tasks renamed: `mix rodar_release.*` → `mix relex.*`

### Added

- `Relex.Config` module for reading `.relex.exs` configuration files
- `mix relex.init` task to scaffold `CHANGELOG.md` and `.relex.exs` in new projects

### Removed

- Igniter integration and `mix relex.install` task
- `ex_doc` and `igniter` dependencies — relex now has zero dependencies
- Hex package metadata

### Fixed

- Tagging tests no longer rely on trailing newline in captured shell output

## [1.6.0-dev.1] - 2026-03-30

### Added

- `mix relex.merge` task to promote pre-release versions after merging into a stable branch
- `Relex.promote/2` to strip or bump a pre-release version to stable
- `Relex.has_pre?/1` to check if a version has a pre-release suffix
- Tag existence check before releasing to prevent version collisions
- Auto-detection of leftover pre-release suffix on stable branches, guiding users to `merge`
- `--no-tag` flag for all release commands to skip git tag creation
- Pre-release versions now skip tagging by default to avoid polluting the tags list

### Changed

- "Next steps" push suggestion now uses specific tag name (`git push origin <branch> v1.2.0`) instead of `--tags`, preventing accidental push of unrelated local tags
- Pre-release releases no longer include a tag reference in the push suggestion

### Fixed

- Documentation warning referencing hidden `resolve_pre/2` helper

## [1.5.0] - 2026-03-30

### Added

- Automatic branch-to-suffix mapping: `develop` → `-dev`, `release/*` → `-rc`, `beta/*` → `-beta`, `alpha/*` → `-alpha`
- Block `--pre` on `main`/`master` — release candidates must use their own branch
- Block releases from unmapped branches (feature branches, etc.)
- Configurable branch mappings via `:branch_pre` in `config.exs`
- Branch name displayed in release plan output

## [1.4.0] - 2026-03-30

### Added

- Pre-release version suffixes via `--pre` flag (e.g., `mix relex.minor --pre rc` produces `1.2.0-rc.1`)
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

- Recommend [relex-project/relex_skills](https://github.com/relex-project/relex_skills) changelog skill in README for AI-assisted dev tools
- Suggest installing the changelog skill via `npx skills` after Igniter setup

### Changed

- Gitignore Claude Code and agent skills artifacts (`.claude/`, `.agents/`, `skills-lock.json`)

## [1.2.0] - 2026-03-22

### Added

- AI-generated changelog entries via Claude Code when `[Unreleased]` is empty or absent at release time
- Igniter integration for automatic project setup (`mix igniter.install relex`)

### Removed

- `mix relex.publish` task and `--publish` flag (use `mix hex.publish` directly)

## [1.1.0] - 2026-03-22

### Removed

- `mix relex.publish` task and `--publish` option from release commands

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

- Refactored mix tasks to use idiomatic Elixir dot notation (e.g., `mix relex.patch` instead of `mix relex patch`)

## [0.2.1] - 2026-03-21

### Changed

- Consolidated `rollback` and `amend` into subcommands of the unified `mix relex` task

## [0.2.0] - 2026-03-21

### Added

- `mix relex rollback` command to undo the last release
- `mix relex amend` command to fold changes into the last release commit

## [0.1.0] - 2026-03-11

### Added

- Mix task `mix relex` for automated semantic version releases
- Version reading, writing, and bumping via `Relex` module
- Changelog update support with ISO 8601 release dates
- Git commit and annotated tag creation
- `--dry-run` option to preview changes

[Unreleased]: https://github.com/relex-project/relex/compare/v1.6.0...HEAD
[1.6.0]: https://github.com/relex-project/relex/compare/v1.6.0-dev.1...v1.6.0
[1.6.0-dev.1]: https://github.com/relex-project/relex/compare/v1.5.0...v1.6.0-dev.1
[1.5.0]: https://github.com/relex-project/relex/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/relex-project/relex/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/relex-project/relex/compare/v1.2.3...v1.3.0
[1.2.3]: https://github.com/relex-project/relex/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/relex-project/relex/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/relex-project/relex/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/relex-project/relex/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/relex-project/relex/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/relex-project/relex/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/relex-project/relex/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/relex-project/relex/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/relex-project/relex/compare/v0.2.1...v1.0.0
[0.2.1]: https://github.com/relex-project/relex/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/relex-project/relex/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/relex-project/relex/releases/tag/v0.1.0
