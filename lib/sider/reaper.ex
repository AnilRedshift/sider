defmodule Sider.Reaper do
  @moduledoc false
  alias Sider.ReapCache
  use GenServer

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def reap(pid) do
    GenServer.cast(pid, :reap)
  end

  @impl true
  def init(%{reap_cache: reap_cache, sider: sider, reap_interval: reap_interval}) do
    state = %{
      reap_cache: reap_cache,
      sider: sider,
      reap_interval: reap_interval
    }

    Process.send_after(self(), :reap, reap_interval)
    {:ok, state}
  end

  @impl true
  def handle_cast(:reap, state) do
    handle_reap(state)
    {:noreply, state}
  end

  @impl true
  def handle_info(:reap, %{reap_interval: reap_interval} = state) do
    handle_reap(state)
    Process.send_after(self(), :reap, reap_interval)
    {:noreply, state}
  end

  defp handle_reap(%{sider: sider, reap_cache: reap_cache} = state) do
    case ReapCache.pop_expired_key(reap_cache) do
      {:ok, key} ->
        Sider.remove(sider, key, only: :expired)
        handle_reap(state)

      _ ->
        nil
    end
  end
end
