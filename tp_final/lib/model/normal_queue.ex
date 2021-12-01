defmodule QueueManager.NormalQueue do
	use GenServer

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

	def handle_cast({:processMessage, message}, {[ch | ct]}) do
		GenServer.cast(ch, {:processMessage, message})
		{:noreply, {[ct | ch]}}
	end

	"
		Consumers
	"

	def handle_call({:addConsumer, consumer}, _from, {consumers}) do
		{:reply, :ok, {consumers ++ [consumer]}}
	end

	def handle_call(:getConsumers, _from, {consumers}) do
		{:reply, consumers, {consumers}}
	end

	"
		Health check
	"

	def handle_call(:healthCheck, _from, state) do
		{:reply, :healthCheck, state}
	end

end

"""
pid = GenServer.whereis(:queue_1)
GenServer.call(pid,:healthCheck)
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
