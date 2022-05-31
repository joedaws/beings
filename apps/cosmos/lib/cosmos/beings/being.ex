defmodule Cosmos.Beings.Being do
  require Logger

  @moduledoc """
  Beings have:
    - shell_name
    - core_prefix
    - core_name
    - ichor
    - rank
    - node
    - age
  """
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Rank
  alias Cosmos.Locations.Node

  @data_path "./data"
  @max_age 99999
  @max_ichor 99999
  @max_starting_ichor 88

  defstruct [
    :shell_name,
    :core_prefix,
    :core_name,
    :node,
    age: 0,
    ichor: 0,
    alive: true,
    rank: Rank.get_lowest_rank()
  ]

  def get_full_name(b) do
    "#{b.shell_name} #{b.core_prefix}#{b.core_name}"
  end

  def get_location_node_name_and_type(b) do
    case b.node do
      nil -> "Lost in Space"
      _ -> "#{b.node.name}: #{b.node.type}"
    end
  end

  def get_random_being() do
    # Path.expand tries to convert relative paths
    path = Path.join(Path.expand(@data_path), "being_name_registry.yaml")

    {:ok, names} = YamlElixir.read_from_file(path)

    %Being{
      shell_name: Enum.random(Map.get(names, "shell_name")),
      core_prefix: Enum.random(Map.get(names, "core_prefix")),
      core_name: Enum.random(Map.get(names, "core_name")),
      age: :rand.uniform(@max_age),
      ichor: :rand.uniform(@max_starting_ichor),
      node: nil
    }
  end

  @doc """
  Takes a being and updates the rank based on the
  beings current ichor amount.
  """
  def change_rank(being) do
    buckets = Rank.get_rank_to_ichor_bucket_map()
    # should always return only one
    [{order, interval}] =
      Enum.filter(
        buckets,
        fn {order, interval} ->
          being.ichor > Enum.at(interval, 0) and
            being.ichor < Enum.at(interval, 1)
        end
      )

    {:ok, Map.replace!(being, :rank, Rank.get_rank_from_order(order))}
  end

  @doc """
  Attaches the node to all of the beings given and
  updates the node
  """
  def occupy_node([first_being | rest_beings], accumulated_beings, node) do
    current_occupancy = node.occupancy
    node = Node.change_occupancy(node, current_occupancy + 1)
    first_being = %{first_being | node: node}
    occupy_node(rest_beings, [first_being] ++ accumulated_beings, node)
  end

  def occupy_node([], accumulated_beings, node) do
    {accumulated_beings, node}
  end

  @doc """
  Generate a md5 for hashing the beings

  time is added to the hash string so that two beings can
  have the same name without colliding in the cosmos bucket
  """
  def generate_id(being) do
    :erlang.md5(get_full_name(being) <> (:os.system_time(:millisecond) |> to_string))
  end
end
