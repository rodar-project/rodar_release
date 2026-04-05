defmodule Relex.TaggingTest do
  use ExUnit.Case

  import Relex.Helpers, only: [execute_release: 3]

  @test_dir "test_tagging_repo"

  setup do
    File.rm_rf!(@test_dir)
    File.mkdir_p!(@test_dir)

    in_dir(fn ->
      git!(["init"])
      git!(["config", "user.email", "test@test.com"])
      git!(["config", "user.name", "Test"])
      git!(["checkout", "-b", "develop"])

      File.write!("mix.exs", ~s|      version: "1.0.0",\n      app: :test\n|)

      File.write!("CHANGELOG.md", """
      # Changelog

      ## [Unreleased]

      ### Added

      - Some feature

      ## [1.0.0] - 2026-01-01

      ### Added

      - Initial release
      """)

      git!(["add", "."])
      git!(["commit", "-m", "Initial commit"])
    end)

    on_exit(fn -> File.rm_rf!(@test_dir) end)
    :ok
  end

  describe "pre-release tagging" do
    test "skips tag for pre-release version by default" do
      in_dir(fn ->
        execute_release("1.1.0-dev.1", "2026-03-31", [])

        {tags, 0} = System.cmd("git", ["tag"])
        refute tags =~ "v1.1.0-dev.1"

        {log, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
        assert String.trim(log) == "release: v1.1.0-dev.1"
      end)
    end

    test "creates tag for stable version by default" do
      in_dir(fn ->
        execute_release("1.1.0", "2026-03-31", [])

        {tags, 0} = System.cmd("git", ["tag"])
        assert tags =~ "v1.1.0"
      end)
    end
  end

  describe "--no-tag flag" do
    test "skips tag for stable version when no_tag is true" do
      in_dir(fn ->
        execute_release("1.1.0", "2026-03-31", no_tag: true)

        {tags, 0} = System.cmd("git", ["tag"])
        refute tags =~ "v1.1.0"

        {log, 0} = System.cmd("git", ["log", "-1", "--format=%s"])
        assert String.trim(log) == "release: v1.1.0"
      end)
    end

    test "skips tag for pre-release even without no_tag" do
      in_dir(fn ->
        execute_release("1.1.0-rc.1", "2026-03-31", [])

        {tags, 0} = System.cmd("git", ["tag"])
        refute tags =~ "v1.1.0-rc.1"
      end)
    end
  end

  describe "next steps message" do
    test "suggests pushing only the specific tag for stable releases" do
      in_dir(fn ->
        output = capture_shell(fn -> execute_release("1.1.0", "2026-03-31", []) end)

        assert output =~ "git push origin develop v1.1.0"
        refute output =~ "--tags"
      end)
    end

    test "suggests pushing without tag for pre-release" do
      in_dir(fn ->
        output = capture_shell(fn -> execute_release("1.1.0-dev.1", "2026-03-31", []) end)

        assert output =~ "  git push origin develop"
        refute output =~ "--tags"
      end)
    end

    test "suggests pushing without tag when no_tag is true" do
      in_dir(fn ->
        output = capture_shell(fn -> execute_release("1.1.0", "2026-03-31", no_tag: true) end)

        assert output =~ "  git push origin develop"
        refute output =~ "--tags"
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

  defp capture_shell(fun) do
    {:ok, agent} = Agent.start_link(fn -> [] end)

    Mix.shell(Mix.Shell.Process)

    try do
      fun.()

      receive_all_messages()
    after
      Mix.shell(Mix.Shell.IO)
      Agent.stop(agent)
    end
  end

  defp receive_all_messages(acc \\ []) do
    receive do
      {:mix_shell, :info, [msg]} -> receive_all_messages([msg | acc])
    after
      100 -> Enum.reverse(acc) |> Enum.join("\n")
    end
  end
end
