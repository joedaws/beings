defmodule Cosmos.Magic.Ritual do
  @moduledoc """
  rituals struct and functions to create them
  """
  alias Cosmos.Magic.Ritual
  alias Cosmos.Locations.Node

  @min_ichor_yeild 10

  defstruct requirements: %{},
            ichor_yeild: 0

  def generate_random_ritual() do
    num_requirements = :rand.uniform(2) + 1
    resource_types = for _ <- 1..num_requirements, do: Node.get_random_resource_type()

    requirements =
      for resource_type <- resource_types, into: %{}, do: {resource_type, :rand.uniform(10) + 1}

    %Ritual{
      requirements: requirements,
      ichor_yeild: :rand.uniform(20) + @min_ichor_yeild
    }
  end

  @doc """
  beings start out with knowledge of an intro ritual

  This ritual should be one they can perform within a few
  cycles are starting. This means that the required resources
  to perform it should be with a few steps of the starting node.

  The inputs to this function are 3 types of resources
  from near by nodes.
  """
  def generate_intro_ritual([rt1, rt2, rt3]) do
    requirements =
      for resource_type <- [rt1, rt2, rt3], into: %{}, do: {resource_type, :rand.uniform(3) + 1}

    %Ritual{
      requirements: requirements,
      ichor_yeild: @min_ichor_yeild
    }
  end

  def get_min_ichor_yeild() do
    @min_ichor_yeild
  end
end
