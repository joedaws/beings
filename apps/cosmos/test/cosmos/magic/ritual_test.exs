defmodule Cosmos.Magic.RitualTest do
  use ExUnit.Case

  @moduletag :capture_log

  alias Cosmos.Locations.Node
  alias Cosmos.Magic.Ritual

  test "generate random ritual" do
    ritual = Ritual.generate_random_ritual()
    assert ritual.ichor_yeild != 0
    assert length(Map.keys(ritual.requirements)) > 0
    assert Enum.at(Map.keys(ritual.requirements), 0) in Node.get_resource_types()
  end

  test "generate startin ritual" do
    ritual = Ritual.generate_intro_ritual([:bones, :blood, :tomb_mold])
    assert Ritual.get_min_ichor_yeild() == ritual.ichor_yeild
    assert length(Map.keys(ritual.requirements)) == 3
  end
end
