defmodule Cosmos.RegistryTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  alias Cosmos.Beings.Being
  alias Cosmos.Bucket

  setup do
    registry = start_supervised!(Cosmos.Registry)
    %{registry: registry}
  end

  test "spawns bucket", %{registry: registry} do
    assert Cosmos.Registry.lookup(registry, "monoverse") == :error

    Cosmos.Registry.create(registry, "monoverse")
    assert {:ok, cosmos} = Cosmos.Registry.lookup(registry, "monoverse")

    test_being = Being.get_random_being()
    being_id = Being.generate_id(test_being)
    Bucket.put(cosmos, being_id, test_being)
    assert Bucket.get(cosmos, being_id) == test_being
  end

  test "removes buckets on exit", %{registry: registry} do
    Cosmos.Registry.create(registry, "monoverse")
    {:ok, bucket} = Cosmos.Registry.lookup(registry, "monoverse")
    Agent.stop(bucket)
    assert Cosmos.Registry.lookup(registry, "monoverse") == :error
  end

  test "remvoes bucket on crash", %{registry: registry} do
    Cosmos.Registry.create(registry, "monoverse")
    {:ok, bucket} = Cosmos.Registry.lookup(registry, "monoverse")

    # stop the bucket with non-normal reason
    Agent.stop(bucket, :shutdown)
    assert Cosmos.Registry.lookup(registry, "monoverse") == :error
  end
end
