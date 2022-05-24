defmodule Cosmos.Beings.Rank do
  alias Cosmos.Beings.Rank

  @rank_map %{
    1 => "Old One",
    2 => "Minister of the Deep",
    3 => "Attendant of the Dead",
    4 => "Doom Acolyte",
    5 => "Ghast"
  }

  @ichor_absorption_map %{
    1 => 100,
    2 => 50,
    3 => 25,
    4 => 10,
    5 => 5
  }

  # inclusive boundaries of ichor that define the ranks
  @rank_to_ichor_bucket_map %{
    1 => [1000, nil],
    2 => [800, 999],
    3 => [500, 799],
    4 => [100, 499],
    5 => [0, 99]
  }

  # defines the lowest rank by setting order
  @lowest_order 5

  # be sure that these are consistant with the rank_map
  # right now the default rank is the lowest possible
  defstruct name: "Ghast",
            order: 5

  def get_rank_from_order(order) do
    %Rank{name: Map.get(@rank_map, order), order: order}
  end

  def get_lowest_rank() do
    %Rank{name: Map.get(@rank_map, @lowest_order), order: @lowest_order}
  end

  def get_abosoprtion_map() do
    @ichor_absorption_map
  end

  def get_rank_to_ichor_bucket_map() do
    @rank_to_ichor_bucket_map
  end
end
