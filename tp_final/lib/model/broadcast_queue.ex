defmodule BroadCastQueue do
	use GenServer, QueueInterface

	def start_link() do
		GenServer.start_link(__MODULE__)
	end

	def init(lola) do
    {:ok, lola}
  end

	def handle_cast({:processMessage, message}, lola) do
		{:noreply, lola}
	end

end