defmodule Registers.CosmosRegistryTest do
  use ExUnit.Case, async: true

  setup do
    registry = start_supervised!(Registers.CosmosRegistry)
    %{registry: registry}
  end

  test "spawns cosmoses", %{registry: registry} do
    assert Registers.CosmosRegistry.lookup(registry, "monoverse") == :error

    Registers.CosmosRegistry.create(registry, "monoverse")
    assert {:ok, cosmos} = Registers.CosmosRegistry.lookup(registry, "monoverse")

    test_being = Being.get_random_being()
    being_id = Being.generate_id(test_being)
    Cosmos.put(cosmos, being_id, test_being)
    assert Cosmos.get(cosmos, being_id) == test_being
  end

  test "removes cosmos on exit", %{registry: registry} do
    Registers.CosmosRegistry.create(registry, "monoverse")
    {:ok, cosmos} = Registers.CosmosRegistry.lookup(registry, "monoverse")
    Agent.stop(cosmos)
    assert Registers.CosmosRegistry.lookup(registry, "monoverse") == :error
  end
end
