defmodule RodarReleaseTest do
  use ExUnit.Case
  doctest RodarRelease

  describe "read_version/1" do
    test "reads version from mix.exs format" do
      File.write!("test_mix.exs", ~s|version: "1.2.3",\n|)
      assert RodarRelease.read_version(file: "test_mix.exs") == "1.2.3"
    after
      File.rm("test_mix.exs")
    end

    test "reads version with extra whitespace" do
      File.write!("test_mix.exs", ~s|version:  "2.0.0",\n|)
      assert RodarRelease.read_version(file: "test_mix.exs") == "2.0.0"
    after
      File.rm("test_mix.exs")
    end

    test "raises when file does not exist" do
      assert_raise RuntimeError, ~r/Could not read/, fn ->
        RodarRelease.read_version(file: "nonexistent")
      end
    end

    test "raises when no version found" do
      File.write!("test_mix.exs", "no version here\n")

      assert_raise RuntimeError, ~r/Could not find version/, fn ->
        RodarRelease.read_version(file: "test_mix.exs")
      end
    after
      File.rm("test_mix.exs")
    end
  end

  describe "write_version/2" do
    test "replaces version in mix.exs format" do
      File.write!("test_mix.exs", ~s|      version: "1.0.0",\n      app: :foo\n|)
      RodarRelease.write_version("1.1.0", file: "test_mix.exs")
      assert File.read!("test_mix.exs") == ~s|      version: "1.1.0",\n      app: :foo\n|
    after
      File.rm("test_mix.exs")
    end

    test "only replaces first occurrence" do
      content = ~s|version: "1.0.0",\ndeps: [{:foo, version: "2.0.0"}]\n|
      File.write!("test_mix.exs", content)
      RodarRelease.write_version("1.1.0", file: "test_mix.exs")
      result = File.read!("test_mix.exs")
      assert result =~ ~s|version: "1.1.0"|
      assert result =~ ~s|version: "2.0.0"|
    after
      File.rm("test_mix.exs")
    end
  end

  describe "bump/2" do
    test "bumps patch" do
      assert RodarRelease.bump("1.0.8", :patch) == "1.0.9"
    end

    test "bumps minor" do
      assert RodarRelease.bump("1.0.8", :minor) == "1.1.0"
    end

    test "bumps major" do
      assert RodarRelease.bump("1.0.8", :major) == "2.0.0"
    end

    test "bumps from zero" do
      assert RodarRelease.bump("0.0.0", :patch) == "0.0.1"
      assert RodarRelease.bump("0.0.0", :minor) == "0.1.0"
      assert RodarRelease.bump("0.0.0", :major) == "1.0.0"
    end
  end

  describe "bump/3 with pre-release" do
    test "stable + --pre creates pre-release" do
      assert RodarRelease.bump("1.1.0", :minor, "rc") == "1.2.0-rc.1"
      assert RodarRelease.bump("1.0.8", :patch, "beta") == "1.0.9-beta.1"
      assert RodarRelease.bump("1.0.8", :major, "dev") == "2.0.0-dev.1"
    end

    test "pre-release + same label increments counter" do
      assert RodarRelease.bump("1.2.0-rc.1", :patch, "rc") == "1.2.0-rc.2"
      assert RodarRelease.bump("1.2.0-rc.5", :minor, "rc") == "1.2.0-rc.6"
    end

    test "pre-release + different label switches label" do
      assert RodarRelease.bump("1.2.0-dev.1", :patch, "rc") == "1.2.0-rc.1"
      assert RodarRelease.bump("1.2.0-rc.3", :patch, "beta") == "1.2.0-beta.1"
    end

    test "pre-release + no pre promotes to stable" do
      assert RodarRelease.bump("1.2.0-rc.2", :patch) == "1.2.0"
      assert RodarRelease.bump("1.2.0-rc.2", :minor) == "1.2.0"
      assert RodarRelease.bump("1.2.0-rc.2", :major) == "1.2.0"
    end

    test "stable + nil pre is normal bump" do
      assert RodarRelease.bump("1.1.0", :minor, nil) == "1.2.0"
    end

    test "raises on invalid pre-release label" do
      assert_raise ArgumentError, ~r/Invalid pre-release label/, fn ->
        RodarRelease.bump("1.0.0", :patch, "123")
      end

      assert_raise ArgumentError, ~r/Invalid pre-release label/, fn ->
        RodarRelease.bump("1.0.0", :patch, "")
      end
    end
  end

  describe "read_version/1 with pre-release" do
    test "reads pre-release version" do
      File.write!("test_mix.exs", ~s|version: "1.2.0-rc.1",\n|)
      assert RodarRelease.read_version(file: "test_mix.exs") == "1.2.0-rc.1"
    after
      File.rm("test_mix.exs")
    end
  end

  describe "write_version/2 with pre-release" do
    test "replaces stable with pre-release version" do
      File.write!("test_mix.exs", ~s|      version: "1.2.0",\n      app: :foo\n|)
      RodarRelease.write_version("1.2.0-rc.1", file: "test_mix.exs")
      assert File.read!("test_mix.exs") == ~s|      version: "1.2.0-rc.1",\n      app: :foo\n|
    after
      File.rm("test_mix.exs")
    end

    test "replaces pre-release with stable version" do
      File.write!("test_mix.exs", ~s|      version: "1.2.0-rc.2",\n      app: :foo\n|)
      RodarRelease.write_version("1.2.0", file: "test_mix.exs")
      assert File.read!("test_mix.exs") == ~s|      version: "1.2.0",\n      app: :foo\n|
    after
      File.rm("test_mix.exs")
    end
  end
end
