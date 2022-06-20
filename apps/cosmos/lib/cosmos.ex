defmodule Cosmos do
  use Application
  require Logger

  alias Cosmos.Locations.Node
  alias Cosmos.Locations.NodeWorker

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    {:ok, sup_pid} = Cosmos.Beings.Supervisor.start_link(name: Cosmos.Beings.Supervisor)

    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "basic_node")
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "basic_node_worker")

    setup_graph(:basic)

    {:ok, sup_pid}
  end

  # setup a collection of nodes at start up
  def setup_graph(:basic) do
    # get names of the nodes
    data_path = Application.fetch_env!(:cosmos, :data_path)
    path = Path.join(data_path, "node_name_registry.yaml")
    {:ok, node_info} = YamlElixir.read_from_file(path)
    names = Map.get(node_info, "node_name")

    generate_nodes(names)
  end

  defp generate_nodes([]) do
    Logger.info("Done setting up nodes.")
  end

  defp generate_nodes([name | tail]) do
    Logger.info("Generating node #{name}")
    create_node(name)
    generate_nodes(tail)
  end

  defp create_node(name) do
    node = Node.generate_node(name)
    node_id = Node.generate_id(node)
    {:ok, basic_node} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "basic_node")
    Cosmos.Beings.Bucket.put(basic_node, node_id, node)

    {:ok, node_worker} = NodeWorker.start_link([basic_node, node_id])

    {:ok, basic_node_worker} =
      Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "basic_node_worker")

    Cosmos.Beings.Bucket.put(basic_node_worker, node_id, node_worker)
  end
end
