defmodule Cosmos.Locations.Node do
  @moduledoc """
  Defines the Node concept, i.e., locations where beings interact.

  The node types determine what kinds of behavior can occur

  Note for updating the struct:
  The project rattle-snake is used to generate the starting
  state of nodes. When changing either the nodes dataclass
  in [rattle_snake.nodes](https://github.com/joedaws/rattle-snake/blob/main/rattle_snake/node.py#L6)
  or the node struct defined in this module be sure they are
  compatible changes.
  """
  require Logger
  alias Cosmos.Locations.Node
  alias Cosmos.Locations.Name
  alias Cosmos.Locations.Resource

  @default_limit 10
  @default_node_worker_module Cosmos.Locations.NodeWorker
  @default_node_bucket_name "nodes"

  defstruct [
    :name,
    :type,
    :resource_yeild,
    :resource_type,
    :x,
    :y,
    :plane,
    :stratum_id,
    :cluster_id,
    :is_population_center,
    neighbors: [],
    occupants: [],
    occupancy_limit: @default_limit,
    id: nil
  ]

  def get_name(node) do
    Name.string(node.name)
  end

  def get_random_node_type() do
    node_types = Map.keys(Name.name_syllables())
  end

  def new(
        name,
        type,
        resource_yeild,
        resource_type,
        x,
        y,
        plane,
        stratum_id,
        cluster_id,
        is_population_center,
        neighbors \\ [],
        occupants \\ [],
        occupancy_limit \\ @default_limit,
        bucket_name \\ @default_node_bucket_name
      ) do
    node = %Node{
      name: name,
      type: type,
      resource_yeild: resource_yeild,
      resource_type: resource_type,
      x: x,
      y: y,
      plane: plane,
      stratum_id: stratum_id,
      cluster_id: cluster_id,
      is_population_center: is_population_center,
      neighbors: neighbors,
      occupants: occupants,
      occupancy_limit: occupancy_limit
    }

    node_id = generate_id(node)

    entity_id_registries(node_id, bucket_name)

    %{node | id: node_id}
  end

  def generate_random_node() do
    node_type = Enum.random(get_random_node_type())
    name = Name.generate_name(node_type)
    generate_node(name)
  end

  def generate_node(name, type \\ :no_type)

  def generate_node(name, type) when type != :no_type do
    name = name
    type = type
    resource_yeild = :rand.uniform(10)
    resource_type = Resource.get_random_resource_type()
    x = 0
    y = 0
    plane = Cosmos.Plane.new("weird_science")
    stratum_id = 1
    cluster_id = 1
    is_population_center = true
    neighbors = []
    occupants = []
    occupancy_limit = @default_limit

    new(
      name,
      type,
      resource_yeild,
      resource_type,
      x,
      y,
      plane,
      stratum_id,
      cluster_id,
      is_population_center,
      neighbors,
      occupants,
      occupancy_limit
    )
  end

  def generate_node(name, type) when type == :no_type do
    name = name
    type = get_random_node_type()
    resource_yeild = :rand.uniform(10)
    resource_type = Resource.get_random_resource_type()
    x = 0
    y = 0
    plane = Cosmos.Plane.new("weird_science")
    stratum_id = 1
    cluster_id = 1
    is_population_center = true
    neighbors = []
    occupants = []
    occupancy_limit = @default_limit

    new(
      name,
      type,
      resource_yeild,
      resource_type,
      x,
      y,
      plane,
      stratum_id,
      cluster_id,
      is_population_center,
      neighbors,
      occupants,
      occupancy_limit
    )
  end

  def generate_id(node) do
    Ksuid.generate()
  end

  defp entity_id_registries(node_id, bucket_name) do
    # this allows other processes to find the bucket
    # given only the id
    Cosmos.BucketNameRegistry.register(node_id, bucket_name)
    Logger.info("Bucket name `#{bucket_name}` registered for node id #{inspect(node_id)}")
    # this allows the historian to use the correct get function
    Cosmos.EntityWorkerModuleNameRegistry.register(node_id, @default_node_worker_module)

    Logger.info(
      "Module `#{@default_node_worker_module}` registered for node id #{inspect(node_id)}"
    )
  end
end

defimpl String.Chars, for: Cosmos.Locations.Node do
  alias Cosmos.Locations.Name

  def to_string(node) do
    name_string = Name.string(node.name)

    """
    #{name_string}
      type:    #{node.type}
      resource_type: #{node.resource_type}
    """
  end
end
