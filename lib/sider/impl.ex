defmodule Sider.Impl do
  @moduledoc false
  alias Sider.Cache
  alias Sider.ReapCache
  alias Sider.Reaper
  alias Sider.Item
  use GenServer

  @impl true
  def init(%{reap_interval: reap_interval, capacity: capacity}) do
    {:ok, cache} = Cache.start_link()
    {:ok, reap_cache} = ReapCache.start_link()

    {:ok, reaper} =
      Reaper.start_link(%{reap_cache: reap_cache, sider: self(), reap_interval: reap_interval})

    state = %{
      cache: cache,
      reap_cache: reap_cache,
      reaper: reaper,
      capacity: capacity
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get, key}, _from, %{cache: cache} = state) do
    {:reply, get(cache, key), state}
  end

  @impl true
  def handle_call({:set, key, value, nil}, _from, %{cache: cache, capacity: capacity} = state) do
    response =
      case Cache.count(cache) do
        count when count >= capacity -> {:error, :max_capacity}
        _ -> set_infinite(key, value, state)
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call({:set, key, value, timeout}, _from, %{cache: cache, capacity: capacity} = state) do
    response =
      case Cache.count(cache) do
        count when count >= capacity -> {:error, :max_capacity}
        _ -> set(key, value, timeout, state)
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call({:remove, key, opts}, _from, state) do
    remove(key, opts, state)
    {:reply, nil, state}
  end

  defp get(cache, key) do
    with {:ok, %Item{} = item} <- Cache.get(cache, key),
         :ok <-
           validate(item) do
      {:ok, item.value}
    else
      {:error, :missing} -> {:error, :missing}
      {:error, :expired} -> {:error, :missing}
      _ -> {:error, :unknown}
    end
  end

  defp set_infinite(key, value, %{cache: cache} = state) do
    remove_from_reaper(key, state)
    item = %Item{value: value}
    Cache.set(cache, key, item)
  end

  defp set(key, value, timeout, %{cache: cache, reap_cache: reap_cache} = state) do
    remove_from_reaper(key, state)
    expires_at = System.monotonic_time(:millisecond) + timeout

    case ReapCache.set(reap_cache, key, expires_at) do
      {:ok, reaper_key} ->
        item = %Item{value: value, expires_at: expires_at, reaper_key: reaper_key}
        Cache.set(cache, key, item)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp remove(key, [only: :expired], %{cache: cache} = state) do
    case get(cache, key) do
      {:ok, _item} -> remove(key, [], state)
      _ -> nil
    end
  end

  defp remove(key, [], %{cache: cache} = state) do
    remove_from_reaper(key, state)
    Cache.remove(cache, key)
  end

  defp validate(%Item{expires_at: nil}), do: :ok

  defp validate(%Item{expires_at: expires_at}) do
    now = System.monotonic_time(:millisecond)

    case now < expires_at do
      true -> :ok
      false -> {:error, :expired}
    end
  end

  defp remove_from_reaper(key, %{cache: cache, reap_cache: reap_cache}) do
    case Cache.get(cache, key) do
      {:ok, %Item{reaper_key: reaper_key}} when reaper_key != nil ->
        ReapCache.remove(reap_cache, reaper_key)
    end
  end
end
