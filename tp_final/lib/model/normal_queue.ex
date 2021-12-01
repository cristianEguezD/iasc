defmodule QueueManager.NormalQueue do
	use GenServer

	@default_timeout 10000

	def start_link(opts) do
		name = Keyword.get(opts, :name, __MODULE__)
		IO.puts(:stdio, name)
		GenServer.start_link(__MODULE__, [], name: name)
	end

	def init(init_arg) do
		{:ok, init_arg}
	end

	"
		Messages
	"

	def handle_cast({:processMessage, message}, {[], messages}) do
		{:noreply, {[], messages ++ [message]}}
	end

	def handle_cast({:processMessage, message}, {[first_consumer | others_consumers], messages}) do
		GenServer.cast(first_consumer, {:processMessage, message})
		"Agrego el mensaje al estado hasta que tenga confirmado que se haya consumido totalmente"
		Process.send_after(self, {:timeout, message}, @default_timeout)
		{:noreply, {others_consumers ++ [first_consumer], messages ++ [message]}}
	end

	def handle_info({:timeout, message}, {consumers, messages}) do
		newMessages = List.delete(messages, message)
    {:noreply, {consumers, newMessages}}
  end

	def handle_call(:getState, _from, state) do
		{:reply, state, state}
	end

	"
		Consumers
	"

	def handle_call({:addConsumer, consumer}, _from, {consumers, messages}) do
		{:reply, :ok, {consumers ++ [consumer], messages}}
	end

	"
		Health first_consumereck
	"

	def handle_call(:healthfirst_consumereck, _from, state) do
		{:reply, :healthfirst_consumereck, state}
	end

end

"""
pid = GenServer.whereis(:queue_1)
GenServer.call(pid,:healthfirst_consumereck)
"""

"""
	iex
	c("normal_queue.ex")
	{:ok, queue} = GenServer.start_link(QueueManager.NormalQueue, {[consumer]})
	GenServer.cast(queue, {:processMessage, ~s({"message": "Esto es un mensaje en json"})})
	GenServer.call(queue, {:addConsumer, :jorge})
	GenServer.call(queue, {:addConsumer, :rama})
	GenServer.call(queue, {:addConsumer, :berko})
	GenServer.call(queue, :getConsumers)

"""
