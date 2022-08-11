defmodule Cosmos.Beings.Actions do
  require Logger
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Bucket
  alias Cosmos.Locations.NodeWorker

  @ichor_cycle_amount 1

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
    new_amount = old_amount - @ichor_cycle_amount

    new_being =
      if new_amount <= 0 do
        Logger.info("#{inspect(being.id)} will cease to exist")
        new_being = %{being | status: "deceased", ichor: 0}
      else
        new_being = %{being | ichor: new_amount}
      end

    put_being(new_being.id, new_being)
  end

  def revive(being_id) do
    being = get_being(being_id)

    if being.status != "active" do
      new_being = %{being | status: "active"}
      put_being(being_id, new_being)

      # start the cycle again
      bucket_name = Cosmos.BucketNameRegistry.get(being_id)
      worker_pid = Cosmos.Beings.BeingWorkerCache.worker_process(bucket_name, being_id)
      send(worker_pid, :cycle)

      Logger.info("Being #{inspect(being_id)} revived and is now active.")
    else
      Logger.info("Being #{inspect(being_id)} cannot be revived since it is currently active.")
    end
  end

  def hibernate(being_id) do
    being = get_being(being_id)

    if being.status != "hibernating" do
      new_being = %{being | status: "hibernating"}
      put_being(being_id, new_being)
      Logger.info("Being #{inspect(being_id)} is now hiberating and is not active.")
    else
      Logger.info("Being #{inspect(being_id)} cannot hiberate since it is currently hibernating.")
    end
  end

  def move_to_node(being_id, node_id) do
    being = get_being(being_id)
    new_being = %{being | node: node_id}
    put_being(being_id, new_being)

    node_bucket_name = Cosmos.BucketNameRegistry.get(node_id)
    node_pid = Cosmos.Locations.NodeWorkerCache.worker_process(node_bucket_name, node_id)
    NodeWorker.attach(node_pid, new_being.id)
    Logger.info("Being #{inspect(being_id)} moved to node #{inspect(node_id)}")
  end

  def give_resource(being_id, other_being_id, resource_type, amount) do
    being = get_being(being_id)
    old_resource = Map.get(being.resources, resource_type)

    {give_amount, new_amount} =
      cond do
        old_resource == 0 -> {0, 0}
        old_resource - amount < 0 -> {old_resource, 0}
        true -> {amount, old_resource - amount}
      end

    # update being state
    new_being = %{being | resources: Map.put(being.resources, resource_type, new_amount)}
    put_being(being_id, new_being)

    # send amount to other being
    other_bucket_name = Cosmos.BucketNameRegistry.get(being_id)
    other_pid = Cosmos.Beings.BeingWorkerCache.worker_process(other_bucket_name, other_being_id)
    Cosmos.Beings.BeingWorker.receive_resource(other_pid, resource_type, amount)

    Logger.info(
      "Being #{inspect(being_id)} gave #{amount} #{resource_type} to #{inspect(other_being_id)}"
    )
  end

  @doc """
  already assumes that being has sufficient resources to perform the specified ritual
  """
  def perform_ritual(being_id, ritual_index \\ 0) do
    being = get_being(being_id)
    resources = being.resources
    ritual = Enum.at(being.rituals, ritual_index)

    new_resources =
      for {k, v} <- resources,
          into: %{},
          do:
            if(k in Map.keys(ritual.requirements),
              do: {k, Map.get(resources, k) - Map.get(ritual.requirements, k)},
              else: {k, v}
            )

    new_ichor = being.ichor + ritual.ichor_yeild

    new_being = %{being | resources: new_resources, ichor: new_ichor}
    put_being(being_id, new_being)
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
