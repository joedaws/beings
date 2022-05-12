defmodule Cosmos.Beings.BucketTest do
  use ExUnit.Case, async: true
  alias Cosmos.Beings.Bucket

  setup do
    bucket = start_supervised!(Bucket)
    %{bucket: bucket}
  end

  test "stores value by key", %{bucket: bucket} do
    assert Bucket.get(bucket, "being1") == nil

    b = Cosmos.Beings.Being.get_random_being()
    Bucket.put(bucket, 234, b)
    assert Bucket.get(bucket, 234) != nil
    assert Bucket.get(bucket, 234).age |> is_number
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(Cosmos.Beings.Bucket, []).restart == :temporary
  end
end
