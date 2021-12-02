# QueueManager

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tp_final` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tp_final, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/tp_final](https://hexdocs.pm/tp_final).


## Start a node

```bash
iex --sname node1 --cookie some_cookie -S mix
```

## Create a new queue
```
opts = [name: :queue_name]
QueueManager.NormalQueue.Starter.start_link(opts)
```

## Obtain queue PID
```
pid = GenServer.whereis(:queue_name)
```

## Healthcheck queue
```
GenServer.call(pid,:healthCheck)
```

## Send message through Horde
```
GenServer.call(QueueManager.NormalQueue.via_tuple(:queue_name), :get_state)
```