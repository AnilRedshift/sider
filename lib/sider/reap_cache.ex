defmodule Sider.ReapCache do
  @moduledoc false
  use GenServer

  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def set(pid, key, timeout) do
    GenServer.call(pid, {:set, key, timeout})
  end

  def remove(pid, reaper_key) do
    GenServer.call(pid, {:remove, reaper_key})
  end

  def pop_expired_key(pid) do
    GenServer.call(pid, :pop)
  end

  def init(_args) do
    tab = :ets.new(:sider_reap_cache, [:ordered_set, :private])
    {:ok, tab}
  end

  def handle_call({:set, key, timeout}, _from, tab) do
    expires_at = System.monotonic_time(:millisecond) + timeout
    suffix = 1 / System.unique_integer([:positive])
    reaper_key = expires_at + suffix
    {:reply, insert(tab, reaper_key, key), tab}
  end

  def handle_call({:remove, reaper_key}, _from, tab) do
    :ets.delete(tab, reaper_key)
    {:reply, nil, tab}
  end

  def handle_call(:pop, _from, tab) do
    now = System.monotonic_time(:millisecond)

    response =
      case get_first_value(tab) do
        {:ok, {key, value}} when now > key ->
          :ets.delete(tab, key)
          {:ok, value}

        {:ok, _} ->
          {:error, :not_expired}

        {:error, reason} ->
          {:error, reason}
      end

    {:reply, response, tab}
  end

  defp insert(tab, reaper_key, value) do
    case :ets.insert_new(tab, {reaper_key, value}) do
      true -> {:ok, reaper_key}
      false -> {:error, :insertion_error}
    end
  end

  defp get_first_value(tab) do
    case :ets.first(tab) do
      :"$end_of_table" -> {:error, :empty}
      key -> get(tab, key)
    end
  end

  defp get(tab, key) do
    case :ets.lookup(tab, key) do
      [] -> {:error, :missing}
      [{^key, value}] -> {:ok, {key, value}}
    end
  end
end
