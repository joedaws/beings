defmodule Cosmos.NameGeneratorTest do
  use ExUnit.Case
  alias Cosmos.NameGenerator

  test "weird science being names" do
    name = NameGenerator.get_name("beings", "weird_science")
    assert name.template == ["model_name", "signifier"]
    assert length(name.parts) == 2
    # TODO fix this
    # assert is_binary(Cosmos.Beings.Name.string(name.template, name))

    name2 = NameGenerator.get_name("beings", "weird_science")
    assert name2.template == ["model_name", "signifier"]
    assert length(name2.parts) == 2
    assert name.parts != name2.parts
  end

  test "dream realm being names" do
    name = NameGenerator.get_name("beings", "dream_realm")
    assert name.template == ["shell_name", "core_prefix", "core_name"]
    assert length(name.parts) == 3

    name2 = NameGenerator.get_name("beings", "dream_realm")
    assert name2.template == ["shell_name", "core_prefix", "core_name"]
    assert length(name2.parts) == 3
    assert name.parts != name2.parts
  end

  test "deep denizen being names" do
    name = NameGenerator.get_name("beings", "deep_denizen")
    assert name.template == ["epithet", "deep_name"]
    assert length(name.parts) == 2

    name2 = NameGenerator.get_name("beings", "deep_denizen")
    assert name2.template == ["epithet", "deep_name"]
    assert length(name2.parts) == 2
    assert name.parts != name2.parts
  end
end
