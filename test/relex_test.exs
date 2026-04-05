defmodule RelexTest do
  use ExUnit.Case
  doctest Relex

  describe "read_version/1" do
    test "reads version from mix.exs format" do
      File.write!("test_mix.exs", ~s|version: "1.2.3",\n|)
      assert Relex.read_version(file: "test_mix.exs") == "1.2.3"
    after
      File.rm("test_mix.exs")
    end

    test "reads version with extra whitespace" do
      File.write!("test_mix.exs", ~s|version:  "2.0.0",\n|)
      assert Relex.read_version(file: "test_mix.exs") == "2.0.0"
    after
      File.rm("test_mix.exs")
    end

    test "raises when file does not exist" do
      assert_raise RuntimeError, ~r/Could not read/, fn ->
        Relex.read_version(file: "nonexistent")
      end
    end

    test "raises when no version found" do
      File.write!("test_mix.exs", "no version here\n")

      assert_raise RuntimeError, ~r/Could not find version/, fn ->
        Relex.read_version(file: "test_mix.exs")
      end
    after
      File.rm("test_mix.exs")
    end
  end

  describe "write_version/2" do
    test "replaces version in mix.exs format" do
      File.write!("test_mix.exs", ~s|      version: "1.0.0",\n      app: :foo\n|)
      Relex.write_version("1.1.0", file: "test_mix.exs")
      assert File.read!("test_mix.exs") == ~s|      version: "1.1.0",\n      app: :foo\n|
    after
      File.rm("test_mix.exs")
    end

    test "only replaces first occurrence" do
      content = ~s|version: "1.0.0",\ndeps: [{:foo, version: "2.0.0"}]\n|
      File.write!("test_mix.exs", content)
      Relex.write_version("1.1.0", file: "test_mix.exs")
      result = File.read!("test_mix.exs")
      assert result =~ ~s|version: "1.1.0"|
      assert result =~ ~s|version: "2.0.0"|
    after
      File.rm("test_mix.exs")
    end
  end

  describe "bump/2" do
    test "bumps patch" do
      assert Relex.bump("1.0.8", :patch) == "1.0.9"
    end

    test "bumps minor" do
      assert Relex.bump("1.0.8", :minor) == "1.1.0"
    end

    test "bumps major" do
      assert Relex.bump("1.0.8", :major) == "2.0.0"
    end

    test "bumps from zero" do
      assert Relex.bump("0.0.0", :patch) == "0.0.1"
      assert Relex.bump("0.0.0", :minor) == "0.1.0"
      assert Relex.bump("0.0.0", :major) == "1.0.0"
    end
  end

  describe "bump/3 with pre-release" do
    test "stable + --pre creates pre-release" do
      assert Relex.bump("1.1.0", :minor, "rc") == "1.2.0-rc.1"
      assert Relex.bump("1.0.8", :patch, "beta") == "1.0.9-beta.1"
      assert Relex.bump("1.0.8", :major, "dev") == "2.0.0-dev.1"
    end

    test "pre-release + same label increments counter" do
      assert Relex.bump("1.2.0-rc.1", :patch, "rc") == "1.2.0-rc.2"
      assert Relex.bump("1.2.0-rc.5", :minor, "rc") == "1.2.0-rc.6"
    end

    test "pre-release + different label switches label" do
      assert Relex.bump("1.2.0-dev.1", :patch, "rc") == "1.2.0-rc.1"
      assert Relex.bump("1.2.0-rc.3", :patch, "beta") == "1.2.0-beta.1"
    end

    test "pre-release + no pre promotes to stable" do
      assert Relex.bump("1.2.0-rc.2", :patch) == "1.2.0"
      assert Relex.bump("1.2.0-rc.2", :minor) == "1.2.0"
      assert Relex.bump("1.2.0-rc.2", :major) == "1.2.0"
    end

    test "stable + nil pre is normal bump" do
      assert Relex.bump("1.1.0", :minor, nil) == "1.2.0"
    end

    test "raises on invalid pre-release label" do
      assert_raise ArgumentError, ~r/Invalid pre-release label/, fn ->
        Relex.bump("1.0.0", :patch, "123")
      end

      assert_raise ArgumentError, ~r/Invalid pre-release label/, fn ->
        Relex.bump("1.0.0", :patch, "")
      end
    end
  end

  describe "has_pre?/1" do
    test "returns true for pre-release version" do
      assert Relex.has_pre?("1.0.0-rc.1")
      assert Relex.has_pre?("2.3.0-dev.5")
    end

    test "returns false for stable version" do
      refute Relex.has_pre?("1.0.0")
      refute Relex.has_pre?("0.1.0")
    end
  end

  describe "promote/1" do
    test "strips pre-release suffix" do
      assert Relex.promote("1.5.1-dev.3") == "1.5.1"
    end

    test "works with rc suffix" do
      assert Relex.promote("2.0.0-rc.5") == "2.0.0"
    end

    test "raises on stable version" do
      assert_raise ArgumentError, ~r/expects a pre-release version/, fn ->
        Relex.promote("1.0.0")
      end
    end
  end

  describe "promote/2" do
    test "patch bumps the base version" do
      assert Relex.promote("1.5.1-dev.3", :patch) == "1.5.2"
    end

    test "minor bumps the base version" do
      assert Relex.promote("1.5.1-dev.3", :minor) == "1.6.0"
    end

    test "major bumps the base version" do
      assert Relex.promote("1.5.1-dev.3", :major) == "2.0.0"
    end

    test "works with zero-based versions" do
      assert Relex.promote("0.1.0-dev.1", :minor) == "0.2.0"
    end

    test "raises on stable version" do
      assert_raise ArgumentError, ~r/expects a pre-release version/, fn ->
        Relex.promote("1.0.0", :patch)
      end
    end
  end

  describe "read_version/1 with pre-release" do
    test "reads pre-release version" do
      File.write!("test_mix.exs", ~s|version: "1.2.0-rc.1",\n|)
      assert Relex.read_version(file: "test_mix.exs") == "1.2.0-rc.1"
    after
      File.rm("test_mix.exs")
    end
  end

  describe "write_version/2 with pre-release" do
    test "replaces stable with pre-release version" do
      File.write!("test_mix.exs", ~s|      version: "1.2.0",\n      app: :foo\n|)
      Relex.write_version("1.2.0-rc.1", file: "test_mix.exs")
      assert File.read!("test_mix.exs") == ~s|      version: "1.2.0-rc.1",\n      app: :foo\n|
    after
      File.rm("test_mix.exs")
    end

    test "replaces pre-release with stable version" do
      File.write!("test_mix.exs", ~s|      version: "1.2.0-rc.2",\n      app: :foo\n|)
      Relex.write_version("1.2.0", file: "test_mix.exs")
      assert File.read!("test_mix.exs") == ~s|      version: "1.2.0",\n      app: :foo\n|
    after
      File.rm("test_mix.exs")
    end
  end
end
