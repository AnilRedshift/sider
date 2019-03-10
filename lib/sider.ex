defmodule Sider do
  @type key :: any()
  @type value :: any()
  @type args ::
          %{
            reap_interval: pos_integer(),
            capacity: pos_integer()
          }
          | %{
              capacity: pos_integer()
            }
  def start_link(args), do: start_link(args, [])

  @doc """
  Create a sider cache process. The behavior of the sider cache can be controlled by the following args
  reap_interval: The number of milliseconds to wait before removing keys that have expired
  capacity: The number of keys allowed in the store. This includes expired keys that have not been reaped.

  Any opts are passed directly to the GenServer

  ## Examples

    iex> {:ok, _pid} = Sider.start_link(%{reap_interval: 60_000, capacity: 1_000_000})
    iex> {:ok, _named_process} = Sider.start_link(%{reap_interval: 60_000, capacity: 1_000_000}, name: :my_cache)
    iex> :ok
    :ok
  """

  @spec start_link(args, GenServer.options()) :: GenServer.on_start()
  def start_link(%{reap_interval: _reap_interval, capacity: _capacity} = args, opts) do
    GenServer.start_link(Sider.Impl, args, opts)
  end

  @spec start_link(args, GenServer.options()) :: GenServer.on_start()
  def start_link(%{capacity: capacity}, opts) do
    args = %{reap_interval: 60_000, capacity: capacity}
    start_link(args, opts)
  end

  @spec child_spec(any()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc """
  Returns an existing key, if it has not expired.

  ## Examples

    iex> {:ok, pid} = Sider.start_link(%{reap_interval: 1, capacity: 100})
    iex> Sider.set(pid, :a, :foo)
    iex> {:ok, :foo} = Sider.get(pid, :a)
    iex> {:error, :missing_key} = Sider.get(pid, :b)
    iex> :ok
    :ok
  """
  @spec get(GenServer.server(), key) :: {:ok, value} | {:error, :missing_key}
  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  @spec set(GenServer.server(), key, value, pos_integer() | nil) :: :ok | {:error, :max_capacity}
  def set(pid, key, value, timeout \\ nil) do
    GenServer.call(pid, {:set, key, value, timeout})
  end

  @spec remove(GenServer.server(), key, [] | [{:only, :expired}]) :: nil
  def remove(pid, key, opts \\ []) do
    GenServer.call(pid, {:remove, key, opts})
  end
end
