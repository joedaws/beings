defmodule Cosmos.Locations.Coordinates.Convert do
  alias Cosmos.Locations.Coordinates.Spherical
  alias Cosmos.Locations.Coordinates.Planar

  @spec to_planar(Spherical) :: Planar
  def to_planar(s) do
    %Planar{
      x: s.radius * s.lambda,
      y: s.radius * :math.log(:math.tan(:math.pi() / 4 + s.phi / 2))
    }
  end
end
