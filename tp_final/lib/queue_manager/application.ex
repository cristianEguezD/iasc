defmodule QueueManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(), [name: MinimalExample.ClusterSupervisor]]},
      QueueManager.HordeRegistry,
      QueueManager.HordeSupervisor,
      QueueManager.NodeObserver.Supervisor,
			# { QueueManager.NormalQueue, :saraza },
      # { QueueManager.NormalQueue.Starter,[name: :cola_1]},
      { QueueManager.NormalQueue.Starter,[name: QueueManager.NormalQueue]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html for other strategies and supported options
    opts = [strategy: :one_for_one, name: QueueManager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp topologies do
    [
      horde_minimal_example: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
  end
end
