defmodule Cosmos.Magic.SpellTest do
  use ExUnit.Case
  alias Cosmos.Locations.Node
  alias Cosmos.Magic.Spell

  test "generate random spell" do
    spell = Spell.generate_random_spell()
    assert spell.ichor_yeild != 0
    assert length(Map.keys(spell.requirements)) > 0
    assert Enum.at(Map.keys(spell.requirements), 0) in Node.get_resource_types()
  end
end
