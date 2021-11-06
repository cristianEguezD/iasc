defmodule QueueManagerTest do
  use ExUnit.Case
  doctest QueueManager

  test "greets the world" do
    assert QueueManager.hello() == :world
  end
end
