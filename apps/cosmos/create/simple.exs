defmodule Cosmos.Create.Simple do
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.BeingWorker
  alias Cosmos.Locations.Node
  alias Cosmos.Locations.NodeWorker

  @doc """
  Here's how the nodes are connected.
  A---B
  | / |
  |/  |
  C---D
  being starts in node A
  """
  def one_being_four_nodes() do
    registry = start_supervised!(Cosmos.Beings.Registry)
    Cosmos.Beings.Registry.create(registry, "beings")
    Cosmos.Beings.Registry.create(registry, "nodes")

    {:ok, beings} = Cosmos.Beings.Registry.lookup(registry, "beings")
    {:ok, nodes} = Cosmos.Beings.Registry.lookup(registry, "nodes")

    # being ----------------------------------------------------------
    b = Being.get_random_being()
    # hibernation prevents the being cycle from running
    b = %{b | ichor: 100, status: "hibernating"}
    b_id = Being.generate_id(b)
    Cosmos.Beings.Bucket.put(beings, b_id, b)
    {:ok, being_worker} = BeingWorker.start_link([beings, b_id])

    # nodes ----------------------------------------------------------
    a = Node.generate_random_node()
    a_id = Node.generate_id(a)

    b = Node.generate_random_node()
    b_id = Node.generate_id(b)
    c = Node.generate_random_node()
    c_id = Node.generate_id(c)
    d = Node.generate_random_node()
    d_id = Node.generate_id(d)

    Cosmos.Beings.Bucket.put(nodes, a_id, a)
    Cosmos.Beings.Bucket.put(nodes, b_id, b)
    Cosmos.Beings.Bucket.put(nodes, c_id, c)
    Cosmos.Beings.Bucket.put(nodes, d_id, d)

    {:ok, node_worker_a} = NodeWorker.start_link([nodes, a_id])
    {:ok, node_worker_b} = NodeWorker.start_link([nodes, b_id])
    {:ok, node_worker_c} = NodeWorker.start_link([nodes, c_id])
    {:ok, node_worker_d} = NodeWorker.start_link([nodes, d_id])

    # edges ---------------------------------------------------------
    NodeWorker.connect(node_worker_a, node_worker_b)
    NodeWorker.connect(node_worker_a, node_worker_c)
    NodeWorker.connect(node_worker_b, node_worker_a)
    NodeWorker.connect(node_worker_b, node_worker_c)
    NodeWorker.connect(node_worker_b, node_worker_d)
    NodeWorker.connect(node_worker_c, node_worker_a)
    NodeWorker.connect(node_worker_c, node_worker_b)
    NodeWorker.connect(node_worker_c, node_worker_d)
    NodeWorker.connect(node_worker_d, node_worker_b)
    NodeWorker.connect(node_worker_d, node_worker_c)

    # attach being ----------
    Actions.move_to_node(being_id, a_id)
  end
end

Cosmos.Create.Simple.one_being_four_nodes()
