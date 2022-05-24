defmodule Cosmos.Beings.RegistryTest do
  use ExUnit.Case, async: true
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Bucket

  setup do
    registry = start_supervised!(Cosmos.Beings.Registry)
    %{registry: registry}
  end

  test "spawns bucket", %{registry: registry} do
    assert Cosmos.Beings.Registry.lookup(registry, "monoverse") == :error

    Cosmos.Beings.Registry.create(registry, "monoverse")
    assert {:ok, cosmos} = Cosmos.Beings.Registry.lookup(registry, "monoverse")

    test_being = Being.get_random_being()
    being_id = Being.generate_id(test_being)
    Bucket.put(cosmos, being_id, test_being)
    assert Bucket.get(cosmos, being_id) == test_being
  end

  test "removes buckets on exit", %{registry: registry} do
    Cosmos.Beings.Registry.create(registry, "monoverse")
    {:ok, bucket} = Cosmos.Beings.Registry.lookup(registry, "monoverse")
    Agent.stop(bucket)
    assert Cosmos.Beings.Registry.lookup(registry, "monoverse") == :error
  end

  test "remvoes bucket on crash", %{registry: registry} do
    Cosmos.Beings.Registry.create(registry, "monoverse")
    {:ok, bucket} = Cosmos.Beings.Registry.lookup(registry, "monoverse")

    # stop the bucket with non-normal reason
    Agent.stop(bucket, :shutdown)
    assert Cosmos.Beings.Registry.lookup(registry, "monoverse") == :error
  end
end
