defmodule QueueManager.BroadCastQueue do
	use GenServer
	require Logger

	@default_no_consumers 10000
	@default_timeout 10000

	def start_link(opts) do
		name = Keyword.get(opts, :name, __MODULE__)
		log("Starting queue with name: #{name}")
		GenServer.start_link(__MODULE__, [], name: name)
	end

	def init({consumers, sended_messages}) do
    {:ok, {consumers, sended_messages}}
  end

	"mensajes procesados"

	def handle_cast({:processed_message, processed_message, consumer}, {consumers, sended_messages}) do
		Logger.info("buscando mensaje")
		{sended_message, consumers_to_notify} = findMessage(sended_messages,processed_message)
		Logger.info("message: #{sended_message} consumers: #{inspect consumers_to_notify}")
		updated_consumers_to_notify = List.delete(consumers_to_notify, consumer)
		updated_sended_messages = List.delete(sended_messages,sended_message)
		if(updated_consumers_to_notify == [] ) do
			Logger.info("todos notificados")
			{:noreply, {consumers, updated_sended_messages}}
		else
			Logger.info("falta notificar")
			updated_sended_message = {sended_message, updated_consumers_to_notify}
			{:noreply, {consumers, updated_sended_messages ++ [updated_sended_message]}}
		end

	end

	"mensajes a procesar"

	def handle_cast({:process_message, message}, {[], sended_messages}) do
		Process.send_after(self,{:process_message,message}, @default_no_consumers)
	end

	def handle_cast({:process_message, message}, {consumers, sended_messages}) do
		Enum.each(consumers, fn consumer ->
		 GenServer.cast(consumer, {:process_message_transactional, message, self})
		end)
		Process.send_after(self, {:timeout, message}, @default_timeout*length(consumers))
		new_messages = sended_messages ++ [{message,consumers}]
		Logger.info("newMessages: #{inspect new_messages}")
		{:noreply, {consumers, new_messages}}
	end

	"mensajes autoenviados"
	def handle_info({:timeout, message}, {consumers, sended_messages}) do
	  sended_message = findMessage(sended_messages,message)
		Logger.info("handle timeout. send_message: #{inspect sended_message}")
		if(sended_message == nil) do
		Logger.info("handle timeout. Mensaje completamente consumido.")
			{:noreply, {consumers, sended_messages}}
		else
			Logger.info("handle timeout. No esta completamente consumido.")
			new_messages = List.delete(sended_messages, sended_message)
			{:noreply, {consumers, new_messages}}
		end
  end

	"jetters"
	def handle_call(:get_state, _from, state) do
		{:reply, state, state}
	end

	"privates"

	defp findMessage(sended_messages,message) do
		Enum.find(sended_messages, fn({processed_message,_}) ->
      processed_message == message
    end)
	end

	defp log(message) do
		Logger.info(message)
	end

end
