defmodule QueueManager.NormalQueue.Starter do
  @moduledoc """
  Module in charge of starting and monitoring  the `NormalQueue`
  process, restarting it when necessary.
  """
  require Logger

  alias QueueManager.{HordeRegistry, HordeSupervisor}
  alias QueueManager.{NormalQueue, BroadCastQueue}

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary,
    }
  end

  def start_normal_queue(opts) do
		
		child_spec = calculate_child_spec(opts, NormalQueue)

    HordeSupervisor.start_child(child_spec)

    :ignore
  end

	def start_broadcast_queue(opts) do
		
		child_spec = calculate_child_spec(opts, BroadCastQueue)

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
