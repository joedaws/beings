defmodule Beings.Cosmos do
  use Agent

  @doc """
  starts new cosmos
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  def get(cosmos, key) do
    Agent.get(cosmos, &Map.get(&1, key))
  end

  def put(cosmos, key, value) do
    Agent.update(cosmos, &Map.put(&1, key, value))
  end
end
