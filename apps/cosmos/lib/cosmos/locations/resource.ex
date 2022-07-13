defmodule Cosmos.Locations.Resource do
  @resource_types [
    :bones,
    :blood,
    :peat_moss,
    :tomb_mold,
    :sea_foam,
    :obsidian,
    :papyrus,
    :lotus_root,
    :soap_stone,
    :birch_bark,
    :uncanny_coal
  ]

  def get_resource_types() do
    @resource_types
  end

  def get_random_resource_type() do
    resources = get_resource_types()
    Enum.random(resources)
  end
end
