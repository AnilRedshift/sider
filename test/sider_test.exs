defmodule SiderTest do
  use ExUnit.Case
  doctest Sider

  describe "non expiring keys" do
    test "Returns :missing_key when getting a non-existant key" do
      pid = start_supervised!({Sider, %{reap_interval: 1000, capacity: 2}})
      assert {:error, :missing_key} = Sider.get(pid, :wrong)
    end
  end
end
