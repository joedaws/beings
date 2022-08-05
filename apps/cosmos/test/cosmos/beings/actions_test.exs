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
    # setup a test being
    n1 = "Ghulop"
    n2 = "Jorsa"
    np = "L'"
    name_template = ["shell_name", "core_prefix", "core_name"]
    parts = %{"shell_name" => n1, "core_prefix" => np, "core_name" => n2}

    name = %Name{template: name_template, parts: parts}

    test_being_1 = %Being{
      name: name,
      age: 666,
      node: nil,
      ichor: 7,
      rank: Rank.get_lowest_rank()
    }

    # setup a test being
    n1 = "Shaptuwy"
    n2 = "Fe"
    np = "L'"
    name_template = ["shell_name", "core_prefix", "core_name"]
    parts = %{"shell_name" => n1, "core_prefix" => np, "core_name" => n2}

    name = %Name{template: name_template, parts: parts}

    test_being_2 = %Being{
      name: name,
      age: 3,
      ichor: 111
    }

    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "nodes")
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "beings")

    {:ok, beings} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "beings")
    {:ok, nodes} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "nodes")

    b = Being.get_random_being()
    # alive false prevents the cycle logic from running while testing
    b = %{b | ichor: 100, alive: false}
    b_id = b.id

    c = Being.get_random_being()
    # alive false prevents the cycle logic from running while testing
    c = %{c | ichor: 100, alive: false}
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
      m_id: m_id,
      test_beings: [test_being_1, test_being_2]
    }
  end

  test "harvest resources", %{b_id: b_id, n_id: n_id} do
    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", n_id)
    BeingWorker.attach(worker, n_id)
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

  test "greet each other", %{test_beings: [b1, b2]} do
    assert is_bitstring(Actions.greet(b1, b2))
  end

  test "perform transfer", %{test_beings: [b1, b2]} do
    b1_original_ichor = b1.ichor
    b2_original_ichor = b2.ichor
    amount = 3
    commodity = :ichor

    {:ok, b1, b2} = Actions.transfer(commodity, amount, b1, b2)

    assert b1.ichor == b1_original_ichor - amount
    assert b2.ichor == b2_original_ichor + amount
  end
end
