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
  def start_link(args), do: start_link(args, [])

  def start_link(%{reap_interval: _reap_interval, capacity: _capacity} = args, opts) do
    GenServer.start_link(Sider.Impl, args, opts)
  end

  def start_link(%{reap_interval: reap_interval}, opts) do
    args = %{reap_interval: reap_interval, capacity: nil}
    start_link(args, opts)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

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
