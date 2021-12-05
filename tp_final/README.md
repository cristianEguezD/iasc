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
opts = [name: :normal_queue]
QueueManager.NormalQueue.Starter.start_normal_queue(opts)
QueueManager.QueueAgent.get_state(QueueManager.QueueAgent.via_tuple(:normal_queue_agent))
QueueManager.QueueAgent.set_state(QueueManager.QueueAgent.via_tuple(:normal_queue_agent), [consumers: [], pending_confirm_messages: [], name: :normal_queue])

opts = [name: :broadcast_queue]
QueueManager.NormalQueue.Starter.start_broadcast_queue(opts)

Consumer.start_in_cluster([name: :consumer1])
Consumer.start_in_cluster([name: :consumer2])
Consumer.start_in_cluster([name: :consumer3])
GenServer.call(Consumer.via_tuple(:consumer1), {:register_in_queue, :normal_queue})
GenServer.call(Consumer.via_tuple(:consumer2), {:register_in_queue, :normal_queue})
GenServer.call(Consumer.via_tuple(:consumer3), {:register_in_queue, :normal_queue})
normal_queue_message = ~s({"message": "Esto es un mensaje para la normal queue"})
GenServer.cast(QueueManager.NormalQueue.via_tuple(:normal_queue), {:process_message, {:mensaje_broadcast, :hash, normal_queue_message}})

Consumer.start_in_cluster([name: :consumer4])
Consumer.start_in_cluster([name: :consumer5])
Consumer.start_in_cluster([name: :consumer6])
GenServer.call(Consumer.via_tuple(:consumer4), {:register_in_queue, :broadcast_queue})
GenServer.call(Consumer.via_tuple(:consumer5), {:register_in_queue, :broadcast_queue})
GenServer.call(Consumer.via_tuple(:consumer6), {:register_in_queue, :broadcast_queue})
broadcast_queue_message = ~s({"message": "Esto es otro mensaje pero para la queue broadcast"})
GenServer.cast(QueueManager.BroadCastQueue.via_tuple(:broadcast_queue), {:process_message, {:mensaje_broadcast, :hash, broadcast_queue_message}})

```

## Example with producer

```
opts = [name: :normal_queue]
QueueManager.NormalQueue.Starter.start_normal_queue(opts)
Consumer.start_in_cluster([name: :consumer1])

GenServer.call(Consumer.via_tuple(:consumer1), {:register_in_queue, :normal_queue})

normal_queue_message = ~s({"message": "Esto es un mensaje para la normal queue"})
Producer.produce_hash_message(:normal_queue, :id1, normal_queue_message)
Producer.produce_wait_message(:normal_queue, :id2, normal_queue_message, 3000)
```