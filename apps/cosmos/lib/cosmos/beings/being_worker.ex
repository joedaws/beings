defmodule Cosmos.Beings.BeingWorker do
  @moduledoc """
  Updates the being state held in the bucket.

  Updating self vs interacting with others:
      The BeingWorker is responsible for updating
      its associated being. To do these updates,
      action/update functions are used. These
      functions take as input some information about the being
      and return an updated being which is then stored in the appropriate
      bucket by the being worker process.

      When interacting with other beings, the present being worker process
      will utlize the client api implemented in this module.
  """
  use GenServer, restart: :temporary
  require Logger
  alias Cosmos.Beings.Bucket
  alias Cosmos.Locations.NodeWorker
  alias Cosmos.Beings.Brains.Observations
  alias Cosmos.Beings.Brains.Parameters
  alias Cosmos.Beings.Brains.DecisionTree

  # defines the default being bucket name
  @default_being_bucket_name "beings"

  # defines the length of time a cycle takes in milliseconds
  @cycle_duration 1 * 1000

  defstruct [
    :bucket_name,
    :being_id
  ]

  # client ---------------------------------
  def start_link(init_args) when is_list(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def get(pid, attribute_type) do
    GenServer.call(pid, {:get, attribute_type})
  end

  def update(pid, attribute_type, new_value) do
    GenServer.cast(pid, {:update, attribute_type, new_value})
  end

  def revive(pid) do
    GenServer.cast(pid, :revive)
  end

  def hibernate(pid) do
    GenServer.cast(pid, :hibernate)
  end

  def attach(pid, node_id) do
    GenServer.cast(pid, {:attach, node_id})
  end

  def give_resource(pid, other_bucket_name, other_id, resource_type, amount) do
    GenServer.cast(pid, {:give_resource, other_bucket_name, other_id, resource_type, amount})
  end

  def receive_resource(pid, resource_type, amount) do
    GenServer.cast(pid, {:receive_resource, resource_type, amount})
  end

  def perform_ritual(pid, ritual_index \\ 0) do
    GenServer.cast(pid, {:perform_ritual, ritual_index})
  end

  # callbacks ------------------------------
  @impl true
  def init([bucket_name, being_id]) do
    bw = %Cosmos.Beings.BeingWorker{
      bucket_name: bucket_name,
      being_id: being_id
    }

    # this allows other processes to find the bucket
    # given only the id
    Cosmos.BucketNameRegistry.register(being_id, bucket_name)
    Logger.info("Bucket name `#{bucket_name}` registered for being id #{inspect(being_id)}")

    cycle(bucket_name, being_id)

    {:ok, bw}
  end

  @impl true
  def init([being_id]) do
    bucket_name = @default_being_bucket_name

    bw = %Cosmos.Beings.BeingWorker{
      bucket_name: bucket_name,
      being_id: being_id
    }

    # this allows other processes to find the bucket
    # given only the id
    Cosmos.BucketNameRegistry.register(being_id, bucket_name)
    Logger.info("Bucket name `#{bucket_name}` registered for being id #{inspect(being_id)}")

    cycle(bucket_name, being_id)

    {:ok, bw}
  end

  @impl true
  def handle_call(:get, _from, state) do
    being = get_being(state.bucket_name, state.being_id)
    {:reply, being, state}
  end

  @impl true
  def handle_call({:get, attribute_type}, _from, state) do
    being = get_being(state.bucket_name, state.being_id)
    amount = Map.get(being, attribute_type)
    {:reply, amount, state}
  end

  @impl true
  def handle_cast({:update, attribute_type, new_value}, state) do
    being = get_being(state.bucket_name, state.being_id)
    new_being = %{being | attribute_type => new_value}
    put_being(state.bucket_name, state.being_id, new_being)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:revive, state) do
    being = get_being(state.bucket_name, state.being_id)
    new_being = %{being | alive: true}
    put_being(state.bucket_name, state.being_id, new_being)
    cycle(state.bucket_name, state.being_id)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:hibernate, state) do
    being = get_being(state.bucket_name, state.being_id)
    new_being = %{being | alive: false}
    put_being(state.bucket_name, state.being_id, new_being)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:attach, node_id}, state) do
    # update the being
    being = get_being(state.bucket_name, state.being_id)
    new_being = %{being | node: node_id}
    put_being(state.bucket_name, state.being_id, new_being)

    # node_id has already been generated
    node_bucket_name = Cosmos.BucketNameRegistry.get(node_id)
    node_pid = Cosmos.Locations.NodeWorkerCache.worker_process(node_bucket_name, node_id)
    NodeWorker.attach(node_pid, new_being.id)
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:give_resource, other_bucket_name, other_being_id, resource_type, amount},
        state
      ) do
    being = get_being(state.bucket_name, state.being_id)
    # check to make sure that this being has enough resource to give
    old_resource = Map.get(being.resources, resource_type)

    {give_amount, new_amount} =
      cond do
        old_resource == 0 -> {0, 0}
        old_resource - amount < 0 -> {old_resource, 0}
        true -> {amount, old_resource - amount}
      end

    # update being state
    new_being = %{being | resources: Map.put(being.resources, resource_type, new_amount)}
    put_being(state.bucket_name, state.being_id, new_being)

    # send resource to other being
    other_pid = Cosmos.Beings.BeingWorkerCache.worker_process(other_bucket_name, other_being_id)
    Cosmos.Beings.BeingWorker.receive_resource(other_pid, resource_type, amount)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:receive_resource, resource_type, amount}, state) do
    being = get_being(state.bucket_name, state.being_id)
    new_amount = Map.get(being.resources, resource_type, 0) + amount
    new_being = %{being | resources: Map.put(being.resources, resource_type, new_amount)}
    put_being(state.bucket_name, state.being_id, new_being)
    {:noreply, state}
  end

  # already assumes that being has sufficient resources to perform this
  @impl true
  def handle_cast({:perform_ritual, ritual_index}, state) do
    being = get_being(state.bucket_name, state.being_id)
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
    put_being(state.bucket_name, state.being_id, new_being)
    {:noreply, state}
  end

  @impl true
  def handle_info(:cycle, state) do
    being = get_being(state.bucket_name, state.being_id)
    cycle(state.bucket_name, state.being_id)
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.info("Unexpected message in Cosmos.Beings.BeingWorker: #{inspect(msg)}")
    {:noreply, state}
  end

  # public helpers ------------------------------------------------------------------------
  def get_default_being_bucket_name() do
    @default_being_bucket_name
  end

  # Private functions ---------------------------------------------------------------------
  defp get_being(bucket_name, being_id) do
    {:ok, bucket_pid} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket_name)
    Bucket.get(bucket_pid, being_id)
  end

  defp put_being(bucket_name, being_id, being) do
    {:ok, bucket_pid} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket_name)
    Bucket.put(bucket_pid, being_id, being)
  end

  defp cycle(bucket_name, being_id) do
    being = get_being(bucket_name, being_id)

    if being.alive do
      # perform updates required each cycle
      # ---
      # first pay the ichor to continue living
      Cosmos.Beings.Actions.pay_ichor(being.id)

      # make a decision
      # TODO replace with DecisionTree call
      Cosmos.Beings.Actions.harvest(being.id)

      # to simulate passage of time
      Process.send_after(self(), :cycle, @cycle_duration)
    end
  end

  defp make_decision(:survival_tree, bucket_name, being) do
    # Logger.info("#{Cosmos.Beings.Name.string(being.name)} will make a decision")

    # TODO update to load parameters from being instance
    parameters = %Parameters{
      ichor_threshold: 10
    }

    node_id = being.node
    node_bucket_name = Cosmos.BucketNameRegistry.get(node_id)
    node_pid = Cosmos.Locations.NodeWorkerCache.worker_process(node_bucket_name, node_id)
    node = NodeWorker.get(node_pid)

    observations = %Observations{
      bucket_name: bucket_name,
      being: being,
      node: node
    }

    DecisionTree.take_action(:survival_tree, observations, parameters)
  end

  defp make_decision(:harvest, bucket_name, being) do
    observations = %Observations{
      bucket_name: bucket_name,
      being: being,
      node: node
    }

    parameters = %{}
    DecisionTree.take_action(:harvest, observations, parameters)
  end

  defp choose_action(policy, observations) do
    :not_implemented
  end
end
