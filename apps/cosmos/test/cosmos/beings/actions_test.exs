defmodule Cosmos.Beings.ActionsTest do
  use ExUnit.Case
  doctest Cosmos.Beings.Actions

  # @moduletag :capture_log

  alias Cosmos.Beings.Being
  alias Cosmos.Beings.BeingWorker
  alias Cosmos.Beings.Actions
  alias Cosmos.Beings.Name
  alias Cosmos.Beings.Rank
  alias Cosmos.Locations.Node
  alias Cosmos.Locations.NodeWorker

  setup do
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "nodes")
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "beings")

    {:ok, beings} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "beings")
    {:ok, nodes} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "nodes")

    b = Being.get_random_being()
    # A hibernating being does not run cycle logic
    b = %{b | ichor: 100, status: "hibernating"}
    b_id = b.id

    c = Being.get_random_being()
    # alive false prevents the cycle logic from running while testing
    c = %{c | ichor: 100, status: "hibernating"}
    c_id = c.id

    Cosmos.Beings.Bucket.put(beings, b.id, b)
    Cosmos.Beings.Bucket.put(beings, c.id, c)

    n = Node.generate_random_node()
    n_id = Node.generate_id(n)
    n = %{n | id: n_id}
    m = Node.generate_random_node()
    m_id = Node.generate_id(m)
    m = %{m | id: m_id}

    Cosmos.Beings.Bucket.put(nodes, n_id, n)
    Cosmos.Beings.Bucket.put(nodes, m_id, m)

    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b.id)

    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", n.id)
    node_worker_2 = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", m.id)

    NodeWorker.connect(node_worker, m.id)
    NodeWorker.connect(node_worker_2, n.id)

    %{
      b_id: b_id,
      c_id: c_id,
      n_id: n_id,
      m_id: m_id
    }
  end

  test "harvest resources", %{b_id: b_id, n_id: n_id} do
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", n_id)
    Actions.move_to_node(b_id, n_id)
    assert BeingWorker.get(worker, :node) != nil
    resource_type = NodeWorker.get(node_worker, :resource_type)
    resource_yeild = NodeWorker.get(node_worker, :resource_yeild)
    old_resource = Map.get(BeingWorker.get(worker, :resources), resource_type)
    # nil because we did a cycle without havesting
    assert old_resource == nil

    being = BeingWorker.get(worker)
    Actions.harvest(being.id)

    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)

    new_resource = Map.get(BeingWorker.get(worker, :resources), resource_type)
    assert new_resource == resource_yeild
  end

  test "greet each other", %{b_id: b_id, c_id: c_id} do
    Actions.greet(b_id, c_id)
    assert true
  end
end
