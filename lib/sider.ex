defmodule Sider do
  @type key :: any()
  @type value :: any()
  @type args ::
          %{
            reap_interval: pos_integer(),
            capacity: pos_integer(),
            name: atom,
          }
          | %{
              name: atom,
              capacity: pos_integer()
            }
          | %{
              capacity: pos_integer()
            }

  @moduledoc """
  Sider is an in-memory key-value store with the following characteristics:
  1. keys & values may be of any type
  2. Key-value pairs expire - once set in the store, they are only valid for a given time
  3. Sider has O(keys) + O(values) memory characteristics
  4. The cache maintains consistent access times - It will not degrade when reaping expired values

  The usage of Sider is as follows. Usually, it will be started under a supervisor with a given name
  ```
  children = [
    {Sider, %{capacity: 100, name: :my_cache}}
  ]
  Supervisor.start_link(children, strategy: :one_for_one)
  ```

  You can then call the cache via its given name, similar to this
  ```
  Sider.get(:my_cache, :a)
  ```
  """

  @doc """
  Create a sider cache process. The behavior of the sider cache can be controlled by the following args
  reap_interval: The number of milliseconds to wait before removing keys that have expired
  capacity: The number of keys allowed in the store. This includes expired keys that have not been reaped.

  ## Examples

      iex> {:ok, _pid} = Sider.start_link(%{reap_interval: 60_000, capacity: 1_000_000, name: :my_cache})
      iex> :ok
      :ok
  """

  @spec start_link(args) :: GenServer.on_start()
  def start_link(args) do
    opts = case Map.fetch(args, :name) do
      {:ok, name} -> [name: name]
      :error -> []
    end
    args = %{
      capacity: args.capacity,
      reap_interval: Map.get(args, :reap_interval, 60_000)
    }
    GenServer.start_link(Sider.Impl, args, opts)
  end

  @spec child_spec(args) :: Supervisor.child_spec()
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
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

  @doc """
  Store a new key-value pair, with an optional timeout for when the pair should expire
  Returns :ok if successful, or {:error, :max_capacity} if the cache is full

  If you call set() on a key that already exists in the store, that key-pair will be overwritten

  ## Examples

      iex> {:ok, pid} = Sider.start_link(%{reap_interval: 1000, capacity: 1})
      iex> :ok = Sider.set(pid, :a, :foo, 1000) # Set a key with a value of :foo that expires after 1000ms
      iex> :ok = Sider.set(pid, :a, {1, 2}, 1000) # Overwrite the key
      iex> Sider.set(pid, :b, :bar) # The capacity is 1, so the key cannot be written
      {:error, :max_capacity}
  """
  @spec set(GenServer.server(), key, value, pos_integer() | nil) :: :ok | {:error, :max_capacity}
  def set(pid, key, value, timeout \\ nil) do
    GenServer.call(pid, {:set, key, value, timeout})
  end

  @doc """
  Removes a key-value pair from the cache, if it exists.
  This function no-ops if the key is non-existant

  If you pass in the `only: :expired` option, the value will only be removed if the entry has expired
  (See the timeout value in `Sider.set/4`)

  ## Examples

      iex> {:ok, pid} = Sider.start_link(%{reap_interval: 1000, capacity: 100})
      iex> Sider.set(pid, :a, :foo)
      iex> Sider.remove(pid, :a)
      nil

  """
  @spec remove(GenServer.server(), key, [] | [{:only, :expired}]) :: nil
  def remove(pid, key, opts \\ []) do
    GenServer.call(pid, {:remove, key, opts})
  end
end
