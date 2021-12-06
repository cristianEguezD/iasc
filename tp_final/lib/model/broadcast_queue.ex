defmodule QueueManager.BroadCastQueue do
	use GenServer
	require Logger

	@default_no_consumers 10000
	@default_timeout 10000

	def start_link(opts) do
		name = opts[:name]
		Logger.info("Starting broadcast queue with name: #{name}")
		GenServer.start_link(__MODULE__, [consumers: [], pending_confirm_messages: [], name: name], name: via_tuple(name))
	end

	def init(state) do
		Logger.info("Broadcast queue up!")
    	agent_name = QueueManager.QueueAgent.get_agent_name(state[:name])
		agent_pid = GenServer.whereis(via_tuple(agent_name))
		{:ok, state}
		if agent_pid != nil do
			initial_state = QueueManager.QueueAgent.get_state(via_tuple(name))
			{:ok, initial_state}
		end
  end

	"For messages sent when consumers are empty"
	def handle_info({:process_message, message}, state) do
		{id, _ , _} = message
		Logger.info("Re-enqueuing message #{id} since there are no consumers")
		handle_cast({:process_message, message}, state)
	end

	"mensajes procesados"
	def handle_cast({:processed_message, processed_message, consumer}, state) do
		consumers = state[:consumers]
		pending_confirm_messages = state[:pending_confirm_messages]
		message_to_delete = {sent_message, consumers_to_notify} = findMessage(pending_confirm_messages, processed_message)
		{id, _ , _} = processed_message
		Logger.info("Message #{id} processed by consumer: #{inspect consumer}")
		remaining_consumers_to_notify = List.delete(consumers_to_notify, consumer)
		remaining_pending_confirmed_messages = List.delete(pending_confirm_messages, message_to_delete)
		if(remaining_consumers_to_notify == [] ) do
			Logger.info("All consumers responded with ACK")
			state = Keyword.put(state, :pending_confirm_messages, remaining_pending_confirmed_messages)
		else
			Logger.info("There are still consumers who did not answer with ACK: #{inspect remaining_consumers_to_notify} for message #{id}")
			updated_sent_message = {sent_message, remaining_consumers_to_notify}
			state = Keyword.put(state, :pending_confirm_messages, remaining_pending_confirmed_messages ++ [{sent_message, remaining_consumers_to_notify}])
		end
		update_agent_state(state)
		{:noreply, state}
	end

	"mensajes a procesar"

	def handle_cast({:process_message, message}, state) do
		{id, _, _} = message
		consumers = state[:consumers]
		if length(consumers) == 0 do 
			Logger.warn("No consumers available in #{state[:name]}, retrying later")
			Process.send_after(self, {:process_message, message}, @default_no_consumers)
		else 
			Logger.info("Sending message #{id} to all customers: #{inspect consumers}")
			Enum.each(consumers, fn consumer ->
				GenServer.cast(Consumer.via_tuple(consumer), {:process_message_transactional, message, state[:name]})
			 end)
			 Process.send_after(self, {:timeout, message}, @default_timeout * length(consumers))
			 new_messages = state[:pending_confirm_messages] ++ [{message, consumers}]
			 state = Keyword.put(state, :pending_confirm_messages, new_messages)
			 update_agent_state(state)
		end
		{:noreply, state}
	end

	"mensajes autoenviados"
	def handle_info({:timeout, message}, state) do
		{id, _ ,_ } = message
		pending_confirm_messages = state[:pending_confirm_messages]
	  sent_message = findMessage(pending_confirm_messages, message)
		if(sent_message == nil) do
			Logger.info("Consumers has process #{id}, aborting timeout")
		else
			Logger.info("The message is not completely consumed and the time expired")
			new_messages = List.delete(pending_confirm_messages, sent_message)
			state = Keyword.put(state, :pending_confirm_messages, new_messages)
			update_agent_state(state)
		end
		{:noreply, state}
  	end

	"
	Consumers
	"

	def handle_call({:register_consumer, consumer}, _from, state) do
		Logger.info("Registering consumer #{consumer}")
		consumers = state[:consumers]
		if(Enum.member?(consumers, consumer) == false) do
			state = Keyword.put(state, :consumers, consumers ++ [consumer])
			update_agent_state(state)
		end
		{:reply, :ok, state}
	end

	"getter"
	def handle_call(:get_state, _from, state) do
		{:reply, state, state}
	end

	"privates"

	defp findMessage(pending_confirmed_messages, {id_processed_message, _, _}) do
		Enum.find(pending_confirmed_messages, fn({{id_pending_confirmed_message, _, _}, _}) ->
      		id_processed_message == id_pending_confirmed_message
    	end)
	end

	def via_tuple(name), do: {:via, Horde.Registry, {QueueManager.HordeRegistry, name}}

	defp update_agent_state(state) do
		agent_name = QueueManager.QueueAgent.get_agent_name(state[:name])
		QueueManager.QueueAgent.set_state(QueueManager.QueueAgent.via_tuple(agent_name), state)
	end

end
