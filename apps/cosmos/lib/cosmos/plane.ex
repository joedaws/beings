defmodule Cosmos.Plane do
  @known_planes ["dream_realm", "deep_denizen", "weird_science"]

  defstruct [
    :name
  ]

  def get_known_planes do
    @known_planes
  end

  def new(name) do
    %__MODULE__{
      name: name
    }
  end
end
