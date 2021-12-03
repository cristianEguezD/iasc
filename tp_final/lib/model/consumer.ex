defmodule Consumer do
	use GenServer
	require Logger

	alias QueueManager.{HordeRegistry, HordeSupervisor}
  alias QueueManager.{NormalQueue}

	def start_link(opts) do
		name = opts[:name]
		log("Starting queue with name: #{name}")
		GenServer.start_link(__MODULE__, [name: name], name: via_tuple(name))
	end

	def init(state) do
		log("Consumer up with pid: #{inspect self()}")
    {:ok, state}
  end

	"
		Health check
	"

	def handle_call(:health_check, _from, state) do
		log("I am alive dog")
		{:reply, :health_check, state}
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

	def handle_cast({:process_message_transactional, message, from}, state) do
		process_name = state[:name]
		process_message(message, process_name)
		from_name = NormalQueue.via_tuple(from)
		GenServer.cast(from_name, {:processed_message, message, process_name})
		{:noreply, state}
	end

	def handle_cast({:process_message_no_transactional, message, from}, state) do
		process_name = state[:name]
		from_name = NormalQueue.via_tuple(from)
		GenServer.cast(from_name, {:processed_message, message, process_name})
		process_message(message, process_name)
		{:noreply, state}
	end

	def handle_call({:register_in_queue, queue_name}, _from, state) do
		name = state[:name]
		log("Registering in queue '#{queue_name}' consumer '#{name}'")
		register_in_queue(queue_name, name)
		{:reply, :ok, state}
	end

	"
		Functions
	"

	defp process_message(message, consumer_name) do
		log("Message #{message} comes from queue!")
		message_processed = process(message)
		write_in_file(message_processed, consumer_name)
	end

	defp process(message) do
		:crypto.hash(:md5, message) |> Base.encode16()
	end

	defp write_in_file(message_processed, consumer_name) do
		time = :os.system_time(:nanosecond)
		pid = "#{inspect self()}"
		file_name = "results/#{consumer_name}-#{Node.self()}-#{pid}-#{time}.data"
		File.write(file_name, message_processed)
		log("A message was processed with result in: #{file_name}")
	end

	defp register_in_queue(queue_name, consumer_name) do
		GenServer.call(NormalQueue.via_tuple(queue_name), {:register_consumer, consumer_name})
	end

	defp log(message) do
		Logger.info(message)
	end

	def via_tuple(name), do: {:via, Horde.Registry, {HordeRegistry, name}}

	def start_in_cluster(opts) do
		name =
      opts
      |> Keyword.get(:name, Consumer)

    opts = Keyword.put(opts, :name, name)

    child_spec = %{
      id: name,
      start: {Consumer, :start_link, [opts]}
    }

    HordeSupervisor.start_child(child_spec)

    :ignore
  end


end
