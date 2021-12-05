defmodule Producer do

	defp send_message(queue_name, message) do
		GenServer.cast(QueueManager.NormalQueue.via_tuple(queue_name), {:process_message, message})
	end

	def produce_hash_message(queue_name, id, message) do
		send_message(queue_name, {id, :hash, message})
	end

	def produce_wait_message(queue_name, id, message, ms) do
		send_message(queue_name, {id, {:wait, ms}, message})
	end

end
