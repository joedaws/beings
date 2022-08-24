defmodule Cosmos.Beings.Actions do
  require Logger
  alias Cosmos.Beings.Being
  alias Cosmos.Bucket
  alias Cosmos.Locations.NodeWorker
  alias Cosmos.Archive.Event
  alias Cosmos.Archive.Historian

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

      Historian.record_event(
        being_id,
        Event.new("being_action", "harvested #{resource_type} from node")
      )
    else
      Logger.info("Harvest: #{inspect(being.id)} is not attached to a node")
    end
  end

  def pay_ichor(being_id) do
    being = get_being(being_id)
    old_amount = Map.get(being, :ichor)
    new_amount = old_amount - @ichor_cycle_amount

    if being.node do
      new_being =
        if new_amount <= 0 do
          Logger.info("#{inspect(being.id)} will cease to exist")
          new_being = %{being | status: "deceased", ichor: 0}
        else
          new_being = %{being | ichor: new_amount}
        end

      put_being(new_being.id, new_being)

      Historian.record_event(
        being_id,
        Event.new("being_update", "continues to exist by paying ichor")
      )
    else
      Logger.info("Pay ichor: #{inspect(being.id)} is not attached to a node")
    end
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

      Historian.record_event(
        being_id,
        Event.new("being_update", "revived from hibernation")
      )
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

      Historian.record_event(
        being_id,
        Event.new("being_update", "began hibernation")
      )
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

    Historian.record_event(
      being_id,
      Event.new("being_action", "moved to a new node")
    )
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

    other_being = get_being(other_being_id)

    Historian.record_event(
      being_id,
      Event.new(
        "being_action",
        "gave #{amount} #{resource_type} to another being, #{Being.get_full_name(other_being)}"
      )
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

    Historian.record_event(
      being_id,
      Event.new("being_action", "performed ritual and gained #{ritual.ichor_yeild} ichor")
    )
  end

  @doc """
  The first being greets the second by name

  If they don't know each other then only use names.
  """
  def greet(b1_id, b2_id) do
    b1 = get_being(b1_id)
    b2 = get_being(b2_id)

    Historian.record_event(
      b1_id,
      Event.new("being_social_interaction", "greeted another being, #{Being.get_full_name(b2)}")
    )
  end

  # Private functions --------------------------------------------------------------------------------------------------

  defp get_being(being_id) do
    bucket_name = Cosmos.BucketNameRegistry.get(being_id)
    {:ok, bucket_pid} = Cosmos.Registry.lookup(Cosmos.Registry, bucket_name)
    Bucket.get(bucket_pid, being_id)
  end

  defp put_being(being_id, being) do
    bucket_name = Cosmos.BucketNameRegistry.get(being_id)
    {:ok, bucket_pid} = Cosmos.Registry.lookup(Cosmos.Registry, bucket_name)
    Bucket.put(bucket_pid, being_id, being)
  end
end
