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
		IO.inspect(message)
		{:noreply, {}}
	end

end

"""
	iex
	c("consumer.ex")
	{:ok, pid} = GenServer.start_link(Consumer, {[]})
	GenServer.cast(pid, {:processMessage, ~s({"message": "Esto es un mensaje en json"})})

"""