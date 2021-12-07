defmodule QueueManager.BroadCastQueue do
	use GenServer
	require Logger

	@default_no_consumers 5000
	@default_timeout 60000

	def start_link(opts) do
		name = opts[:name]
		Logger.info("Starting broadcast queue with name: #{name}")
		GenServer.start_link(__MODULE__, [consumers: [], pending_confirm_messages: [], name: name], name: via_tuple(name))
	end

	def init(state) do
		queue_name = state[:name]
		Logger.info("Broadcast queue up!")
		agent_name = QueueManager.QueueAgent.get_agent_name(queue_name)
		agent_pid = GenServer.whereis(via_tuple(agent_name))
		if agent_pid == nil do
			Logger.info("Agent #{agent_name} does not exist in the system, starting #{queue_name} with default state")
			{:ok, state}
		else
			Logger.info("Agent #{agent_name} exist in the system, starting #{queue_name} with saved state")
			initial_state = QueueManager.QueueAgent.get_state(via_tuple(agent_name))
			{:ok, initial_state}
		end
  end

	"For messages send when consumers are empty"
	def handle_info({:process_message, message}, state) do
		{id, _ , _} = message
		Logger.info("Re-queuing message #{id} as there are no consumers")
		handle_cast({:process_message, message}, state)
	end

	"mensajes procesados"
	def handle_cast({:processed_message, processed_message, consumer}, state) do
		{id, _ , _} = processed_message
		consumers = state[:consumers]
		pending_confirm_messages = state[:pending_confirm_messages]
		pending_message_to_delete = {sent_message, consumers_to_notify} = findMessage(pending_confirm_messages, processed_message)
		Logger.info("Message #{id} processed by consumer: #{inspect consumer}")
		remaining_consumers_to_notify = List.delete(consumers_to_notify, consumer)
		remaining_pending_confirm_messages = List.delete(pending_confirm_messages, pending_message_to_delete)
		if(remaining_consumers_to_notify == [] ) do
			Logger.info("All consumers responded with ACK")
			state = Keyword.put(state, :pending_confirm_messages, remaining_pending_confirm_messages)
			update_agent_state(state)
			{:noreply, state}
		else
			Logger.info("There are still consumers who did not answer with ACK: #{inspect remaining_consumers_to_notify} for message #{id}")
			updated_sent_message = {sent_message, remaining_consumers_to_notify}
			state = Keyword.put(state, :pending_confirm_messages, remaining_pending_confirm_messages ++ [updated_sent_message])
			update_agent_state(state)
			{:noreply, state}
		end
	end

	"mensajes a procesar"

	def handle_cast({:process_message, message}, state) do
		consumers = state[:consumers]
		{id, _, _} = message
		if length(consumers) == 0 do
			Logger.warn("No consumers available in #{state[:name]}, retrying later")
			Process.send_after(self, {:process_message, message}, @default_no_consumers)
			{:noreply, state}
		else
			Logger.info("Sending message #{id} to all customers: #{inspect consumers}")
			Enum.each(consumers, fn consumer ->
				GenServer.cast(Consumer.via_tuple(consumer), {:process_message_transactional, message, state[:name]})
			 end)
			 Process.send_after(self, {:timeout, message}, @default_timeout * length(consumers))
			 new_messages = state[:pending_confirm_messages] ++ [{message, consumers}]
			 state = Keyword.put(state, :pending_confirm_messages, new_messages)
			 update_agent_state(state)
			 {:noreply, state}
		end
	end

	"mensajes autoenviados"
	def handle_info({:timeout, message}, state) do
		{id, _ ,_ } = message
		pending_confirm_messages = state[:pending_confirm_messages]
	  sent_message = findMessage(pending_confirm_messages, message)
		if(sent_message == nil) do
			Logger.info("Consumers has procees #{id}, aborting timeout")
			{:noreply, state}
		else
			Logger.info("The message is not completely consumed and the time expired")
			new_messages = List.delete(pending_confirm_messages, sent_message)
			state = Keyword.put(state, :pending_confirm_messages, new_messages)
			update_agent_state(state)
			{:noreply, state}
		end
  end

	"
	Consumers
	"

	def handle_call({:register_consumer, consumer}, _from, state) do
		Logger.info("Registering consumer #{consumer}")
		consumers = state[:consumers]
		if(Enum.member?(consumers, consumer)) do
			{:reply, :ok, state}
		else
			state = Keyword.put(state, :consumers, consumers ++ [consumer])
			update_agent_state(state)
			{:reply, :ok, state}
		end
	end

	"getters"
	def handle_call(:get_state, _from, state) do
		{:reply, state, state}
	end

	"privates"

	defp findMessage(pending_confirm_messages, {id_processed_message, _,_ }) do
		Enum.find(pending_confirm_messages, fn({{id_message, _ , _}, _}) ->
      id_processed_message == id_message
    end)
	end

	defp update_agent_state(state) do
		agent_name = QueueManager.QueueAgent.get_agent_name(state[:name])
		QueueManager.QueueAgent.set_state(QueueManager.QueueAgent.via_tuple(agent_name), state)
	end

	def via_tuple(name), do: {:via, Horde.Registry, {QueueManager.HordeRegistry, name}}

end
