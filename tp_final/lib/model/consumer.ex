defmodule Consumer do
	use GenServer
	require Logger

	def start_link() do
		GenServer.start_link(__MODULE__)
	end

	def init(state) do
		log("Consumer up with pid: #{inspect(self)}")
    {:ok, {}}
  end

	"
		Health check
	"

	def handle_call(:health_check, _from, {}) do
		log("I am alive dog")
		{:reply, :health_check, {}}
	end

	"
		Getter
	"

	def handle_call(:get_state, _from, state) do
		{:reply, state, state}
	end

	"
		Process Message
	"

	def handle_cast({:process_message_transactional, message, from}, {}) do
		process_message(message)
		GenServer.cast(from, {:processed_message, message, self})
		{:noreply, {}}
	end

	def handle_cast({:process_message_no_transactional, message, from}, {}) do
		GenServer.cast(from, {:processed_message, message, self})
		process_message(message)
		{:noreply, {}}
	end

	"
		Functions
	"

	defp process_message(message) do
		log("Message #{message} comes from queue!")
		message_processed = process(message)
		write_in_file(message_processed)
	end

	defp process(message) do
		:crypto.hash(:md5, message) |> Base.encode16()
	end

	defp write_in_file(message_processed) do
		time = :os.system_time(:nanosecond)
		pid = "#{inspect self()}"
		file_name = "#{time}-#{Node.self()}-#{pid}.data"
		File.write(file_name, message_processed)
		log("A message was processed with result in: #{file_name}")
	end

	defp log(message) do
		Logger.info(message)
	end

end
