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

## Create consumer
```
Consumer.start_in_cluster([name: :consumer1])
```

## Register consumer
```
GenServer.call(Consumer.via_tuple(:consumer1), {:register_in_queue, :queue_name})
```



## Full example
```
opts = [name: :queue_name]
QueueManager.NormalQueue.Starter.start_link(opts)
Consumer.start_in_cluster([name: :consumer1])
GenServer.call(Consumer.via_tuple(:consumer1), {:register_in_queue, :queue_name})

GenServer.cast(QueueManager.NormalQueue.via_tuple(:queue_name), {:process_message, ~s({"message": "Esto es un mensaje en json 1"})})
```