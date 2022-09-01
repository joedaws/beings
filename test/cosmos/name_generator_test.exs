defmodule Cosmos.NameGeneratorTest do
  use ExUnit.Case
  alias Cosmos.NameGenerator

  test "generate being name" do
    name = NameGenerator.get_name("being", "deep_denizen")
    assert name != nil
  end
end
