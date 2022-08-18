defmodule Cosmos.EntityWorkerModuleNameRegistry do
  @moduledoc """
  Associates an entity id with the worker module name so that you only
  need the id to be able to call.

  Not a gen server! Don't need to start it
  """
  @registry_bucket_name "entity_worker_names"

  def register(entity_id, entity_worker_module_name) do
    {:ok, bucket} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, @registry_bucket_name)
    Cosmos.Beings.Bucket.put(bucket, entity_id, entity_worker_module_name)
  end

  def get(entity_id) do
    {:ok, bucket} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, @registry_bucket_name)
    Cosmos.Beings.Bucket.get(bucket, entity_id)
  end
end
