defmodule QueueManager.NormalQueue.Starter do
  @moduledoc """
  Module in charge of starting and monitoring  the `NormalQueue`
  process, restarting it when necessary.
  """
  require Logger

  alias QueueManager.{HordeRegistry, HordeSupervisor}
  alias QueueManager.{NormalQueue, BroadCastQueue, Consumer}

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary,
    }
  end

  def start_queue(opts, type) do

		child_spec = calculate_child_spec(opts, type)

		queue_name = child_spec[:id]
		agent_name = QueueManager.QueueAgent.get_agent_name(queue_name)
		agent_opts = [name: agent_name, initial_state: [consumers: [], pending_confirm_messages: [], name: queue_name]]

		agent_spec = calculate_child_spec(agent_opts, QueueManager.QueueAgent)

    HordeSupervisor.start_child(child_spec)
		HordeSupervisor.start_child(agent_spec)

    :ignore
  end

	def start_in_cluster(opts) do
		
		child_spec = calculate_child_spec(opts, Consumer)
		Logger.info("#{inspect child_spec}")
    HordeSupervisor.start_child(child_spec)

    :ignore
  end

	def calculate_child_spec(opts, type) do 
		name =
      opts
      |> Keyword.get(:name, type)

    opts = Keyword.put(opts, :name, name)

    %{
      id: name,
      start: {type, :start_link, [opts]}
    }
	end

  def whereis(name \\ NormalQueue) do
    name
    |> via_tuple()
    |> GenServer.whereis()
  end

  def via_tuple(name) do
    {:via, Horde.Registry, {HordeRegistry, name}}
  end
end
