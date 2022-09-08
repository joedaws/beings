defmodule Cosmos.NameGeneratorTest do
  use ExUnit.Case
  alias Cosmos.NameGenerator

  test "weird science being name queue" do
    name_queue = NameGenerator.get_all_names_queue("weird_science")
    name = :queue.out(name_queue)
    assert name.template == ["model_name", "signifier"]
    assert length(name.parts) == 2
  end
end
