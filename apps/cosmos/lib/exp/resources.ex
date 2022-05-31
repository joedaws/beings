defmodule Exp.Resources do
  @typedoc """
  The types of resources that are allowed.
  - :bones
  - :blood
  - :peat_moss
  - :tomb_mold
  - :sea_foam
  - :obsidian
  - :papyrus
  - :lotus_root
  - :soap_stone
  - :birch_bark
  - :uncanny_coal
  """
  @known_resources [
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

  @type resource_type :: atom

  @type resources :: %{resource_type => integer}

  def get_random_resource() do
    Enum.random(@known_resources)
  end
end
