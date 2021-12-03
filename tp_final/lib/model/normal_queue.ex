defmodule QueueManager.NormalQueue do
	use GenServer
	require Logger

	@default_timeout 10000
	@default_no_consumers 5000

	def start_link(opts) do
		name = opts[:name]
		Logger.info("Starting queue with name: #{name}")
		GenServer.start_link(__MODULE__, [consumers: [], pending_confirm_messages: [], name: name], name: via_tuple(name))
	end

	def init(init_arg) do
		Logger.info("Queue up with pid: #{inspect self()}")
		{:ok, init_arg}
	end

	"
		Messages Succefully
	"

	"For messages send when consumers are empty"
	def handle_info({:process_message, message}, state) do
		Logger.info("Re-queuing message as there are no consumers")
		handle_cast({:process_message, message}, state)
	end

	def handle_cast({:processed_message, message, _ }, state) do
		Logger.info("Message #{message} processed succefully for consumer, cleaning pending messages")
		pending_confirm_messages = state[:pending_confirm_messages]
		new_messages = List.delete(pending_confirm_messages, message)
		state = Keyword.put(state, :pending_confirm_messages, new_messages)
		{:noreply, state}
	end

	"
		Receive messages from producers
	"

	# def handle_cast({:process_message, message}, [consumers: []]) do
	# 	Logger.warning("NO CONSUMERS")
	# 	Process.send_after(self, {:process_message, message}, @default_no_consumers)
	# 	{:noreply, {[], pending_confirm_messages}}
	# end

	def handle_cast({:process_message, message}, state) do
		Logger.info("Message #{message} comes for processing")
		consumers = get_consumers(state)

		if length(consumers) == 0 do
			Logger.warn("No consumers available in #{state[:name]}, retrying later")
			Process.send_after(self, {:process_message, message}, @default_no_consumers)
			{:noreply, state}
		else
			[first_consumer | others_consumers] = consumers
			Logger.info("Sending message to #{first_consumer}")
			pending_confirm_messages = state[:pending_confirm_messages]
			GenServer.cast(Consumer.via_tuple(first_consumer), {:process_message_transactional, message, state[:name]})
			Process.send_after(self, {:timeout, message}, @default_timeout)
			consumers = others_consumers ++ [first_consumer]
			pending_confirm_messages = pending_confirm_messages ++ [message]
			state = Keyword.put(state, :consumers, consumers)
			state = Keyword.put(state, :pending_confirm_messages, pending_confirm_messages)
			{:noreply, state}
		end
	end

	"
		Timeout consumers response
	"

	def handle_info({:timeout, message}, state) do
		pending_confirm_messages = state[:pending_confirm_messages]
		if(Enum.member?(pending_confirm_messages, message)) do
			Logger.info("Message #{message} has been expired")
			new_messages = List.delete(pending_confirm_messages, message)
			state = Keyword.put(state, :pending_confirm_messages, new_messages)
			handle_cast({:process_message, message}, state)
		else
			Logger.info("Consumer has procees #{message}, aborting timeout")
			{:noreply, state}
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

	def handle_call({:register_consumer, consumer}, _from, state) do
		Logger.info("Registering consumer #{consumer}")
		consumers = get_consumers(state)
		state = Keyword.put(state, :consumers, consumers ++ [consumer])
		{:reply, :ok, state}
	end

	"
		Healthcheck
	"

	def handle_call(:health_check, _from, state) do
		Logger.info("I am alive dog")
		{:reply, :health_check, state}
	end

	defp get_consumers(state) do
		Keyword.get(state, :consumers, [])
	end

	def via_tuple(name), do: {:via, Horde.Registry, {QueueManager.HordeRegistry, name}}
end

"""
pid = GenServer.whereis(:queue_1)
GenServer.call(pid,:health_check)
"""
