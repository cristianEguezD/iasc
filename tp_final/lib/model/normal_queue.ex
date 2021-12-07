defmodule QueueManager.NormalQueue do
	use GenServer
	require Logger

	@default_timeout 30000
	@default_no_consumers 5000

	def start_link(opts) do
		name = opts[:name]
		Logger.info("Starting queue with name: #{name}")
		GenServer.start_link(__MODULE__, [consumers: [], pending_confirm_messages: [], busy_consumers: [], name: name], name: via_tuple(name))
	end

	def init(init_arg) do
		Logger.info("Normal queue up!")
		name = QueueManager.QueueAgent.get_agent_name(init_arg[:name])
		agent_pid = GenServer.whereis(via_tuple(name))
		if agent_pid == nil do
			{:ok, init_arg}
		else
			initial_state = QueueManager.QueueAgent.get_state(via_tuple(name))
			{:ok, initial_state}
		end

	end

	"
		Messages Succefully
	"

	"For messages send when consumers are empty"
	def handle_info({:process_message, message}, state) do
		{id, _, _} = message
		Logger.info("Re-enqueuing message #{id} since there are no consumers")
		handle_cast({:process_message, message}, state)
	end

	def handle_cast({:processed_message, message, consumer_name }, state) do
		{id, _, _} = message
		Logger.info("Message #{id} processed succefully for consumer, cleaning pending messages")
		pending_confirm_messages = state[:pending_confirm_messages]
		new_messages = List.delete(pending_confirm_messages, message)
		new_busy_consumers = List.delete(state[:busy_consumers], consumer_name)
		consumers = state[:consumers]
		new_consumers = consumers ++ [consumer_name]
		state = Keyword.put(state, :pending_confirm_messages, new_messages)
		state = Keyword.put(state, :busy_consumers, new_busy_consumers)
		state = Keyword.put(state, :consumers, new_consumers)
		update_agent_state(state)
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
		{id, _, _} = message
		Logger.info("Message #{id} comes to be processed")
		consumers = get_consumers(state)

		if length(consumers) == 0 do
			Logger.warn("No consumers available in #{state[:name]}, retrying later")
			Process.send_after(self, {:process_message, message}, @default_no_consumers)
			{:noreply, state}
		else
			[first_consumer | others_consumers] = consumers
			busy_consumers = state[:busy_consumers]
			Logger.info("Sending message #{id} to #{first_consumer}")
			pending_confirm_messages = state[:pending_confirm_messages]
			GenServer.cast(Consumer.via_tuple(first_consumer), {:process_message_transactional, message, state[:name]})
			Process.send_after(self, {:timeout, message}, @default_timeout)
			consumers = others_consumers
			busy_consumers = busy_consumers ++ [first_consumer]
			pending_confirm_messages = pending_confirm_messages ++ [message]
			state = Keyword.put(state, :consumers, consumers)
			state = Keyword.put(state, :busy_consumers, busy_consumers)
			state = Keyword.put(state, :pending_confirm_messages, pending_confirm_messages)
			update_agent_state(state)
			{:noreply, state}
		end
	end

	"
		Timeout consumers response
	"

	def handle_info({:timeout, message}, state) do
		pending_confirm_messages = state[:pending_confirm_messages]
		{id, _, _} = message
		if(Enum.member?(pending_confirm_messages, message)) do
			Logger.info("Message #{id} has been expired")
			new_messages = List.delete(pending_confirm_messages, message)
			state = Keyword.put(state, :pending_confirm_messages, new_messages)
			handle_cast({:process_message, message}, state)
		else
			Logger.info("Consumer has processed #{id}, aborting timeout")
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
		update_agent_state(state)
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

	defp update_agent_state(state) do
		agent_name = QueueManager.QueueAgent.get_agent_name(state[:name])
		QueueManager.QueueAgent.set_state(QueueManager.QueueAgent.via_tuple(agent_name), state)
	end

	def via_tuple(name), do: {:via, Horde.Registry, {QueueManager.HordeRegistry, name}}
end

"""
pid = GenServer.whereis(:queue_1)
GenServer.call(pid,:health_check)
"""
