defmodule Cosmos.Beings.Brains.DecisionTree do
  @moduledoc """
  observations:
    - resources
    - ritual
    - ichor
    - worker_pid

  This module implements parameterized decision tree
  which being instances can use to make decisions.

  The struct determines parameters needed to
  make a decision using this decision tree

  first choice:
  - low on ichor or not

  level 2:
  - look for resourcdes
  - if not low on ichor then search for
  """
  require Logger
  alias Cosmos.Magic.Ritual
  alias Cosmos.Beings.BeingWorker
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Actions

  defstruct ichor_threshold: 10

  # first function called by the being worker
  def take_action(root_function, observations, parameters) do
    make_choice(root_function, observations, parameters)
  end

  def take_action(f) do
  end

  # this starts the very basic survival logic for a single being
  # without any cooperation needed.
  def make_choice(:survival_tree, observations, parameters) do
    make_choice(:low_on_ichor, observations, parameters)
  end

  def make_choice(:low_on_ichor, observations, parameters) do
    # check the current ichor level against ichor_threshold
    check = observations.being.ichor < parameters.ichor_threshold
    make_choice({:low_on_ichor, check}, observations, parameters)
  end

  def make_choice({:low_on_ichor, false}, observations, parameters) do
    make_choice(:find_necessary_resources, observations, parameters)
  end

  # need to perform a ritual as soon as possible
  def make_choice({:low_on_ichor, true}, observations, parameters) do
    make_choice(:can_perform_ritual, observations, parameters)
  end

  # if we have the sufficient resources go ahead and perform the ritual
  def make_choice(:can_perform_ritual, observations, parameters) do
    valid_rituals =
      for ritual <- observations.being.rituals,
          do: Ritual.sufficient_resources?(observations.being.resources, ritual)

    # can use this index later
    idx = Enum.find_index(valid_rituals, true)

    check =
      if idx == nil do
        false
      else
        true
      end

    make_choice({:can_perform_ritual, check}, observations, parameters)
  end

  # LEAF!
  # actual performs the ritual
  def make_choice({:can_perform_ritual, true}, observations, parameters) do
    worker_pid =
      Cosmos.Beings.BeingWorkerCache.worker_process(
        observations.bucket_name,
        observations.being.id
      )

    Logger.info("Decision: #{Being.get_full_name(observations.being)} will perform a ritual")

    Actions.perform_ritual(observations.being.id)
  end

  def make_choice({:can_perform_ritual, false}, observations, parameters) do
    make_choice(:find_necessary_resources, observations, parameters)
  end

  def make_choice(:find_necessary_resources, observations, parameters) do
    # find out if current node has a desired resource
    check = observations.node.resource_type in Map.keys(observations.being.resources)
    make_choice({:find_necessary_resources, check}, observations, parameters)
  end

  # LEAF!
  # being harvests from it's current node
  def make_choice({:find_necessary_resources, true}, observations, parameters) do
    worker_pid =
      Cosmos.Beings.BeingWorkerCache.worker_process(
        observations.bucket_name,
        observations.being.id
      )

    Logger.info(
      "Decision: #{Being.get_full_name(observations.being)} will harvest from its current"
    )

    Task.async(fn -> BeingWorker.harvest(worker_pid) end)
  end

  # LEAF!
  def make_choice({:find_necessary_resources, false}, observations, parameters) do
    # TODO add better choice of next node
    new_node_id = Enum.random(observations.node.neighbors)

    Logger.info(
      "Decision: #{Being.get_full_name(observations.being)} moving to new node #{inspect(new_node_id)}"
    )

    worker_pid =
      Cosmos.Beings.BeingWorkerCache.worker_process(
        observations.bucket_name,
        observations.being.id
      )

    Actions.move_to_node(observations.being.id, new_node_id)
  end

  def make_choice(:harvest, observations, _) do
    worker_pid =
      Cosmos.Beings.BeingWorkerCache.worker_process(
        observations.bucket_name,
        observations.being.id
      )

    :harvest
  end
end
