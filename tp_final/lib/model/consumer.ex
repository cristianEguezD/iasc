defmodule Consumer do
	use GenServer
	require Logger

	alias QueueManager.{HordeRegistry, HordeSupervisor}
  alias QueueManager.{NormalQueue}

	def start_link(opts) do
		name = opts[:name]
		Logger.info("Starting consumer with name: #{name}")
		GenServer.start_link(__MODULE__, [name: name], name: via_tuple(name))
	end

	def init(state) do
		Logger.info("Consumer up!")
    {:ok, state}
  end

	"
		Health check
	"

	def handle_call(:health_check, _from, state) do
		Logger.info("I am alive dog")
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
		Logger.info("Registering in queue '#{queue_name}' consumer '#{name}'")
		register_in_queue(queue_name, name)
		{:reply, :ok, state}
	end

	"
		Functions
	"

	"
		Process hash message
	"
	defp process_message({id, :hash, content}, consumer_name) do
		Logger.info("Message #{id} comes from queue for hashing!")
		message_processed = process(content)
		write_in_file(message_processed, consumer_name, id)
	end

	defp process(message) do
		:crypto.hash(:md5, message) |> Base.encode16()
	end

	defp write_in_file(message_processed, consumer_name, message_id) do
		time = :os.system_time(:nanosecond)
		pid = "#{inspect self()}"
		file_name = "results/#{consumer_name}-#{message_id}-#{Node.self()}-#{pid}-#{time}.data"
		File.write(file_name, message_processed)
		Logger.info("Message #{message_id} was processed with result in: #{file_name}")
	end

	"
		Process wait and hash message
	"
	defp process_message({id, {:wait, ms}, content}, consumer_name) do
		Logger.info("Message #{id} comes from queue for wait and hashing!")
		Process.sleep(ms)
		message_processed = process(content)
		write_in_file(message_processed, consumer_name, id)
	end

	defp register_in_queue(queue_name, consumer_name) do
		GenServer.call(NormalQueue.via_tuple(queue_name), {:register_consumer, consumer_name})
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
