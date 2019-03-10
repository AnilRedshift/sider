defmodule Sider.Cache do
  @moduledoc false

  use Agent

  def start_link(opts \\ []) do
    Agent.start_link(
      fn ->
        tab = :ets.new(:sider_cache, [:set, :private])

        %{
          tab: tab,
          count: 0
        }
      end,
      opts
    )
  end

  def get(pid, key) do
    Agent.get(pid, fn %{tab: tab} ->
      case :ets.lookup(tab, key) do
        [] -> {:error, :missing}
        [{^key, value}] -> {:ok, value}
      end
    end)
  end

  def count(pid) do
    Agent.get(pid, fn %{count: count} ->
      count
    end)
  end

  def set(pid, key, value) do
    Agent.update(pid, fn %{tab: tab, count: count} = state ->
      :ets.insert(tab, {key, value})
      %{state | count: count + 1}
    end)
  end

  def remove(pid, key) do
    Agent.update(pid, fn %{tab: tab, count: count} = state ->
      new_count =
        case :ets.member(tab, key) do
          true -> count - 1
          false -> count
        end

      :ets.delete(tab, key)
      %{state | count: new_count}
    end)
  end
end
