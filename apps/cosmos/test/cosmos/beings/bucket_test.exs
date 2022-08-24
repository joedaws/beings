defmodule Cosmos.BucketTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  alias Cosmos.Bucket

  setup do
    bucket = start_supervised!(Bucket)
    %{bucket: bucket}
  end

  test "stores value by key", %{bucket: bucket} do
    assert Bucket.get(bucket, "being1") == nil

    b = Cosmos.Beings.Being.get_random_being()
    b_id = "TEST_BEING"
    Bucket.put(bucket, b_id, b)
    assert Bucket.get(bucket, b_id) != nil
    assert Bucket.get(bucket, b_id).age |> is_number
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(Cosmos.Bucket, []).restart == :temporary
  end

  test "get keys", %{bucket: bucket} do
    b = Cosmos.Beings.Being.get_random_being()
    b_id = "TEST_BEING"
    Bucket.put(bucket, b_id, b)
    assert Cosmos.Bucket.keys(bucket) == ["TEST_BEING"]
  end
end
