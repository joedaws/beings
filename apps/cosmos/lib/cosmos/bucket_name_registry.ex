defmodule Cosmos.BucketNameRegistry do
  @moduledoc """
  Assumes that the application registry already has
  a bucket by the name bucket_names

  Don't actually need to start this because it is not a genserver.
  """
  @registry_bucket_name "bucket_names"

  def register(being_id, bucket_name) do
    {:ok, bucket} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, @registry_bucket_name)
    Cosmos.Beings.Bucket.put(bucket, being_id, bucket_name)
  end

  def get(being_id) do
    {:ok, bucket} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, @registry_bucket_name)
    Cosmos.Beings.Bucket.get(bucket, being_id)
  end
end
