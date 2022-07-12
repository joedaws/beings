defmodule Cosmos.Locations.NameTest do
  use ExUnit.Case

  require Logger
  alias Cosmos.Locations.Name

  test "generate warped_nature name" do
    name = Name.generate_name("warped_nature")
    Logger.info("#{Name.string(name)}")
    assert is_map(name.parts)
    assert is_list(name.template)
    assert is_bitstring(Enum.at(Map.keys(name.parts), 0))
    assert is_bitstring(Enum.at(name.template, 0))
  end

  test "generate human_built name" do
    name = Name.generate_name("human_built")
    Logger.info("#{Name.string(name)}")
    assert is_map(name.parts)
    assert is_list(name.template)
    assert is_bitstring(Enum.at(Map.keys(name.parts), 0))
    assert is_bitstring(Enum.at(name.template, 0))
  end

  test "generate dream_place name" do
    name = Name.generate_name("dream_place")
    Logger.info("#{Name.string(name)}")
    assert is_map(name.parts)
    assert is_list(name.template)
    assert is_bitstring(Enum.at(Map.keys(name.parts), 0))
    assert is_bitstring(Enum.at(name.template, 0))
  end
end
