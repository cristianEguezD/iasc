defmodule QueueManager.BroadCastQueue do
	use GenServer
	require Logger

	@default_no_consumers 10000
	@default_timeout 10000

	def start_link(opts) do
		name = Keyword.get(opts, :name, __MODULE__)
		log("Starting broadcast queue with name: #{name}")
		GenServer.start_link(__MODULE__, [consumers: [], pending_confirm_messages: [], name: name], name: via_tuple(name))
	end

	def init(state) do
		log("Broadcast queue up with pid: #{inspect self()}")
    {:ok, state}
  end

	"mensajes procesados"
	def handle_cast({:processed_message, processed_message, consumer}, state) do
		consumers = state[:consumers]
		pending_confirm_messages = state[:pending_confirm_messages]
		message_to_delete = {sended_message, consumers_to_notify} = findMessage(pending_confirm_messages, processed_message)
		Logger.info("Message #{sended_message} processed by consumer: #{inspect consumer}")
		remaining_consumers_to_notify = List.delete(consumers_to_notify, consumer)
		remaining_pending_confirm_messages = List.delete(pending_confirm_messages, message_to_delete)
		if(remaining_consumers_to_notify == [] ) do
			Logger.info("All consumers responded with ACK")
			state = Keyword.put(state, :pending_confirm_messages, remaining_pending_confirm_messages)
			{:noreply, state}
		else
			Logger.info("There are still consumers who did not answer with ACK: #{inspect remaining_consumers_to_notify}")
			updated_sended_message = {sended_message, remaining_consumers_to_notify}
			state = Keyword.put(state, :pending_confirm_messages, remaining_pending_confirm_messages ++ [{sended_message, remaining_consumers_to_notify}])
			{:noreply, state}
		end

	end

	"mensajes a procesar"

	def handle_cast({:process_message, message}, state) do
		consumers = state[:consumers]
		if length(consumers) == 0 do 
			Process.send_after(self, {:process_message, message}, @default_no_consumers)
			{:noreply, state}
		else 
			Enum.each(consumers, fn consumer ->
				GenServer.cast(Consumer.via_tuple(consumer), {:process_message_transactional, message, state[:name]})
			 end)
			 Process.send_after(self, {:timeout, message}, @default_timeout * length(consumers))
			 new_messages = state[:pending_confirm_messages] ++ [{message, consumers}]
			 Logger.info("newMessages: #{inspect new_messages}")
			 state = Keyword.put(state, :pending_confirm_messages, new_messages)
			 {:noreply, state}
		end
	end

	"mensajes autoenviados"
	def handle_info({:timeout, message}, state) do
		pending_confirm_messages = state[:pending_confirm_messages]
	  sended_message = findMessage(pending_confirm_messages, message)
		if(sended_message == nil) do
			Logger.info("Consumers has procees #{message}, aborting timeout")
			{:noreply, state}
		else
			Logger.info("The message is not completely consumed and the time expired")
			new_messages = List.delete(pending_confirm_messages, sended_message)
			state = Keyword.put(state, :pending_confirm_messages, new_messages)
			{:noreply, state}
		end
  end

	"
	Consumers
	"

	def handle_call({:register_consumer, consumer}, _from, state) do
		log("Registering consumer #{consumer}")
		consumers = state[:consumers]
		state = Keyword.put(state, :consumers, consumers ++ [consumer])
		{:reply, :ok, state}
	end

	"jetters"
	def handle_call(:get_state, _from, state) do
		{:reply, state, state}
	end

	"privates"

	defp findMessage(pending_confirm_messages, processed_message) do
		Enum.find(pending_confirm_messages, fn({message, _}) ->
      processed_message == message
    end)
	end

	defp log(message) do
		Logger.info(message)
	end

	def via_tuple(name), do: {:via, Horde.Registry, {QueueManager.HordeRegistry, name}}

end
