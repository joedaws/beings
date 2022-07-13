defmodule Cosmos.Locations.Node do
  @moduledoc """
  Defines the Node concept, i.e., locations where beings interact.

  The node types determine what kinds of behavior can occur
  """
  alias Cosmos.Locations.Node
  alias Cosmos.Locations.Name
  alias Cosmos.Locations.Resource

  @default_limit 10

  defstruct [
    :name,
    :type,
    :resource_yeild,
    :resource_type,
    neighbors: [],
    occupants: [],
    occupancy_limit: @default_limit
  ]

  def get_name(node) do
    Name.string(node.name)
  end

  def get_random_node_type() do
    node_types = Map.keys(Name.name_syllables())
  end

  def generate_random_node() do
    node_type = Enum.random(get_random_node_type())
    name = Name.generate_name(node_type)
    generate_node(name)
  end

  def generate_node(name, type \\ :no_type)

  def generate_node(name, type) when type != :no_type do
    node = %Node{
      name: name,
      type: type,
      resource_yeild: :rand.uniform(10),
      resource_type: Resource.get_random_resource_type(),
      occupants: [],
      occupancy_limit: @default_limit
    }
  end

  def generate_node(name, type) when type == :no_type do
    node = %Node{
      name: name,
      type: get_random_node_type(),
      resource_yeild: :rand.uniform(10),
      resource_type: Resource.get_random_resource_type(),
      occupants: [],
      occupancy_limit: @default_limit
    }
  end

  def generate_id(node) do
    :erlang.md5(get_name(node) <> (:os.system_time(:millisecond) |> to_string))
  end
end
