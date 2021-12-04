defmodule QueueManager.QueueAgent do
	use Agent
	require Logger

	def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary,
    }
  end

	def start_link(opts) do
		name = Keyword.get(opts, :name, __MODULE__)
		state = Keyword.get(opts, :initial_state)
		Logger.info("Queue agent start with name: #{name}")
    Agent.start_link(fn -> [name: name, state: state] end, name: via_tuple(name))
  end

	def get_agent_name(queue_name) do
		:"#{queue_name}_agent"
	end

  def get_state(agent) do
    Agent.get(agent, fn state -> state end)
  end

  def set_state(agent, new_state) do
    Agent.update(agent, fn state -> new_state end)
  end

	def via_tuple(name), do: {:via, Horde.Registry, {QueueManager.HordeRegistry, name}}

end