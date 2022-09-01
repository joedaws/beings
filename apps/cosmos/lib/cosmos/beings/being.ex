defmodule Cosmos.Beings.Being do
  require Logger

  @default_being_bucket_name "beings"

  @default_being_worker_module Cosmos.Beings.BeingWorker

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
  @min_starting_ichor 100
  @max_starting_ichor 200

  defstruct [
    :name,
    :node,
    age: 0,
    ichor: 0,
    status: "hibernating",
    rank: Rank.get_lowest_rank(),
    resources: %{},
    rituals: [],
    id: nil
  ]

  def get_full_name(b) do
    Name.string(b.name)
  end

  def get_location_node_name_and_type(b) do
    case b.node do
      nil -> "Lost in Space"
      _ -> "#{Name.string(b.node.name)}: #{node.id}"
    end
  end

  def new(
        name,
        node,
        age \\ 0,
        ichor \\ @min_starting_ichor,
        status \\ "active",
        rank \\ Rank.get_lowest_rank(),
        resources \\ %{},
        rituals \\ [],
        bucket_name \\ @default_being_bucket_name
      ) do
    being = %Being{
      name: name,
      node: node,
      age: age,
      ichor: ichor,
      status: status,
      rank: rank,
      resources: resources,
      rituals: rituals
    }

    being_id = generate_id(being)

    entity_id_registries(being_id, bucket_name)

    being = %{being | id: being_id}
  end

  def get_random_being() do
    # TODO create centralized place for all being cultures
    being_cultures = Map.keys(Name.name_syllables())
    name = Name.generate_name(Enum.random(being_cultures))
    age = :rand.uniform(@max_age)
    ichor = @min_starting_ichor + :rand.uniform(@max_starting_ichor - @min_starting_ichor)
    node = nil
    status = "active"
    rank = Rank.get_lowest_rank()
    resources = %{}
    rituals = []
    bucket_name = @default_being_bucket_name

    new(name, node, age, ichor, status, rank, resources, rituals, bucket_name)
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
  Generate a Ksuid for the being
  """
  def generate_id(being) do
    Ksuid.generate()
  end

  def get_default_being_bucket_name() do
    @default_being_bucket_name
  end

  defp entity_id_registries(being_id, bucket_name) do
    # this allows other processes to find the bucket
    # given only the id
    Cosmos.BucketNameRegistry.register(being_id, bucket_name)
    Logger.info("Bucket name `#{bucket_name}` registered for being id #{inspect(being_id)}")
    # this allows the historian to use the correct get function
    Cosmos.EntityWorkerModuleNameRegistry.register(being_id, @default_being_worker_module)

    Logger.info(
      "Module `#{@default_being_worker_module}` registered for being id #{inspect(being_id)}"
    )
  end
end
