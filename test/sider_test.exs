defmodule SiderTest do
  use ExUnit.Case, async: true
  doctest Sider

  setup do
    pid = start_supervised!({Sider, %{reap_interval: 50, capacity: 2}})
    {:ok, %{pid: pid}}
  end

  describe "non expiring keys" do
    test "Returns :missing_key when getting a non-existant key", %{pid: pid} do
      assert {:error, :missing_key} = Sider.get(pid, :wrong)
    end

    test "Does nothing when removing a non-existant key", %{pid: pid} do
      assert nil == Sider.remove(pid, :wrong)
    end

    test "sets and gets a key", %{pid: pid} do
      assert :ok == Sider.set(pid, :a, :foo)
      assert {:ok, :foo} = Sider.get(pid, :a)
    end

    test "overwrites a key", %{pid: pid} do
      assert :ok == Sider.set(pid, :a, :foo)
      assert :ok == Sider.set(pid, :a, :bar)
      assert {:ok, :bar} = Sider.get(pid, :a)
    end

    test "nothing happens after the reaper runs", %{pid: pid} do
      assert :ok == Sider.set(pid, :a, :foo)
      Process.sleep(60)
      assert {:ok, :foo} = Sider.get(pid, :a)
    end

    test "doesn't remove when passing only: :expired", %{pid: pid} do
      assert :ok == Sider.set(pid, :a, :foo)
      assert nil == Sider.remove(pid, :a, only: :expired)
      assert {:ok, :foo} = Sider.get(pid, :a)
    end

    test "Removes a key normally", %{pid: pid} do
      assert :ok == Sider.set(pid, :a, :foo)
      assert nil == Sider.remove(pid, :a)
      assert {:error, :missing_key} = Sider.get(pid, :a)
    end
  end

  describe "expiring keys" do
    test "write over an expiring key", %{pid: pid} do
      assert :ok == Sider.set(pid, :a, :foo, 10)
      assert :ok == Sider.set(pid, :a, :bar, 80)
      assert {:ok, :bar} = Sider.get(pid, :a)
      Process.sleep(30)
      assert {:ok, :bar} = Sider.get(pid, :a)
      Process.sleep(100)
      assert {:error, :missing_key} = Sider.get(pid, :a)
    end

    test "write over an expiring key with a non-expiring one", %{pid: pid} do
      assert :ok == Sider.set(pid, :a, :foo, 10)
      assert :ok == Sider.set(pid, :a, :bar)
      assert {:ok, :bar} = Sider.get(pid, :a)
      Process.sleep(60)
      assert {:ok, :bar} = Sider.get(pid, :a)
    end

    test "reap multiple keys", %{pid: pid} do
      assert :ok == Sider.set(pid, :a, :foo, 10)
      assert :ok == Sider.set(pid, :b, :foo, 10)
      Process.sleep(5)
      assert {:error, :max_capacity} == Sider.set(pid, :c, :foo, 10)
      Process.sleep(50)
      assert :ok == Sider.set(pid, :c, :foo, 10)
      assert :ok == Sider.set(pid, :d, :foo, 10)
      assert {:error, :max_capacity} == Sider.set(pid, :e, :foo, 10)
      assert :ok == Sider.set(pid, :c, :bar, 10)
    end
  end
end
