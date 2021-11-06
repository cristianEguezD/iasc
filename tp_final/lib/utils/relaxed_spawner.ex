defmodule RelaxedProcessesSpawner do
  @doc """
    Module for generating workers that will be using the HordeSupervisor and Registry
  """
  use GenServer
  require Logger

  alias QueueManager.{HordeSupervisor}
  alias QueueManager.{SleepProcess}

  @doc """
    Function to spawn n SleepProcess that will after some seconds, generate a random number
  """
  def perform(number, ttl) do
    start_link({number, ttl})
  end

  def stress_them(number) do
    for x <- 0..number do
      pid = SleepProcess.whereis_identifier(x)
      if pid do
        send(pid, :stress)
      end
    end
  end

  def stop(number) do
    for x <- 0..number do
      pid = SleepProcess.whereis_identifier(x)
      if pid do
        send(pid, :terminate)
      end
    end
  end

  def start_link({number, ttl}) do
    GenServer.start_link(__MODULE__, {number, ttl})
  end

  def init({number, ttl}) do
    {:ok, {number, ttl}, {:continue, :start_processes}}
  end

  @doc """
  handle_continue :start_processes to be called only when the number status has reached 0. Stop this process normally.
  """
  def handle_continue(:start_processes, {0, _}) do
    Logger.info("Shutting down this stress test process #{inspect(self())}.")
    {:stop, :normal, nil}
  end

  def handle_continue(:start_processes, {number, ttl}) do
    child_spec = SleepProcess.child_spec(number, seconds_with_jitter(ttl))
    HordeSupervisor.start_child(child_spec)

    Logger.info("started process #{number}")

    {:noreply, {number - 1, ttl}, {:continue, :start_processes}}
  end

  defp seconds_with_jitter(ttl) do
    (ttl * 0.55 + :rand.uniform(ttl) / 2)
    |> round()
  end
end

# RelaxedProcessesSpawner.perform(20,2)
# RelaxedProcessesSpawner.stop(20)
