defmodule Cosmos.Beings.BeingWorker do
  @moduledoc """
  Updates the being state held in the bucket
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

  def harvest(pid) do
    GenServer.cast(pid, :harvest)
  end

  def give_resource(pid, other_bucket_name, other_id, resource_type, amount) do
    GenServer.cast(pid, {:give_resource, other_bucket_name, other_id, resource_type, amount})
  end

  def receive_resource(pid, resource_type, amount) do
    GenServer.cast(pid, {:receive_resource, resource_type, amount})
  end

  def move(pid, new_node_pid) do
    GenServer.cast(pid, {:move, new_node_pid})
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

    cycle(bucket_name, being_id)

    {:ok, bw}
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

    # update the node
    node_bucket_name = Cosmos.BucketNameRegistry.get(node_id)
    node_pid = Cosmos.Locations.NodeWorkerCache.worker_process(node_bucket_name, node_id)
    NodeWorker.attach(node_pid, new_being.id)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:harvest, state) do
    being = get_being(state.bucket_name, state.being_id)

    if being.node do
      node_pid = Cosmos.BucketNameRegistry.get(being.node)
      {:ok, resource_type, amount} = NodeWorker.yeild_resource(node_pid)
      old_resource = Map.get(being.resources, resource_type, 0)

      new_being = %{
        being
        | resources: Map.put(being.resources, resource_type, old_resource + amount)
      }

      put_being(state.bucket_name, state.being_id, new_being)
    end

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

  @impl true
  def handle_cast({:move, new_node_pid}, state) do
    being = get_being(state.bucket_name, state.being_id)
    new_being = %{being | node: new_node_pid}
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

  # public helpers ------------------------------------------------------------------------
  def get_default_being_bucket_name() do
    @default_being_bucket_name
  end

  # Private functions ---------------------------------------------------------------------
  defp get_being(bucket_name, being_id) do
    {:ok, bucket_pid} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket_name)
    Logger.info("Got bucket PID #{inspect(bucket_pid)}")
    Bucket.get(bucket_pid, being_id)
  end

  defp put_being(bucket_name, being_id, being) do
    {:ok, bucket_pid} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket_name)
    Bucket.put(bucket_pid, being_id, being)
  end

  defp cycle(bucket_name, being_id) do
    being = get_being(bucket_name, being_id)

    if being.alive do
      Logger.info("#{inspect(self())} is updating being #{Cosmos.Beings.Name.string(being.name)}")
      # perform updates required each cycle
      # ---
      # first pay the ichor to continue living
      pay_ichor(bucket_name, being)

      # make a decision
      make_decision(bucket_name, being)

      # to simulate passage of time
      Process.send_after(self(), :cycle, @cycle_duration)
    end
  end

  defp pay_ichor(bucket_name, being) do
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
    put_being(bucket_name, being.id, new_being)
  end

  defp make_decision(bucket_name, being) do
    Logger.info("#{Cosmos.Beings.Name.string(being.name)} will make a decision")

    # TODO update to load parameters from being instance
    parameters = %Parameters{
      ichor_threshold: 10
    }

    node = NodeWorker.get(being.node)

    observations = %Observations{
      bucket_name: bucket_name,
      being: being,
      node: node
    }

    DecisionTree.take_action(:survival_tree, observations, parameters)
  end

  defp choose_action(policy, observations) do
    :not_implemented
  end
end
