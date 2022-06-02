defmodule Cosmos.Magic.Spell do
  alias Cosmos.Magic.Spell
  alias Cosmos.Locations.Node

  defstruct requirements: %{},
            ichor_yeild: 0

  def generate_random_spell() do
    num_requirements = :rand.uniform(2) + 1
    resource_types = for _ <- 1..num_requirements, do: Node.get_random_resource_type()

    requirements =
      for resource_type <- resource_types, into: %{}, do: {resource_type, :rand.uniform(10) + 1}

    %Spell{
      requirements: requirements,
      ichor_yeild: :rand.uniform(20) + 10
    }
  end
end
