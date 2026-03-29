defmodule RodarReleaseChangelogTest do
  use ExUnit.Case

  import RodarRelease.Helpers, only: [update_changelog: 2]

  @changelog_file "CHANGELOG.md"

  setup do
    original = File.read(@changelog_file)

    on_exit(fn ->
      case original do
        {:ok, content} -> File.write!(@changelog_file, content)
        {:error, _} -> File.rm(@changelog_file)
      end
    end)
  end

  describe "update_changelog/2 comparison links" do
    test "updates [Unreleased] link and inserts new version link" do
      File.write!(@changelog_file, """
      # Changelog

      ## [Unreleased]

      ### Added

      - New feature

      ## [1.0.0] - 2026-03-01

      ### Added

      - Initial release

      [Unreleased]: https://github.com/rodar-project/rodar_release/compare/v1.0.0...HEAD
      [1.0.0]: https://github.com/rodar-project/rodar_release/releases/tag/v1.0.0
      """)

      update_changelog("1.1.0", "2026-03-29")

      result = File.read!(@changelog_file)

      assert result =~
               "[Unreleased]: https://github.com/rodar-project/rodar_release/compare/v1.1.0...HEAD"

      assert result =~
               "[1.1.0]: https://github.com/rodar-project/rodar_release/compare/v1.0.0...v1.1.0"

      assert result =~
               "[1.0.0]: https://github.com/rodar-project/rodar_release/releases/tag/v1.0.0"
    end

    test "handles consecutive releases correctly" do
      File.write!(@changelog_file, """
      # Changelog

      ## [Unreleased]

      ### Fixed

      - Bug fix

      ## [1.1.0] - 2026-03-29

      ### Added

      - Feature

      ## [1.0.0] - 2026-03-01

      ### Added

      - Initial release

      [Unreleased]: https://github.com/rodar-project/rodar_release/compare/v1.1.0...HEAD
      [1.1.0]: https://github.com/rodar-project/rodar_release/compare/v1.0.0...v1.1.0
      [1.0.0]: https://github.com/rodar-project/rodar_release/releases/tag/v1.0.0
      """)

      update_changelog("1.1.1", "2026-03-30")

      result = File.read!(@changelog_file)

      assert result =~
               "[Unreleased]: https://github.com/rodar-project/rodar_release/compare/v1.1.1...HEAD"

      assert result =~
               "[1.1.1]: https://github.com/rodar-project/rodar_release/compare/v1.1.0...v1.1.1"

      assert result =~
               "[1.1.0]: https://github.com/rodar-project/rodar_release/compare/v1.0.0...v1.1.0"
    end

    test "preserves changelog without comparison links" do
      File.write!(@changelog_file, """
      # Changelog

      ## [Unreleased]

      ### Added

      - Something new

      ## [1.0.0] - 2026-03-01

      ### Added

      - Initial release
      """)

      update_changelog("1.1.0", "2026-03-29")

      result = File.read!(@changelog_file)

      assert result =~ "## [1.1.0] - 2026-03-29"
      refute result =~ "[Unreleased]:"
    end
  end
end
