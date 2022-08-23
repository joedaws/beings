defmodule Cosmos.Beings.BeingWorkerTest do
  use ExUnit.Case

  alias Cosmos.Beings.Actions
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.BeingWorker
  alias Cosmos.Locations.Node
  alias Cosmos.Locations.NodeWorker
  alias Cosmos.Magic.Ritual

  setup do
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "nodes")
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "beings")

    {:ok, beings} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "beings")
    {:ok, nodes} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "nodes")

    b = Being.get_random_being()
    # hibernation prevents the cycle from running
    b = %{b | ichor: 100}
    b_id = b.id

    c = Being.get_random_being()
    # hibernation prevents the cycle from running
    c = %{c | ichor: 100}
    c_id = c.id

    Cosmos.Beings.Bucket.put(beings, b.id, b)
    Cosmos.Beings.Bucket.put(beings, c.id, c)

    n = Node.generate_random_node()
    n_id = n.id
    m = Node.generate_random_node()
    m_id = m.id

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

  test "get being state", %{b_id: b_id} do
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    assert BeingWorker.get(worker, :ichor) > 0
  end

  test "update being state", %{b_id: b_id} do
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    new_ichor_amount = 300
    BeingWorker.update(worker, :ichor, new_ichor_amount)
    ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor_amount == ichor
  end

  test "attach being to node", %{b_id: b_id, n_id: n_id} do
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    BeingWorker.update(worker, :node, nil)
    assert BeingWorker.get(worker, :node) == nil
    Actions.move_to_node(b_id, n_id)
    assert BeingWorker.get(worker, :node) == n_id
  end

  test "ichor decrease each cycle", %{b_id: b_id, n_id: n_id} do
    Actions.move_to_node(b_id, n_id)
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", n_id)
    being = BeingWorker.get(worker)
    node = NodeWorker.get(node_worker)
    # must be attached to node in order to cycle at the moment
    # tests don't always run in the same order
    Actions.hibernate(b_id)
    Actions.revive(b_id)
    new_ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor < 100
  end

  test "give resource", %{b_id: b_id, c_id: c_id} do
    worker1 = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    worker2 = Cosmos.Beings.BeingWorkerCache.worker_process("beings", c_id)

    # we expect that the new other being has no resources
    assert BeingWorker.get(worker2, :resources) == %{}

    # the original being should have bones
    new_being = BeingWorker.update(worker1, :resources, %{bones: 10})
    amount = 5

    Actions.give_resource(b_id, c_id, :bones, amount)

    assert BeingWorker.get(worker1, :resources) == %{bones: 5}
    assert BeingWorker.get(worker2, :resources) == %{bones: 5}
  end

  test "receive resource", %{b_id: b_id} do
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    # we expect that the new other being has no resources
    old_amount = Map.get(BeingWorker.get(worker, :resources), :papyrus, 0)

    # the original being should have bones
    BeingWorker.receive_resource(worker, :papyrus, 10)

    new_amount = Map.get(BeingWorker.get(worker, :resources), :papyrus, 0)

    assert new_amount == old_amount + 10
  end

  test "move to node", %{b_id: b_id, m_id: m_id, n_id: n_id} do
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)

    # move being to new node
    Actions.move_to_node(b_id, n_id)
    assert BeingWorker.get(worker, :node) == n_id

    # move being to new node
    Actions.move_to_node(b_id, m_id)
    assert BeingWorker.get(worker, :node) == m_id
  end

  test "make decision", %{b_id: b_id, n_id: n_id} do
    Actions.move_to_node(b_id, n_id)
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", n_id)
    being = BeingWorker.get(worker)
    node = NodeWorker.get(node_worker)
    # hibernate then revive to run 1 cycle
    Actions.hibernate(b_id)
    Actions.revive(b_id)
    new_ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor < 100
  end

  test "perform ritual", %{b_id: b_id} do
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    # add ritual to being
    ritual = Ritual.generate_random_ritual()
    BeingWorker.update(worker, :rituals, [ritual])
    old_ichor = BeingWorker.get(worker, :ichor)

    resources = BeingWorker.get(worker, :resources)
    # give being sufficient resources to perform a ritual
    new_resources =
      for {k, v} <- resources,
          into: %{},
          do:
            if(k in Map.keys(ritual.requirements),
              do: {k, Map.get(ritual.requirements, k)},
              else: {k, v}
            )

    BeingWorker.update(worker, :resources, new_resources)

    # To change both the ichor and resources of the being, the worker performs the ritual
    Actions.perform_ritual(b_id)

    # upon successful completion of the ritual the ichor should have increased.
    new_ichor = BeingWorker.get(worker, :ichor)

    assert new_ichor == old_ichor + ritual.ichor_yeild
  end
end
