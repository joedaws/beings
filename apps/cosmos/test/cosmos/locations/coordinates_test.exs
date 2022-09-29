defmodule Cosmos.Locations.Coordinates do
  use ExUnit.Case
  alias Cosmos.Locations.Coordinates.Spherical
  alias Cosmos.Locations.Coordinates.Convert

  require Logger

  test "convert to planar" do
    s = %Spherical{radius: 1, lambda: :math.pi() / 2, phi: :math.pi() / 8}
    p = Convert.to_planar(s)
    assert p.x != nil
    assert p.y != nil
  end
end
