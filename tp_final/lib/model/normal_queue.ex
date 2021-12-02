defmodule QueueManager.NormalQueue do
	use GenServer
	require Logger

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

	def handle_cast({:processed_message, message}, {consumers, messages}) do
		new_messages = List.delete(messages, message)
		{:noreply, {consumers, new_messages}}
	end

	def handle_cast({:process_message, message}, {[], messages}) do
		{:noreply, {[], messages ++ [message]}}
	end

	def handle_cast({:process_message, message}, {[first_consumer | others_consumers], messages}) do
		GenServer.cast(first_consumer, {:process_message_transactional, message, self})
		"Agrego el mensaje al estado hasta que tenga confirmado que se haya consumido totalmente"
		Process.send_after(self, {:timeout, message}, @default_timeout)
		{:noreply, {others_consumers ++ [first_consumer], messages ++ [message]}}
	end

	def handle_info({:timeout, message}, {consumers, messages}) do
		if(Enum.member?(messages, message)) do 
			new_messages = List.delete(messages, message)
			handle_cast({:process_message, message}, {consumers, new_messages})
		else 
			{:noreply, {consumers, messages}}
		end
  end

	def handle_call(:get_state, _from, state) do
		{:reply, state, state}
	end

	"
		Consumers
	"

	def handle_call({:add_consumer, consumer}, _from, {consumers, messages}) do
		{:reply, :ok, {consumers ++ [consumer], messages}}
	end

	"
		Healthcheck
	"

	def handle_call(:health_check, _from, state) do
		{:reply, :health_check, state}
	end

end

"""
pid = GenServer.whereis(:queue_1)
GenServer.call(pid,:health_check)
"""

"""
	iex
	c("normal_queue.ex")
	{:ok, queue} = GenServer.start_link(QueueManager.NormalQueue, {[consumer]})
	GenServer.cast(queue, {:process_message, ~s({"message": "Esto es un mensaje en json"})})
	GenServer.call(queue, {:add_consumer, :jorge})
	GenServer.call(queue, {:add_consumer, :rama})
	GenServer.call(queue, {:add_consumer, :berko})

"""
