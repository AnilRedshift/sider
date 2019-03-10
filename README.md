# Sider

Sider is an in-memory key-value store with the following characteristics:
  1. keys & values may be of any type
  2. Key-value pairs expire - once set in the store, they are only valid for a given time
  3. Sider has O(keys) + O(values) memory characteristics
  4. The cache maintains consistent access times - It will not degrade when reaping expired values

  The usage of Sider is as follows. Usually, it will be started under a supervisor with a given name
  ```elixir
  children = [
    {Sider, %{capacity: 100, name: :my_cache}}
  ]
  Supervisor.start_link(children, strategy: :one_for_one)
  ```

  You can then call the cache via its given name, similar to this
  ```elixir
  Sider.get(:my_cache, :a)
  ```


## Installation
```elixir
def deps do
  [
    {:sider, "~> 0.1.0"}
  ]
end
```

## Usage
Once you have a running Sider cache, you can get and set keys that expire after some tim:

```elixir
# Store an access token for example@example.com
Sider.set(:my_cache, "example@example.com", "access_token_123", 60_000)
# I can access this token for 60 seconds
{:ok, "access_token_123"} = Sider.get(:my_cache, "example@example.com")

# but after 60 seconds, it will be gone
Process.sleep(60_000)
{:error, :missing_key} = Sider.get(:my_cache, "example@example.com")
```

Hex documentation is available at [https://hexdocs.pm/sider](https://hexdocs.pm/sider)

