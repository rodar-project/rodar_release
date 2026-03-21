defmodule Mix.Tasks.RodarRelease.AmendTest do
  use ExUnit.Case

  @test_dir "test_amend_repo"

  setup do
    File.rm_rf!(@test_dir)
    File.mkdir_p!(@test_dir)

    in_dir(fn ->
      git!(["init"])
      git!(["config", "user.email", "test@test.com"])
      git!(["config", "user.name", "Test"])

      File.write!("mix.exs", ~s|      version: "1.0.0",\n      app: :test\n|)
      File.write!("CHANGELOG.md", "# Changelog\n\n## [Unreleased]\n")

      git!(["add", "."])
      git!(["commit", "-m", "Initial commit"])

      # Simulate a release
      File.write!("mix.exs", ~s|      version: "1.1.0",\n      app: :test\n|)

      File.write!("CHANGELOG.md", """
      # Changelog

      ## [Unreleased]

      ## [1.1.0] - 2026-03-20

      ### Added

      - New feature
      """)

      git!(["add", "."])
      git!(["commit", "-m", "release: v1.1.0"])
      git!(["tag", "-a", "v1.1.0", "-m", "Release v1.1.0"])
    end)

    on_exit(fn -> File.rm_rf!(@test_dir) end)
    :ok
  end

  describe "amend" do
    test "amends release commit and re-tags" do
      in_dir(fn ->
        # Make a change to fold in
        File.write!("fix.txt", "hotfix content")

        {original_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"])

        Mix.Tasks.RodarRelease.run(["amend"])

        # Commit message should be unchanged
        {log, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
        assert String.trim(log) == "release: v1.1.0"

        # SHA should have changed (it was amended)
        {new_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"])
        assert String.trim(new_sha) != String.trim(original_sha)

        # The new file should be in the commit
        {show, 0} = System.cmd("git", ["show", "--stat", "--format="])
        assert show =~ "fix.txt"

        # Tag should point to new commit
        {tag_sha, 0} = System.cmd("git", ["rev-list", "-1", "v1.1.0"])
        assert String.trim(tag_sha) == String.trim(new_sha)
      end)
    end

    test "dry-run shows plan without changes" do
      in_dir(fn ->
        File.write!("fix.txt", "hotfix content")

        {original_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"])

        Mix.Tasks.RodarRelease.run(["amend", "--dry-run"])

        # SHA should NOT have changed
        {new_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"])
        assert String.trim(new_sha) == String.trim(original_sha)
      end)
    end
  end

  describe "amend validation" do
    test "raises when latest commit is not a release" do
      in_dir(fn ->
        File.write!("dummy.txt", "hello")
        git!(["add", "dummy.txt"])
        git!(["commit", "-m", "not a release"])

        assert_raise Mix.Error, ~r/Latest commit is not a release commit/, fn ->
          Mix.Tasks.RodarRelease.run(["amend"])
        end
      end)
    end

    test "raises when working tree is clean" do
      in_dir(fn ->
        assert_raise Mix.Error, ~r/No changes to amend/, fn ->
          Mix.Tasks.RodarRelease.run(["amend"])
        end
      end)
    end
  end

  defp in_dir(fun) do
    original = File.cwd!()
    File.cd!(@test_dir)

    try do
      fun.()
    after
      File.cd!(original)
    end
  end

  defp git!(args) do
    case System.cmd("git", args, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, code} -> raise "git #{inspect(args)} failed (#{code}): #{output}"
    end
  end
end
