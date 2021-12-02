defmodule QueueManager.NormalQueue do
	use GenServer
	require Logger

	@default_timeout 10000
	@default_no_consumers_availability 5000

	def start_link(opts) do
		name = Keyword.get(opts, :name, __MODULE__)
		GenServer.start_link(__MODULE__, [], name: name)
	end

	def init(init_arg) do
		log("Normal queue up with pid: #{inspect(self)}")
		{:ok, init_arg}
	end

	"
		Messages
	"

	def handle_info({:process_message, message}, state) do 
		handle_cast({:process_message, message}, state)
	end

	def handle_cast({:processed_message, message}, {consumers, messages}) do
		log("Message #{message} processed succefully")
		new_messages = List.delete(messages, message)
		{:noreply, {consumers, new_messages}}
	end

	"
		Receive messages from producers
	"

	def handle_cast({:process_message, message}, {[], messages}) do
		Logger.warning("NO CONSUMERS")
		Process.send_after(self, {:process_message, message}, @default_no_consumers_availability)
		{:noreply, {[], messages}}
	end

	def handle_cast({:process_message, message}, {[first_consumer | others_consumers], messages}) do
		log("Message #{message} comes for processing")
		GenServer.cast(first_consumer, {:process_message_transactional, message, self})
		Process.send_after(self, {:timeout, message}, @default_timeout)
		{:noreply, {others_consumers ++ [first_consumer], messages ++ [message]}}
	end

	"
		Timeout consumers response
	"

	def handle_info({:timeout, message}, {consumers, messages}) do
		if(Enum.member?(messages, message)) do
			log("Message #{message} has been expired") 
			new_messages = List.delete(messages, message)
			handle_cast({:process_message, message}, {consumers, new_messages})
		else 
			log("Customer has procees #{message}, aborting timeout")
			{:noreply, {consumers, messages}}
		end
  end

	"
		Getter
	"

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
		log("I am alive dog")
		{:reply, :health_check, state}
	end
	
	defp log(message) do
		Logger.info(message)
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
