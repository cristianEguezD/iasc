# Arquitectura

![Arquitectura](arquitectura.jpg?raw=true "Arquitectura")

Como primero punto, decidimos utilizar elixir y en particular el modelo de actores debido a que el enunciado del trabajo práctico tenía como objetivos principales lograr que el sistema sea distribuído, tolerar las fallas en el sistema, atender las solicitudes de forma concurrente y otros aspectos que el lenguaje soportaba de forma nativa.
Escogimos utilizar Horde ya que nos provee una gestión transparente de la distribución del sistema.
En cuanto a la arquitectura contamos con:
-   NodeSupervisorObserver: encargado de supervisar al NodeObserver del sistema.
-   NodeObserver: responsable de setear los miembros del sistema cuando un nodo entra o un nodo se cae.
-   NormalQueue: cola que funciona con el esquema tradicional de envío de mensajes.
-   BroadcastQueue: cola especial que funciona con la modalidad Publicar-Suscribir.
-   Consumer: entidad responsable de recibir y procesar pedidos de las queues.
-   QueueAgent: gestiona el estado tanto de las NormalQueue como también de las BroadcastQueue. Existe una por cada queue, esto permite que el estado quede distribuído en todo el sistema y no haya un único punto de falla.
-   Producer: no se encuentra bajo la supervisión de Horde, simplemente son funcionalidades que nos permiten crear distintos tipos de mensajes para que las queues puedan recibirlos.
-   Starter: no se encuentra bajo la supervisión de Horde, nos permite crear las distintas colas y consumidores que necesita el sistema.  

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

```
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

## Full example (without Producer)
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

## Full example with producer

```
opts = [name: :normal_queue]
QueueManager.NormalQueue.Starter.start_normal_queue(opts)
Consumer.start_in_cluster([name: :consumer1])
Consumer.start_in_cluster([name: :consumer2])
Consumer.start_in_cluster([name: :consumer3])
GenServer.call(Consumer.via_tuple(:consumer1), {:register_in_queue, :normal_queue})
GenServer.call(Consumer.via_tuple(:consumer2), {:register_in_queue, :normal_queue})
GenServer.call(Consumer.via_tuple(:consumer3), {:register_in_queue, :normal_queue})
normal_queue_message = ~s({"message": "Esto es un mensaje para la normal queue"})
Producer.produce_n_wait_messages(:normal_queue, :process_1, normal_queue_message, 1, 5000, 0, :process_message_transactional)
Producer.produce_n_wait_messages(:normal_queue, :process_2, normal_queue_message, 1, 10000, 0, :process_message_no_transactional)


opts = [name: :broadcast_queue]
QueueManager.NormalQueue.Starter.start_broadcast_queue(opts)
Consumer.start_in_cluster([name: :consumer4])
Consumer.start_in_cluster([name: :consumer5])
Consumer.start_in_cluster([name: :consumer6])
GenServer.call(Consumer.via_tuple(:consumer4), {:register_in_queue, :broadcast_queue})
GenServer.call(Consumer.via_tuple(:consumer5), {:register_in_queue, :broadcast_queue})
GenServer.call(Consumer.via_tuple(:consumer6), {:register_in_queue, :broadcast_queue})
broadcast_queue_message = ~s({"message": "Esto es otro mensaje pero para la queue broadcast"})
Producer.produce_n_wait_messages(:broadcast_queue, :process_3, broadcast_queue_message, 1, 1000, 0, :process_message_transactional)
Producer.produce_n_wait_messages(:broadcast_queue, :process_4, broadcast_queue_message, 1, 1000, 0, :process_message_no_transactional)


GenServer.call(Consumer.via_tuple(:normal_queue), {:delete_consumer, :consumer1})
GenServer.call(Consumer.via_tuple(:broadcast_queue), {:delete_consumer, :consumer1})

```
