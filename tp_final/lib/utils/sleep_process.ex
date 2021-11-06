defmodule QueueManager.SleepProcess do
  @moduledoc """
  Module which generates only a random number.
  """
  use GenServer
  require Logger

  alias QueueManager.{HordeRegistry}

  def child_spec(id, seconds_to_sleep) do
    %{
      id: get_process_name_from_number(id),
      start: {__MODULE__, :start_link, [id, seconds_to_sleep]},
      restart: :transient,
    }
  end

  def start_link(identifier, seconds_to_sleep) do
    name =  get_process_name_from_number(identifier)
    GenServer.start_link(__MODULE__, {identifier, seconds_to_sleep, name}, name: name)
  end

  @impl GenServer
  def init({id, timeout, name}) do
    Logger.info("scheduling for #{timeout}ms")

    register_process(name)

    Process.send_after(self(), :execute, timeout)

    {:ok, {id, timeout}}
  end

  @impl GenServer
  def handle_info(:execute, {id, timeout}) do
    execute(timeout)
    {:noreply, {id, timeout}}
  end

  @impl GenServer
  def handle_info(:terminate, {id, timeout}) do
    Logger.info("process #{id} Finishing.")
    {:stop, :normal, {id, timeout}}
  end

  @impl GenServer
  def handle_info(:stress, {id, timeout}) do
    execute(1)
    Process.send_later(self(), :stress, timeout)
    {:noreply, {id, timeout}}
  end

  def whereis_identifier(id) do
    get_process_name_from_number(id)
    |> whereis
  end

  def whereis(name) do
    name
    |> via_tuple()
    |> GenServer.whereis()
  end

  def via_tuple(name) do
    {:via, Horde.Registry, {HordeRegistry, name}}
  end

  # --- Private functions --- #

  defp register_process(name) do
    Horde.Registry.register(HordeRegistry, name, self())
  end

  defp execute(seconds_to_sleep) do
    random = :rand.uniform(10_000)

    Logger.info("#{__MODULE__} #{inspect(self())} - Starting to sleep.")

    Process.sleep(seconds_to_sleep * 1000)

    Logger.info("#{__MODULE__} #{inspect(self())} - Generating Random number ->> #{random}.")
  end

  defp get_process_name_from_number(id) do
    String.to_atom("relaxed-#{id}")
  end
end
