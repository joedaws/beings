defmodule Cosmos.Beings.Bucket do
  use Agent, restart: :temporary

  @doc """
  starts new cosmos bucket
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  def keys(bucket) do
    Agent.get(bucket, fn bucket_map -> Map.keys(bucket_map) end)
  end
end
