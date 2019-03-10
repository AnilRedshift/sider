defmodule Sider.Cache do
  @moduledoc false

  use Agent

  def start_link(opts \\ []) do
    Agent.start_link(
      fn ->
        :ets.new(:sider_cache, [:set, :private])
      end,
      opts
    )
  end

  def get(pid, key) do
    Agent.get(pid, fn tab ->
      case :ets.lookup(tab, key) do
        [] -> {:error, :missing}
        [{^key, value}] -> {:ok, value}
      end
    end)
  end

  def set(pid, key, value) do
    Agent.get(pid, fn tab ->
      :ets.insert(tab, {key, value})
      nil
    end)
  end

  def remove(pid, key) do
    Agent.get(pid, fn tab ->
      :ets.delete(tab, key)
      nil
    end)
  end
end
