defmodule Cosmos.Beings.BeingWorkerTest do
  use ExUnit.Case
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.BeingWorker
  alias Cosmos.Locations.Node
  alias Cosmos.Locations.NodeWorker

  setup do
    registry = start_supervised!(Cosmos.Beings.Registry)
    Cosmos.Beings.Registry.create(registry, "beings")
    Cosmos.Beings.Registry.create(registry, "nodes")

    {:ok, beings} = Cosmos.Beings.Registry.lookup(registry, "beings")
    {:ok, nodes} = Cosmos.Beings.Registry.lookup(registry, "nodes")

    b = Being.get_random_being()
    # alive false prevents the cycle logic from running while testing
    b = %{b | ichor: 100, alive: false}
    b_id = Being.generate_id(b)

    Cosmos.Beings.Bucket.put(beings, b_id, b)

    n = Node.generate_random_node()
    n_id = Node.generate_id(n)

    Cosmos.Beings.Bucket.put(nodes, n_id, n)

    {:ok, worker} = BeingWorker.start_link([beings, b_id])

    {:ok, node_worker} = NodeWorker.start_link([nodes, n_id])

    %{beings: beings, worker: worker, node_worker: node_worker}
  end

  test "get being state", %{worker: worker} do
    assert 100 == BeingWorker.get(worker, :ichor)
  end

  test "update being state", %{worker: worker} do
    new_ichor_amount = 300
    BeingWorker.update(worker, :ichor, new_ichor_amount)
    ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor_amount == ichor
  end

  test "attach being to node", %{worker: worker, node_worker: node_worker} do
    assert BeingWorker.get(worker, :node) == nil
    BeingWorker.attach(worker, node_worker)
    assert BeingWorker.get(worker, :node) == node_worker
  end

  test "ichor decrease each cycle", %{worker: worker} do
    old_ichor = BeingWorker.get(worker, :ichor)
    BeingWorker.revive(worker)
    BeingWorker.hibernate(worker)
    new_ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor == old_ichor - 1
  end

  test "harvest resources", %{worker: worker, node_worker: node_worker} do
    BeingWorker.attach(worker, node_worker)
    assert BeingWorker.get(worker, :node) != nil
    resource_type = NodeWorker.get(node_worker, :resource_type)
    resource_yeild = NodeWorker.get(node_worker, :resource_yeild)
    old_resource = Map.get(BeingWorker.get(worker, :resources), resource_type)
    # nil because we did a cycle without the being attached to a node
    assert old_resource == nil

    BeingWorker.harvest(worker)

    new_resource = Map.get(BeingWorker.get(worker, :resources), resource_type)
    assert new_resource == resource_yeild
  end
end
