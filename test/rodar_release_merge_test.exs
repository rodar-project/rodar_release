defmodule Mix.Tasks.RodarRelease.MergeTest do
  use ExUnit.Case

  @test_dir "test_merge_repo"

  setup do
    File.rm_rf!(@test_dir)
    File.mkdir_p!(@test_dir)

    in_dir(fn ->
      git!(["init"])
      git!(["config", "user.email", "test@test.com"])
      git!(["config", "user.name", "Test"])
      git!(["checkout", "-b", "main"])

      File.write!("mix.exs", ~s|      version: "1.5.1-dev.3",\n      app: :test\n|)

      File.write!("CHANGELOG.md", """
      # Changelog

      ## [Unreleased]

      ### Added

      - Some feature

      ## [1.5.0] - 2026-01-01

      ### Added

      - Initial release
      """)

      git!(["add", "."])
      git!(["commit", "-m", "Initial commit"])
      git!(["tag", "-a", "v1.5.0", "-m", "Release v1.5.0"])
    end)

    on_exit(fn -> File.rm_rf!(@test_dir) end)
    :ok
  end

  describe "merge (no segment)" do
    test "promotes pre-release to base version" do
      in_dir(fn ->
        Mix.Tasks.RodarRelease.Merge.run([])

        assert File.read!("mix.exs") =~ ~s|version: "1.5.1"|

        {tags, 0} = System.cmd("git", ["tag"])
        assert tags =~ "v1.5.1"

        {log, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
        assert String.trim(log) == "release: v1.5.1"
      end)
    end
  end

  describe "merge patch" do
    test "promotes pre-release to next patch version" do
      in_dir(fn ->
        Mix.Tasks.RodarRelease.Merge.run(["patch"])

        assert File.read!("mix.exs") =~ ~s|version: "1.5.2"|

        {tags, 0} = System.cmd("git", ["tag"])
        assert tags =~ "v1.5.2"

        {log, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
        assert String.trim(log) == "release: v1.5.2"
      end)
    end
  end

  describe "merge minor" do
    test "promotes pre-release to next minor version" do
      in_dir(fn ->
        Mix.Tasks.RodarRelease.Merge.run(["minor"])

        assert File.read!("mix.exs") =~ ~s|version: "1.6.0"|

        {tags, 0} = System.cmd("git", ["tag"])
        assert tags =~ "v1.6.0"
      end)
    end
  end

  describe "merge major" do
    test "promotes pre-release to next major version" do
      in_dir(fn ->
        Mix.Tasks.RodarRelease.Merge.run(["major"])

        assert File.read!("mix.exs") =~ ~s|version: "2.0.0"|

        {tags, 0} = System.cmd("git", ["tag"])
        assert tags =~ "v2.0.0"
      end)
    end
  end

  describe "merge --dry-run" do
    test "shows plan without making changes" do
      in_dir(fn ->
        Mix.Tasks.RodarRelease.Merge.run(["patch", "--dry-run"])

        # Version should be unchanged
        assert File.read!("mix.exs") =~ ~s|version: "1.5.1-dev.3"|

        # No new tag
        {tags, 0} = System.cmd("git", ["tag"])
        refute tags =~ "v1.5.2"
      end)
    end
  end

  describe "merge validation" do
    test "raises when not on stable branch" do
      in_dir(fn ->
        git!(["checkout", "-b", "develop"])

        assert_raise Mix.Error, ~r/merge must be run from main or master/, fn ->
          Mix.Tasks.RodarRelease.Merge.run(["patch"])
        end
      end)
    end

    test "raises when version has no pre-release suffix" do
      in_dir(fn ->
        File.write!("mix.exs", ~s|      version: "1.5.0",\n      app: :test\n|)
        git!(["add", "mix.exs"])
        git!(["commit", "-m", "stable version"])

        assert_raise Mix.Error, ~r/is not a pre-release/, fn ->
          Mix.Tasks.RodarRelease.Merge.run(["patch"])
        end
      end)
    end

    test "raises when tag already exists" do
      in_dir(fn ->
        git!(["tag", "-a", "v1.5.2", "-m", "existing"])

        assert_raise Mix.Error, ~r/already exists/, fn ->
          Mix.Tasks.RodarRelease.Merge.run(["patch"])
        end
      end)
    end

    test "raises when invalid segment given" do
      in_dir(fn ->
        assert_raise Mix.Error, ~r/Invalid segment/, fn ->
          Mix.Tasks.RodarRelease.Merge.run(["hotfix"])
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
