defmodule Cosmos.Locations.Node do
  @moduledoc """
  Defines the Node concept, i.e., locations where beings interact.

  The node types determine what kinds of behavior can occur
  """
  alias Cosmos.Locations.Node

  @default_limit 10
  @data_path "./data"
  # TODO there might be a better way to store constants
  @node_types [:meeting_place, :resting_place, :ichor_place]

  defstruct [
    :name,
    :type,
    :ichor_supply,
    occupancy: 0,
    occupancy_limit: @default_limit
  ]

  def get_name(node) do
    "#{node.name}"
  end

  # compute the amount of ichor that can be gerenated by the node in one cycle
  def get_ichor_supply(node) do
    # TODO replace uniform with heavy left tail distribution
    5 * node.occupancy_limit + :rand.uniform(45 * node.occupancy_limit)
  end

  def set_ichor_supply(node) do
    ichor_supply = get_ichor_supply(node)
    node = %{node | ichor_supply: ichor_supply}
  end

  def get_random_node_name() do
    path = Path.join(Path.expand(@data_path), "node_name_registry.yaml")

    {:ok, types} = YamlElixir.read_from_file(path)

    Enum.random(Map.get(types, "node_name"))
  end

  def get_random_node_type() do
    Enum.random(@node_types)
  end

  def generate_random_node() do
    name = get_random_node_name()
    generate_node(name)
  end

  def generate_node(name, type \\ :no_type)

  def generate_node(name, type) when type != :no_type do
    node = %Node{
      name: name,
      type: type,
      occupancy: 0,
      occupancy_limit: @default_limit
    }

    set_ichor_supply(node)
  end

  def generate_node(name, type) when type == :no_type do
    node = %Node{
      name: name,
      type: get_random_node_type(),
      occupancy: 0,
      occupancy_limit: @default_limit
    }

    set_ichor_supply(node)
  end

  def change_occupancy(node, n \\ 1) do
    %{node | occupancy: n}
  end

  def generate_id(node) do
    :erlang.md5(get_name(node) <> (:os.system_time(:millisecond) |> to_string))
  end
end
