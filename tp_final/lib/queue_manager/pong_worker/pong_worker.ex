defmodule QueueManager.PongWorker do
    @moduledoc """
  small module that does some trivial and schedules tasks.
  """
  use GenServer
  require Logger

  alias __MODULE__.TrivialTask

  @impl GenServer
  def init(timeout) do
    schedule_task(timeout)

    {:ok, timeout}
  end

  @default_timeout :timer.seconds(60)

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    GenServer.start_link(__MODULE__, timeout, name: name)
  end

  @impl GenServer
  def handle_call(:ping,_from, timeout) do
    {:reply, :pong, timeout}
  end

  @impl GenServer
  def handle_info(:execute, timeout) do
    log("Executing trivial task")

    Task.start(TrivialTask, :execute, [])

    log("Re-enqueuing trivial Task once more...")

    schedule_task(timeout)

    {:noreply, timeout}
  end

  # --- Client functions ---

  def ping do
    GenServer.call(__MODULE__, :ping)
  end

  # --- Private functions ---

  defp schedule_task(timeout) do
    log("scheduling for #{timeout}ms")

    Process.send_after(self(), :execute, timeout)
  end

  defp log(text) do
    Logger.info("----[#{node()}-#{inspect(self())}] #{__MODULE__} #{text}")
  end
end
