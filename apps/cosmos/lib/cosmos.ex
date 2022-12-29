defmodule Cosmos do
  use Application
  require Logger

  alias Cosmos.Beings.Actions
  alias Cosmos.Beings.Being
  alias Cosmos.Locations.Node
  alias Cosmos.Locations.Name
  alias Cosmos.Locations.NodeWorker
  alias Cosmos.Locations.NodeWorkerCache

  @nodes_database_path "start_cosmos.db"

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    {:ok, sup_pid} = Cosmos.Supervisor.start_link(name: Cosmos.Supervisor)

    # This bucket will hold the map between entity ids and
    # the buck in which they are currently held.
    Cosmos.Registry.create(Cosmos.Registry, "bucket_names")
    Cosmos.Registry.create(Cosmos.Registry, "entity_worker_names")
    # In order for the graph to be setup we need a place to hold nodes.
    Cosmos.Registry.create(Cosmos.Registry, "nodes")
    # same for beings
    Cosmos.Registry.create(Cosmos.Registry, "beings")

    # setup_nodes()
    setup_graph(:basic)
    setup_beings(:basic)

    {:ok, sup_pid}
  end

  @doc """
  Read a list of generated nodes from a sqlitedb
  """
  def setup_nodes() do
    data_path = Application.fetch_env!(:cosmos, :data_path)
    path = Path.join(data_path, @nodes_database_path)

    {:ok, conn} = Exqlite.Sqlite3.open(path)
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select * from nodes;")
    {:row, rows} = Exqlite.Sqlite3.step(conn, statement)
  end

  @doc """
  Setup basic grpah of nodes and their connections.
  """
  def setup_graph(:basic) do
    node_types = Map.keys(Name.name_syllables())
    names = for x <- 1..12, do: Name.generate_name(Enum.random(node_types))

    generate_nodes(names)
    # in the future different options can be used
    connect_nodes(:random_lookahead)
  end

  @doc """
  Setup a few initial beings at some of the locations

  Looks in the bucket "nodes" for all node ids.
  Puts one being at each of the nodes
  """
  def setup_beings(:basic) do
    {:ok, nodes} = Cosmos.Registry.lookup(Cosmos.Registry, "nodes")
    node_ids = Cosmos.Bucket.keys(nodes)
    generate_beings(node_ids)
  end

  defp generate_nodes([]) do
    Logger.info("Done generating starting nodes.")
  end

  defp generate_nodes([name | tail]) do
    create_node(name)
    generate_nodes(tail)
  end

  defp create_node(name) do
    node = Node.generate_node(name)
    {:ok, nodes} = Cosmos.Registry.lookup(Cosmos.Registry, "nodes")
    Cosmos.Bucket.put(nodes, node.id, node)

    node_worker = Cosmos.Locations.NodeWorkerCache.worker_process("nodes", node.id)
  end

  defp generate_beings([]) do
    Logger.info("Done generating starting beings.")
  end

  defp generate_beings([head | tail]) do
    create_being(head)
    generate_beings(tail)
  end

  defp create_being(node_id) do
    {:ok, beings} = Cosmos.Registry.lookup(Cosmos.Registry, "beings")
    b = Being.get_random_being()
    Cosmos.Bucket.put(beings, b.id, b)

    worker = Cosmos.Beings.BeingWorkerCache.worker_process("beings", b.id)
    Actions.move_to_node(b.id, node_id)
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
    {:ok, node_bucket} = Cosmos.Registry.lookup(Cosmos.Registry, "nodes")
    node_ids = Cosmos.Bucket.keys(node_bucket)

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
    NodeWorker.connect(w1, NodeWorker.get(w2, :id))
    NodeWorker.connect(w2, NodeWorker.get(w1, :id))

    NodeWorker.connect(w1, NodeWorker.get(w3, :id))
    NodeWorker.connect(w3, NodeWorker.get(w1, :id))

    NodeWorker.connect(w1, NodeWorker.get(w4, :id))
    NodeWorker.connect(w4, NodeWorker.get(w1, :id))
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
