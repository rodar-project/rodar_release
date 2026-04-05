defmodule Mix.Tasks.Relex.RollbackTest do
  use ExUnit.Case

  @test_dir "test_rollback_repo"

  setup do
    File.rm_rf!(@test_dir)
    File.mkdir_p!(@test_dir)

    # Initialize a git repo with a mix.exs and CHANGELOG
    in_dir(fn ->
      git!(["init"])
      git!(["config", "user.email", "test@test.com"])
      git!(["config", "user.name", "Test"])

      File.write!("mix.exs", ~s|      version: "0.1.0",\n      app: :test\n|)

      File.write!("CHANGELOG.md", """
      # Changelog

      ## [Unreleased]

      ## [0.1.0] - 2026-01-01

      ### Added

      - Initial release
      """)

      git!(["add", "."])
      git!(["commit", "-m", "Initial commit"])

      # Now simulate a release to 0.2.0
      File.write!("mix.exs", ~s|      version: "0.2.0",\n      app: :test\n|)

      File.write!("CHANGELOG.md", """
      # Changelog

      ## [Unreleased]

      ## [0.2.0] - 2026-03-20

      ## [0.1.0] - 2026-01-01

      ### Added

      - Initial release
      """)

      git!(["add", "."])
      git!(["commit", "-m", "release: v0.2.0"])
      git!(["tag", "-a", "v0.2.0", "-m", "Release v0.2.0"])
    end)

    on_exit(fn -> File.rm_rf!(@test_dir) end)
    :ok
  end

  describe "rollback --dry-run" do
    test "shows what would happen without making changes" do
      in_dir(fn ->
        Mix.Tasks.Relex.Rollback.run(["--dry-run"])

        # Tag and commit should still exist
        {tags, 0} = System.cmd("git", ["tag"])
        assert tags =~ "v0.2.0"

        {log, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
        assert String.trim(log) == "release: v0.2.0"
      end)
    end
  end

  describe "rollback (soft)" do
    test "removes tag and resets commit, restores files" do
      in_dir(fn ->
        Mix.Tasks.Relex.Rollback.run([])

        # Tag should be gone
        {tags, 0} = System.cmd("git", ["tag"])
        refute tags =~ "v0.2.0"

        # Latest commit should be the initial one
        {log, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
        assert String.trim(log) == "Initial commit"

        # mix.exs should be restored to pre-release version
        assert File.read!("mix.exs") =~ ~s|version: "0.1.0"|
      end)
    end
  end

  describe "rollback --hard" do
    test "removes tag and discards all release changes" do
      in_dir(fn ->
        Mix.Tasks.Relex.Rollback.run(["--hard"])

        # Tag should be gone
        {tags, 0} = System.cmd("git", ["tag"])
        refute tags =~ "v0.2.0"

        # Latest commit should be the initial one
        {log, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
        assert String.trim(log) == "Initial commit"

        # Working tree should be clean with old version
        assert File.read!("mix.exs") =~ ~s|version: "0.1.0"|
      end)
    end
  end

  describe "rollback validation" do
    test "raises when latest commit is not a release" do
      in_dir(fn ->
        File.write!("dummy.txt", "hello")
        git!(["add", "dummy.txt"])
        git!(["commit", "-m", "not a release"])

        assert_raise Mix.Error, ~r/Latest commit is not a release commit/, fn ->
          Mix.Tasks.Relex.Rollback.run([])
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
