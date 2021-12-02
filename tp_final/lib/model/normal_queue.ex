defmodule QueueManager.NormalQueue do
	use GenServer
	require Logger

	@default_timeout 10000
	@default_no_consumers 5000

	def start_link(opts) do
		GenServer.start_link(__MODULE__, {[], []})
	end

	def init(init_arg) do
		log("Normal queue up with pid: #{inspect(self)}")
		{:ok, init_arg}
	end

	"
		Messages Succefully
	"

	
	"For messages send with send_after"
	def handle_info({:process_message, message}, state) do
		handle_cast({:process_message, message}, state)
	end

	def handle_cast({:processed_message, message, _ }, {consumers, pending_confirm_messages}) do
		log("Message #{message} processed succefully")
		new_messages = List.delete(pending_confirm_messages, message)
		{:noreply, {consumers, new_messages}}
	end

	"
		Receive messages from producers
	"

	def handle_cast({:process_message, message}, {[], pending_confirm_messages}) do
		Logger.warning("NO CONSUMERS")
		Process.send_after(self, {:process_message, message}, @default_no_consumers)
		{:noreply, {[], pending_confirm_messages}}
	end

	def handle_cast({:process_message, message}, {[first_consumer | others_consumers], pending_confirm_messages}) do
		log("Message #{message} comes for processing")
		GenServer.cast(first_consumer, {:process_message_transactional, message, self})
		Process.send_after(self, {:timeout, message}, @default_timeout)
		{:noreply, {others_consumers ++ [first_consumer], pending_confirm_messages ++ [message]}}
	end

	"
		Timeout consumers response
	"

	def handle_info({:timeout, message}, {consumers, pending_confirm_messages}) do
		if(Enum.member?(pending_confirm_messages, message)) do
			log("Message #{message} has been expired")
			new_messages = List.delete(pending_confirm_messages, message)
			handle_cast({:process_message, message}, {consumers, new_messages})
		else
			log("Customer has procees #{message}, aborting timeout")
			{:noreply, {consumers, pending_confirm_messages}}
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

	def handle_call({:add_consumer, consumer}, _from, {consumers, pending_confirm_messages}) do
		{:reply, :ok, {consumers ++ [consumer], pending_confirm_messages}}
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
