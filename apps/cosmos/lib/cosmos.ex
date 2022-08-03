defmodule Cosmos do
  use Application
  require Logger

  alias Cosmos.Locations.Node
  alias Cosmos.Locations.Name
  alias Cosmos.Locations.NodeWorker
  alias Cosmos.Locations.NodeWorkerCache

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    {:ok, sup_pid} = Cosmos.Beings.Supervisor.start_link(name: Cosmos.Beings.Supervisor)

    # This bucket will hold the map between entity ids and
    # the buck in which they are currently held.
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "bucket_names")
    # In order for the graph to be setup we need a place to hold nodes.
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "nodes")

    setup_graph(:basic)

    {:ok, sup_pid}
  end

  # setup a collection of nodes at start up
  def setup_graph(:basic) do
    node_types = Map.keys(Name.name_syllables())
    names = for x <- 1..12, do: Name.generate_name(Enum.random(node_types))

    generate_nodes(names)
    # in the future different options can be used
    connect_nodes(:random_lookahead)
  end

  defp generate_nodes([]) do
    Logger.info("Done setting up nodes.")
  end

  defp generate_nodes([name | tail]) do
    Logger.info("Generating node #{Name.string(name)}")
    create_node(name)
    generate_nodes(tail)
  end

  defp create_node(name) do
    node = Node.generate_node(name)
    node_id = Node.generate_id(node)
    node = %{node | id: node_id}
    {:ok, nodes} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "nodes")
    Cosmos.Beings.Bucket.put(nodes, node.id, node)

    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", node.id)
  end

  @doc """
  Each node is randomly connected to 0 or 3 of the nodes ahead
  of it as they are ordered in a list of nodes.

  For example, if the list of node names is
  [A, B, C, D]
  Then on the first step, The edges A -- B
  A -- C and A -- D.
  Edges are bidirectional.
  There is only one step in this case

  When there are 4 nodes the graph looks like
  A-B
  |\
  C D

  Note well:
  There should be 4 or more nodes for this to work.
  """
  defp connect_nodes(:random_lookahead) do
    {:ok, node_bucket} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "nodes")
    node_ids = Cosmos.Beings.Bucket.keys(node_bucket)

    build_edges(node_ids)
  end

  defp build_edges([start | tail]) do
    four_nodes = [start] ++ Enum.slice(tail, 0, 3)

    # get node workers associated with next three nodes
    four_node_workers =
      for k <- four_nodes, do: Cosmos.Locations.NodeWorkerCache.worker_process("nodes", k)

    connect(four_node_workers)

    build_edges(tail)
  end

  @doc """
  The last two nodes don't need to be connected to anything
  Since they will have already been taken care of
  """
  defp build_edges([]) do
    Logger.info("Basic nodes have been connected")
  end

  @doc """
  Given 10 nodes there will be 7 calls to connect

  XXXX______
  _XXXX_____
  __XXXX____
  ___XXXX___
  ____XXXX__
  _____XXXX_
  ______XXXX

  In general, if there are n nodes and k connections
  there will be n - k + 1 of calls to connect
  """
  defp connect([w1, w2, w3, w4]) do
    primary_node = NodeWorker.get(w1, :name)
    Logger.info("Connecting #{Name.string(primary_node)}")
    NodeWorker.connect(w1, w2)
    NodeWorker.connect(w2, w1)

    NodeWorker.connect(w1, w3)
    NodeWorker.connect(w3, w1)

    NodeWorker.connect(w1, w4)
    NodeWorker.connect(w4, w1)
  end

  defp connect([w1, w2, w3]) do
    :ok
  end

  defp connect([w1, w2]) do
    :ok
  end

  defp connect([w1]) do
    :ok
  end

  defp connect([]) do
    :ok
  end
end
