defmodule QueueManager.NormalQueue.Starter do
  @moduledoc """
  Module in charge of starting and monitoring  the `NormalQueue`
  process, restarting it when necessary.
  """
  require Logger

  alias QueueManager.{HordeRegistry, HordeSupervisor}
  alias QueueManager.{NormalQueue}

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary,
    }
  end

  def start_link(opts) do
		name =
      opts
      |> Keyword.get(:name, NormalQueue)

    opts = Keyword.put(opts, :name, name)

    child_spec = %{
      id: name,
      start: {NormalQueue, :start_link, [opts]}
    }

    HordeSupervisor.start_child(child_spec)

    :ignore
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
