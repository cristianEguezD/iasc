defmodule NormalQueue do
	use GenServer

	def start_link(name) do
		GenServer.start_link(__MODULE__)
	end

	"""
	def init({consumers}) do
    {:ok, {consumers}}
  end
	"""

	def handle_cast({:processMessage, message}, {consumers}) do
		{:noreply, {consumers}}
	end

	def handle_call(:healthCheck, _from, {consumers}) do
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
	iex
	c("normal_queue.ex")
	{:ok, pid} = GenServer.start_link(NormalQueue, {[]})
	GenServer.call(pid, {:addConsumer, :jorge})
	GenServer.call(pid, {:addConsumer, :rama})
	GenServer.call(pid, {:addConsumer, :berko})
	GenServer.call(pid, :getConsumers)

"""