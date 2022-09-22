defmodule Cosmos.Beings.NameTest do
  use ExUnit.Case

  require Logger
  alias Cosmos.Beings.Name

  test "generate dream_realm name" do
    name = Name.generate_name("dream_realm")
    assert is_list(name.parts)
    assert is_list(name.template)
    assert is_bitstring(Enum.at(Enum.at(name.parts, 0), 0))
    assert is_bitstring(Enum.at(name.template, 0))
  end

  test "generate deep_denizen name" do
    name = Name.generate_name("deep_denizen")
    assert is_map(name.parts)
    assert is_list(name.template)
    assert is_bitstring(Enum.at(Enum.at(name.parts, 0), 0))
    assert is_bitstring(Enum.at(name.template, 0))
  end

  test "generate weird_science name" do
    name = Name.generate_name("weird_science")
    assert is_map(name.parts)
    assert is_list(name.template)
    assert is_bitstring(Enum.at(Enum.at(name.parts, 0), 0))
    assert is_bitstring(Enum.at(name.template, 0))
  end

  test "weird science being all name list" do
    name_list = Name.get_all_names_list("weird_science")
    name = Enum.at(name_list, 0)
    assert name.template == ["model_name", "signifier"]
    assert length(name.parts) == 2

    name = Enum.at(name_list, 1)
    assert name.template == ["model_name", "signifier"]
    assert length(name.parts) == 2
  end

  test "all combos generation" do
    syllables_list = ["ya", "di", "do", "so"]

    assert length(Name.all_combos(syllables_list, [], 1)) == 4
    assert length(Name.all_combos(syllables_list, [], 2)) == 4 * 4 + 4
    assert length(Name.all_combos(syllables_list, [], 3)) == 4 * 4 * 4 + 4 * 4 + 4
    assert length(Name.all_combos(syllables_list, [], 4)) == 4 * 4 * 4 * 4 + 4 * 4 * 4 + 4 * 4 + 4
  end
end
