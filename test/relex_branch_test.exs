defmodule RelexBranchTest do
  use ExUnit.Case

  import Relex.Helpers, only: [resolve_pre: 2]

  describe "resolve_pre/2 on main/master" do
    test "main without --pre returns stable" do
      assert resolve_pre("main", nil) == {:ok, nil}
    end

    test "master without --pre returns stable" do
      assert resolve_pre("master", nil) == {:ok, nil}
    end

    test "main with --pre is rejected" do
      assert {:error, msg} = resolve_pre("main", "rc")
      assert msg =~ "Cannot use --pre on main"
    end

    test "master with --pre is rejected" do
      assert {:error, msg} = resolve_pre("master", "beta")
      assert msg =~ "Cannot use --pre on master"
    end
  end

  describe "resolve_pre/2 on develop branches" do
    test "develop auto-infers dev suffix" do
      assert resolve_pre("develop", nil) == {:ok, "dev"}
    end

    test "dev auto-infers dev suffix" do
      assert resolve_pre("dev", nil) == {:ok, "dev"}
    end

    test "develop with explicit --pre overrides" do
      assert resolve_pre("develop", "beta") == {:ok, "beta"}
    end
  end

  describe "resolve_pre/2 on release branches" do
    test "release/* auto-infers rc suffix" do
      assert resolve_pre("release/1.2.0", nil) == {:ok, "rc"}
    end

    test "rc/* auto-infers rc suffix" do
      assert resolve_pre("rc/1.2.0", nil) == {:ok, "rc"}
    end

    test "release/* with explicit --pre overrides" do
      assert resolve_pre("release/1.2.0", "beta") == {:ok, "beta"}
    end
  end

  describe "resolve_pre/2 on beta/alpha branches" do
    test "beta/* auto-infers beta suffix" do
      assert resolve_pre("beta/new-feature", nil) == {:ok, "beta"}
    end

    test "alpha/* auto-infers alpha suffix" do
      assert resolve_pre("alpha/experiment", nil) == {:ok, "alpha"}
    end
  end

  describe "resolve_pre/2 on unmapped branches" do
    test "feature branch is blocked" do
      assert {:error, msg} = resolve_pre("feature/my-thing", nil)
      assert msg =~ "Releases are not allowed from branch"
    end

    test "arbitrary branch is blocked" do
      assert {:error, msg} = resolve_pre("fix/bug-123", nil)
      assert msg =~ "Releases are not allowed from branch"
    end

    test "unmapped branch with --pre is still blocked" do
      assert {:error, msg} = resolve_pre("feature/my-thing", "dev")
      assert msg =~ "Releases are not allowed from branch"
    end
  end

  describe "resolve_pre/2 with custom config" do
    setup do
      on_exit(fn -> Relex.Config.reset() end)
    end

    test "custom exact branch mapping" do
      Relex.Config.put(:branch_pre, %{"staging" => "rc"})
      assert resolve_pre("staging", nil) == {:ok, "rc"}
    end

    test "custom pattern mapping" do
      Relex.Config.put(:branch_pre, %{~r/^preview\// => "beta"})
      assert resolve_pre("preview/v2", nil) == {:ok, "beta"}
    end

    test "custom mapping overrides default" do
      Relex.Config.put(:branch_pre, %{"develop" => "snapshot"})
      assert resolve_pre("develop", nil) == {:ok, "snapshot"}
    end
  end
end
