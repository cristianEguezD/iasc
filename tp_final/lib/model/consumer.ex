defmodule Consumer do
	use GenServer

	def start_link() do
		GenServer.start_link(__MODULE__)
	end

	def init(state) do
    {:ok, {}}
  end

	def handle_call(:health_check, _from, {}) do
		{:reply, :health_check, {}}
	end

	def handle_call(:get_state, _from, state) do
		{:reply, state, state}
	end

	def handle_cast({:process_message, message, from}, {}) do
		IO.puts(message)
		message_processed = process(message)
		write_in_file(message_processed)
		GenServer.cast(from, {:processed_message, message})
		{:noreply, {}}
	end

	defp process(message) do
		:crypto.hash(:md5, message) |> Base.encode16()
	end

	defp write_in_file(message_processed) do
		time = :os.system_time(:nanosecond)
		File.write("#{time}-#{Node.self()}.data", message_processed)
	end

end

"""
	iex
	c("consumer.ex")
	{:ok, consumer} = GenServer.start_link(Consumer, {[]})
	GenServer.cast(pid, {:process_message, ~s({"message": "Esto es un mensaje en json"})})

"""