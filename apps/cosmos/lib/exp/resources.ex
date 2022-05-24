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
  @type resource_type :: atom

  @type resources :: %{resource_type => integer}
end
