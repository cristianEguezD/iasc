defmodule QueueManager.NodeObserver do
  use GenServer
  require Logger

  alias QueueManager.{HordeRegistry, HordeSupervisor}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl GenServer
  def init(state) do
    # https://erlang.org/doc/man/net_kernel.html#monitor_nodes-1
    :net_kernel.monitor_nodes(true, node_type: :visible)

    {:ok, state}
  end

  @impl GenServer
  @doc """
  Handler that will be called when a node has left the cluster.
  """
  def handle_info({:nodedown, node, _node_type}, state) do
    Logger.info("---- Node down: #{node} ----")
    set_members(HordeRegistry)
    set_members(HordeSupervisor)

    {:noreply, state}
  end

  @impl GenServer
  @doc """
  Handler that will be called when a node has joined the cluster.
  """
  def handle_info({:nodeup, node, _node_type}, state) do
    Logger.info("---- Node up: #{node} ----")
    set_members(HordeRegistry)
    set_members(HordeSupervisor)

    {:noreply, state}
  end

  defp set_members(name) do
    members = Enum.map([Node.self() | Node.list()], &{name, &1})

    :ok = Horde.Cluster.set_members(name, members)
  end
end
