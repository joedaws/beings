defmodule Cosmos.Beings.Actions do
  require Logger
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Bucket

  @moduledoc """
  Definitions of basic actions that beings may take
  """

  def harvest(being_id) do
    being = get_being(being_id)

    if being.node do
      node_id = being.node
      node_bucket_name = Cosmos.BucketNameRegistry.get(node_id)
      node_pid = Cosmos.Locations.NodeWorkerCache.worker_process(node_bucket_name, node_id)
      {:ok, resource_type, amount} = Cosmos.Locations.NodeWorker.yeild_resource(node_pid)
      old_resource = Map.get(being.resources, resource_type, 0)

      new_being = %{
        being
        | resources: Map.put(being.resources, resource_type, old_resource + amount)
      }

      put_being(new_being.id, new_being)

      Logger.info(
        "Harvest: #{inspect(being.id)} harvested #{amount} #{resource_type} from #{inspect(being.node)}."
      )
    else
      Logger.info("Harvest: #{being.id} is not attached to a node")
    end
  end

  def pay_ichor(being_id) do
    being = get_being(being_id)
    old_amount = Map.get(being, :ichor)
    new_amount = old_amount - 1

    being =
      if new_amount <= 0 do
        Logger.info("#{inspect(being.id)} will cease to exist")
        being = %{being | alive: false}
      else
        being
      end

    new_being = %{being | ichor: new_amount}
    put_being(new_being.id, new_being)
  end

  def revive(being_id) do
    being = get_being(being_id)

    if not being.alive do
      new_being = %{being | alive: true}
      put_being(being_id, new_being)

      # start the cycle again
      bucket_name = Cosmos.BucketNameRegistry.get(being_id)
      worker_pid = Cosmos.Beings.BeingWorkerCache.worker_process(bucket_name, being_id)
      send(worker_pid, :cycle)

      Logger.info("Being #{inspect(being_id)} revived.")
    else
      Logger.info("Being #{inspect(being_id)} cannot be revived since it is currently alive.")
    end
  end

  @doc """
  The first being greets the second by name

  if they don't know each other then only use names.
  """
  def greet(b1, b2) do
    b1_says = "#{Being.get_full_name(b1)}: Hello, I'm #{Being.get_full_name(b1)}"

    b2_says = "#{Being.get_full_name(b2)}: Greetins fellow being, I'm #{Being.get_full_name(b2)}}"

    Logger.info(b1_says)
    Logger.info(b2_says)
    b1_says <> "\n" <> b2_says
  end

  @doc """
  Function to perform the transfer of commodity between two beings

  The giver gives amount of commodity to the receiver
  """
  def transfer(commodity, amount, giver, receiver) do
    # TODO add in check to make sure that giver has enough commodity to transfer
    # take commodity away from giver
    giver = %{giver | commodity => Map.get(giver, commodity) - amount}
    # give commodity to receiver
    receiver = %{receiver | commodity => Map.get(receiver, commodity) + amount}

    {:ok, giver, receiver}
  end

  defp get_being(being_id) do
    bucket_name = Cosmos.BucketNameRegistry.get(being_id)
    {:ok, bucket_pid} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket_name)
    Bucket.get(bucket_pid, being_id)
  end

  defp put_being(being_id, being) do
    bucket_name = Cosmos.BucketNameRegistry.get(being_id)
    {:ok, bucket_pid} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket_name)
    Bucket.put(bucket_pid, being_id, being)
  end
end
