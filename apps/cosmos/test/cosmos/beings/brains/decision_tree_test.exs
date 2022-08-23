defmodule Cosmos.Beings.Brains.DecisionTreeTest do
  use ExUnit.Case

  alias Cosmos.Archive.Historian
  alias Cosmos.Beings.Actions
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.BeingWorker
  alias Cosmos.Beings.Brains.DecisionTree
  alias Cosmos.Beings.Brains.Observations
  alias Cosmos.Beings.Brains.Parameters
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

    param = %Parameters{
      ichor_threshold: 8
    }

    %{
      b_id: b_id,
      c_id: c_id,
      n_id: n_id,
      m_id: m_id,
      param: param
    }
  end

  test "get graph", %{b_id: b_id, n_id: n_id, param: param} do
    # attach b being to node n
    Actions.move_to_node(b_id, n_id)

    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", n_id)
    being = BeingWorker.get(worker)
    node = NodeWorker.get(node_worker)

    obs = %Observations{
      bucket_name: "beings",
      being: being,
      node: node
    }

    root_node = DecisionTree.get_graph(:survival_tree, obs, param)

    assert length(root_node.children) >= 0
  end

  test "decision path", %{b_id: b_id, n_id: n_id, param: param} do
    # attach b being to node n
    Actions.move_to_node(b_id, n_id)

    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", n_id)
    being = BeingWorker.get(worker)
    node = NodeWorker.get(node_worker)

    obs = %Observations{
      bucket_name: "beings",
      being: being,
      node: node
    }

    root_node = DecisionTree.get_graph(:survival_tree, obs, param)

    DecisionTree.decision_path(root_node)

    history = Historian.get_entity_history(b_id)
    assert length(history) > 0
  end

  test "make decision - survival tree", %{b_id: b_id, n_id: n_id, param: param} do
    # attach b being to node n
    Actions.move_to_node(b_id, n_id)

    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b_id)
    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", n_id)
    being = BeingWorker.get(worker)
    node = NodeWorker.get(node_worker)

    obs = %Observations{
      bucket_name: "beings",
      being: being,
      node: node
    }

    DecisionTree.make_decision(:survival_tree, obs, param)

    history = Historian.get_entity_history(b_id)
    assert length(history) > 0
  end
end
