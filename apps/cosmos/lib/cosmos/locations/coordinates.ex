defmodule Cosmos.Locations.Coordinates do
  @typedoc """
  These are usual spherical coordindates
  (r, theta, phi)

  Where
  R -- radius
  lambda -- poral angle
  phi -- azimuthal angle

  Note that lambda and phi are radians
  """
  @type spherical :: {number, number, number}

  @typedoc """
  There are the planar coordinates that can be used.
  (x, y)
  """
  @type planar :: {number, number}
end
