defmodule Cosmos.Beings.Being do
  require Logger

  @moduledoc """
  Beings have:
    - name
    - ichor
    - rank
    - node
    - age
  """
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Rank
  alias Cosmos.Locations.Node
  alias Cosmos.Beings.Name

  @max_age 99999
  @max_ichor 99999
  @max_starting_ichor 88

  defstruct [
    :name,
    :node,
    age: 0,
    ichor: 0,
    alive: false,
    rank: Rank.get_lowest_rank(),
    resources: %{},
    rituals: []
  ]

  def get_full_name(b) do
    Name.string(b.name)
  end

  def get_location_node_name_and_type(b) do
    case b.node do
      nil -> "Lost in Space"
      _ -> "#{Name.string(b.node.name)}: #{b.node.type}"
    end
  end

  def get_random_being() do
    # TODO create centralized place for all being cultures
    being_cultures = Map.keys(Name.name_syllables())
    name = Name.generate_name(Enum.random(being_cultures))

    %Being{
      name: name,
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
  Generate a md5 for hashing the beings

  time is added to the hash string so that two beings can
  have the same name without colliding in the cosmos bucket
  """
  def generate_id(being) do
    :erlang.md5(get_full_name(being) <> (:os.system_time(:millisecond) |> to_string))
  end
end
