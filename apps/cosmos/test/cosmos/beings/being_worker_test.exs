defmodule Cosmos.Beings.BeingWorkerTest do
  use ExUnit.Case, async: true
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

  test "get being state", %{beings: _beings, worker: worker} do
    assert 100 == BeingWorker.get(worker, :ichor)
  end

  test "update being state", %{beings: _beings, worker: worker} do
    new_ichor_amount = 300
    BeingWorker.update(worker, :ichor, new_ichor_amount)
    ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor_amount == ichor
  end

  test "ichor decrease each cycle", %{beings: _beings, worker: worker} do
    old_ichor = BeingWorker.get(worker, :ichor)
    BeingWorker.revive(worker)
    BeingWorker.hibernate(worker)
    new_ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor == old_ichor - 1
  end

  test "attach being to node", %{worker: worker, node_worker: node_worker} do
    assert BeingWorker.get(worker, :node) == nil
    BeingWorker.attach(worker, node_worker)
    assert BeingWorker.get(worker, :node) == node_worker
  end
end
