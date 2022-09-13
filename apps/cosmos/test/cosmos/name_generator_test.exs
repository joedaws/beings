defmodule Cosmos.NameGeneratorTest do
  use ExUnit.Case
  alias Cosmos.NameGenerator

  test "weird science being names" do
    name = NameGenerator.get_name("beings", "weird_science")
    assert name.template == ["model_name", "signifier"]
    assert length(name.parts) == 2
  end
end
