defmodule QueueManager.PongWorker.TrivialTask do
  @moduledoc """
  Module which generates only a random number.
  """
  require Logger

  def execute do
    sleep_rand = :rand.uniform(3_000)
    random = :rand.uniform(10_000)

    Process.sleep(sleep_rand)

    Logger.info("#{__MODULE__} - Generating Random number ->> #{random}.")
  end
end
