defmodule Consumer do
	use GenServer

	def start_link() do
		GenServer.start_link(__MODULE__)
	end

	def init(state) do
    {:ok, {}}
  end

	def handle_call(:healthCheck, _from, {}) do
		{:reply, :healthCheck, {}}
	end

	def handle_cast({:processMessage, message}, {}) do
		IO.puts(message)
		message_processed = :crypto.hash(:md5, message) |> Base.encode16()
		time = :os.system_time(:nanosecond)
		File.write("#{time}-#{Node.self()}.data", message_processed)
		{:noreply, {}}
	end

end

"""
	iex
	c("consumer.ex")
	{:ok, consumer} = GenServer.start_link(Consumer, {[]})
	GenServer.cast(pid, {:processMessage, ~s({"message": "Esto es un mensaje en json"})})

"""