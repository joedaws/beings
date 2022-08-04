defmodule Cosmos.Beings.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {DynamicSupervisor, name: Cosmos.Beings.BucketSupervisor, strategy: :one_for_one},
      {DynamicSupervisor, name: Cosmos.Beings.BeingWorkerSupervisor, strategy: :one_for_one},
      {DynamicSupervisor, name: Cosmos.Locations.NodeWorkerSupervisor, strategy: :one_for_one},
      {Cosmos.Archive.Historian, name: Cosmos.Archive.Historian},
      {Cosmos.Beings.Registry, name: Cosmos.Beings.Registry},
      {Cosmos.Beings.BeingWorkerCache, name: Cosmos.Beings.BeingWorkerCache},
      {Cosmos.Locations.NodeWorkerCache, name: Cosmos.Locations.NodeWorkerCache}
    ]

    # :one_for_one means that if a child dies,
    # it will be the only one restarted.
    # :one_for_all means that if a child dies
    # all sibling processes will be stopped and
    # all children processes will be restarted
    Supervisor.init(children, strategy: :one_for_all)
  end
end
