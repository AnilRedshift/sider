defmodule Sider.ReapCache do
  @moduledoc false
  use GenServer

  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def set(pid, key, expires_at) do
    GenServer.call(pid, {:set, key, expires_at})
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

  def handle_call({:set, key, expires_at}, _from, tab) do
    reaper_key = create_reaper_key(expires_at)
    insert(tab, reaper_key, key)
    {:reply, nil, tab}
  end

  def handle_call({:remove, reaper_key}, _from, tab) do
    :ets.delete(tab, reaper_key)
    {:reply, nil, tab}
  end

  def handle_call(:pop, _from, tab) do
    now = System.monotonic_time(:millisecond)

    response =
      case get_first_value(tab) do
        {:ok, {{expires_at, _} = key, value}} when now > expires_at ->
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
    true = :ets.insert_new(tab, {reaper_key, value})
  end

  defp get_first_value(tab) do
    case :ets.first(tab) do
      :"$end_of_table" -> {:error, :empty}
      key -> get(tab, key)
    end
  end

  defp get(tab, key) do
    case :ets.lookup(tab, key) do
      [] -> {:error, :missing_key}
      [{^key, value}] -> {:ok, {key, value}}
    end
  end

  defp create_reaper_key(expires_at) do
    nonce = System.unique_integer([:positive])
    {expires_at, nonce}
  end
end
