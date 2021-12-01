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

	def handle_cast({:processMessage, _message}, {consumers}) do
		{:noreply, {consumers}}
	end

	def handle_call(:healthCheck, _from, consumers) do
		{:reply, :healthCheck, {consumers}}
	end

	def handle_call({:addConsumer, consumer}, _from, {consumers}) do
		{:reply, :ok, {consumers ++ [consumer]}}
	end

	def handle_call(:getConsumers, _from, {consumers}) do
		{:reply, consumers, {consumers}}
	end

end

"""
pid = GenServer.whereis(:queue_1)
GenServer.call(pid,:healthCheck)
"""

"""
	iex
	c("normal_queue.ex")
	{:ok, pid} = GenServer.start_link(NormalQueue, {[]})
	GenServer.call(pid, {:addConsumer, :jorge})
	GenServer.call(pid, {:addConsumer, :rama})
	GenServer.call(pid, {:addConsumer, :berko})
	GenServer.call(pid, :getConsumers)

"""
