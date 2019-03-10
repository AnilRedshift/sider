defmodule SiderTest do
  use ExUnit.Case, async: true
  doctest Sider

  describe "non expiring keys" do
    test "Returns :missing_key when getting a non-existant key" do
      pid = start_sider()
      assert {:error, :missing_key} = Sider.get(pid, :wrong)
    end

    test "Does nothing when removing a non-existant key" do
      pid = start_sider()
      assert nil == Sider.remove(pid, :wrong)
    end

    test "sets and gets a key" do
      pid = start_sider()
      assert :ok == Sider.set(pid, :a, :foo)
      assert {:ok, :foo} = Sider.get(pid, :a)
    end

    test "overwrites a key" do
      pid = start_sider()
      assert :ok == Sider.set(pid, :a, :foo)
      assert :ok == Sider.set(pid, :a, :bar)
      assert {:ok, :bar} = Sider.get(pid, :a)
    end

    test "nothing happens after the reaper runs" do
      pid = start_sider()
      assert :ok == Sider.set(pid, :a, :foo)
      Process.sleep(110)
      assert {:ok, :foo} = Sider.get(pid, :a)
    end

    test "doesn't remove when passing only: :expired" do
      pid = start_sider()
      assert :ok == Sider.set(pid, :a, :foo)
      assert nil == Sider.remove(pid, :a, [only: :expired])
      assert {:ok, :foo} = Sider.get(pid, :a)
    end

    defp start_sider() do
      start_supervised!({Sider, %{reap_interval: 100, capacity: 2}})
    end
  end
end
