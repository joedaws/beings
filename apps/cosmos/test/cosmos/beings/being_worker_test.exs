defmodule Cosmos.Beings.BeingWorkerTest do
  use ExUnit.Case

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
    # alive false prevents the cycle logic from running while testing
    b = %{b | ichor: 100, alive: false}

    Cosmos.Beings.Bucket.put(beings, b.id, b)

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

    %{beings: beings, worker: worker, nodes: nodes, node_worker: node_worker, n: n}
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

  test "attach being to node", %{worker: worker, n: n} do
    assert BeingWorker.get(worker, :node) == nil
    BeingWorker.attach(worker, n.id)
    assert BeingWorker.get(worker, :node) == n.id
  end

  test "ichor decrease each cycle", %{worker: worker, n: n} do
    # must be attached to node in order to cycle at the moment
    # tests don't always run in the same order
    BeingWorker.attach(worker, n.id)

    # ichor should decrease after 1 cycle
    old_ichor = BeingWorker.get(worker, :ichor)
    BeingWorker.revive(worker)
    BeingWorker.hibernate(worker)
    new_ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor == old_ichor - 1
  end

  test "harvest resources", %{worker: worker, n: n, node_worker: node_worker} do
    BeingWorker.attach(worker, n.id)
    assert BeingWorker.get(worker, :node) != nil
    resource_type = NodeWorker.get(node_worker, :resource_type)
    resource_yeild = NodeWorker.get(node_worker, :resource_yeild)
    old_resource = Map.get(BeingWorker.get(worker, :resources), resource_type)
    # nil because we did a cycle without havesting
    assert old_resource == nil

    BeingWorker.harvest(worker)

    new_resource = Map.get(BeingWorker.get(worker, :resources), resource_type)
    assert new_resource == resource_yeild
  end

  test "give resource", %{worker: worker, beings: beings} do
    b = Being.get_random_being()
    # alive false prevents the cycle logic from running while testing
    b = %{b | ichor: 100, alive: false}
    Cosmos.Beings.Bucket.put(beings, b.id, b)

    other_worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b.id)

    # we expect that the new other being has no resources
    assert BeingWorker.get(other_worker, :resources) == %{}

    # the original being should have bones
    BeingWorker.update(worker, :resources, %{bones: 10})
    amount = 5

    BeingWorker.give_resource(worker, "beings", b.id, :bones, amount)

    assert BeingWorker.get(worker, :resources) == %{bones: 5}
    assert BeingWorker.get(other_worker, :resources) == %{bones: 5}
  end

  test "receive resource", %{worker: worker} do
    # we expect that the new other being has no resources
    old_amount = Map.get(BeingWorker.get(worker, :resources), :papyrus, 0)

    # the original being should have bones
    BeingWorker.receive_resource(worker, :papyrus, 10)

    new_amount = Map.get(BeingWorker.get(worker, :resources), :papyrus, 0)

    assert new_amount == old_amount + 10
  end

  test "move to node", %{worker: worker, nodes: nodes} do
    # create new node and worker
    n = Node.generate_random_node()
    n_id = Node.generate_id(n)
    n = %{n | id: n_id}
    Cosmos.Beings.Bucket.put(nodes, n.id, n)

    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", n.id)

    old_node = BeingWorker.get(worker, :node)

    # move being to new node
    BeingWorker.move(worker, n.id)

    assert old_node != n.id
    assert BeingWorker.get(worker, :node) == n.id
  end

  test "make decision", %{worker: worker, n: n} do
    # being should be attached to a node
    BeingWorker.attach(worker, n.id)

    old_ichor = BeingWorker.get(worker, :ichor)
    BeingWorker.revive(worker)
    BeingWorker.hibernate(worker)
    new_ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor == old_ichor - 1
  end

  test "perform ritual", %{worker: worker} do
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
    BeingWorker.perform_ritual(worker)

    # upon successful completion of the ritual the ichor should have increased.
    new_ichor = BeingWorker.get(worker, :ichor)

    assert new_ichor == old_ichor + ritual.ichor_yeild
  end
end
