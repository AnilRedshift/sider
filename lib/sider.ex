defmodule Sider do
  @type key :: any()
  @type value :: any()
  @type args ::
          %{
            reap_interval: pos_integer(),
            capacity: pos_integer()
          }
          | %{
              reap_interval: pos_integer()
            }

  @spec start_link(args) :: GenServer.on_start()
  def start_link(args), do: start_link(args, [])

  def start_link(%{reap_interval: reap_interval}, opts) do
    args = %{reap_interval: reap_interval, capacity: nil}
    start_link(args, opts)
  end

  @spec start_link(args, GenServer.options()) :: GenServer.on_start()
  def start_link(%{reap_interval: _reap_interval, capacity: _capacity} = args, opts) do
    GenServer.start_link(Sidr.Impl, args, opts)
  end

  @spec get(GenServer.server(), key) :: {:ok, value} | {:error, :missing_key}
  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  @spec set(GenServer.server(), key, value, pos_integer()) :: :ok | {:error, :max_capacity}
  def set(pid, key, value, timeout \\ nil) do
    GenServer.call(pid, {:set, key, value, timeout})
  end

  @spec remove(GenServer.server(), key) :: nil
  def remove(pid, key) do
    GenServer.call(pid, {:remove, key})
  end
end
