defmodule Producer do

	defp send_message(queue_name, message, transactional_type) do
		GenServer.cast(QueueManager.NormalQueue.via_tuple(queue_name), {:process_message, message, transactional_type})
	end

	def produce_hash_message(queue_name, id, message, transactional_type) do
		send_message(queue_name, {id, :hash, message}, transactional_type)
	end

	def produce_wait_message(queue_name, id, message, ms, transactional_type) do
		send_message(queue_name, {id, {:wait, ms}, message}, transactional_type)
	end

	def produce_n_wait_messages(queue_name, prefix_id, message, n, ms, delay_between_messages, transactional_type) do
		if n > 0 do
			produce_wait_message(queue_name, "#{prefix_id}_#{n}", message, ms, transactional_type)
			Process.sleep(delay_between_messages)
			produce_n_wait_messages(queue_name, prefix_id,  message, n - 1, ms, delay_between_messages, transactional_type)
		end
	end

end
