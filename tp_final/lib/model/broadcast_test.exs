"""
  iex
  IEx.Helpers.c("broadcast_test.exs")
"""
IEx.Helpers.c("consumer.ex")
IEx.Helpers.c("broadcast_queue.ex")
{:ok, consumer_1} = GenServer.start_link(Consumer, {[]})
{:ok, consumer_2} = GenServer.start_link(Consumer, {[]})
{:ok, consumer_3} = GenServer.start_link(Consumer, {[]})
{:ok, consumer_4} = GenServer.start_link(Consumer, {[]})
{:ok, queue} = GenServer.start_link(QueueManager.BroadCastQueue, {[consumer_1, consumer_2, consumer_3,consumer_4], []})
GenServer.cast(queue, {:process_message, ~s({"message": "Esto es un mensaje en json 1"})})
GenServer.cast(queue, {:process_message, ~s({"message": "Esto es un mensaje en json 2"})})
"""
GenServer.call(queue, {:add_consumer, :jorge})
GenServer.call(queue, {:add_consumer, :rama})
GenServer.call(queue, {:add_consumer, :berko})
"""
