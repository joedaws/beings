defmodule Cosmos.NameGeneratorTest do
  use ExUnit.Case
  alias Cosmos.NameGenerator

  test "weird science being names" do
    name = NameGenerator.get_name("beings", "weird_science")
    assert name.template == ["model_name", "signifier"]
    assert length(name.parts) == 2
  end

  test "dream realm being names" do
    name = NameGenerator.get_name("beings", "dream_realm")
    assert name.template == ["shell_name", "core_prefix", "core_name"]
    assert length(name.parts) == 3
  end
end
