defmodule Cosmos.Beings.NameTest do
  use ExUnit.Case

  require Logger
  alias Cosmos.Beings.Name

  test "generate dream_realm name" do
    name = Name.generate_name("dream_realm")
    Logger.info("#{Name.show(name)}")
    assert is_map(name.parts)
    assert is_list(name.template)
    assert is_bitstring(Enum.at(Map.keys(name.parts), 0))
    assert is_bitstring(Enum.at(name.template, 0))
  end

  test "generate deep_denizen name" do
    name = Name.generate_name("deep_denizen")
    Logger.info("#{Name.show(name)}")
    assert is_map(name.parts)
    assert is_list(name.template)
    assert is_bitstring(Enum.at(Map.keys(name.parts), 0))
    assert is_bitstring(Enum.at(name.template, 0))
  end
end
