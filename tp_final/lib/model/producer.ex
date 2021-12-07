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

	def produce_n_wait_messages(queue_name, prefix_id, message, n, ms, delay_between_messages) do
		produce_wait_message(queue_name, "#{prefix_id}_#{n}", message, ms)
		if n > 0 do
			Process.sleep(delay_between_messages)
			produce_n_wait_messages(queue_name, prefix_id,  message, n - 1, ms, delay_between_messages)
		end
	end

end
