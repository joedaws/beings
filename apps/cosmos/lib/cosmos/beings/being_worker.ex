defmodule Cosmos.Beings.BeingWorker do
  @moduledoc """
  Updates the being state held in the bucket
  """
  use GenServer
  require Logger
  alias Cosmos.Beings.Bucket
  alias Cosmos.Locations.NodeWorker
  alias Cosmos.Beings.Brains.Observations
  alias Cosmos.Beings.Brains.Parameters
  alias Cosmos.Beings.Brains.DecisionTree

  # defines the length of time a cycle takes in milliseconds
  @cycle_duration 1 * 1000

  defstruct [
    :bucket_pid,
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

  def attach(pid, node) do
    GenServer.cast(pid, {:attach, node})
  end

  def harvest(pid) do
    GenServer.cast(pid, :harvest)
  end

  def give_resource(pid, other_pid, resource_type, amount) do
    GenServer.cast(pid, {:give_resource, other_pid, resource_type, amount})
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
  def init([bucket_pid, being_id]) do
    bw = %Cosmos.Beings.BeingWorker{
      bucket_pid: bucket_pid,
      being_id: being_id
    }

    cycle(bw)

    {:ok, bw}
  end

  @impl true
  def handle_call({:get, attribute_type}, _from, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
    amount = Map.get(being, attribute_type)
    {:reply, amount, state}
  end

  @impl true
  def handle_cast({:update, attribute_type, new_value}, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
    new_being = %{being | attribute_type => new_value}
    Bucket.put(state.bucket_pid, state.being_id, new_being)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:revive, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
    new_being = %{being | alive: true}
    Bucket.put(state.bucket_pid, state.being_id, new_being)
    cycle(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:hibernate, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
    new_being = %{being | alive: false}
    Bucket.put(state.bucket_pid, state.being_id, new_being)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:attach, node}, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
    new_being = %{being | node: node}
    Bucket.put(state.bucket_pid, state.being_id, new_being)
    NodeWorker.attach(node, self())
    {:noreply, state}
  end

  @impl true
  def handle_cast(:harvest, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)

    if being.node do
      {:ok, resource_type, amount} = NodeWorker.yeild_resource(being.node)
      old_resource = Map.get(being.resources, resource_type, 0)

      new_being = %{
        being
        | resources: Map.put(being.resources, resource_type, old_resource + amount)
      }

      Bucket.put(state.bucket_pid, state.being_id, new_being)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:give_resource, other_pid, resource_type, amount}, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
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
    Bucket.put(state.bucket_pid, state.being_id, new_being)
    # send resource to other being
    Cosmos.Beings.BeingWorker.receive_resource(other_pid, resource_type, amount)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:receive_resource, resource_type, amount}, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
    new_amount = Map.get(being.resources, resource_type, 0) + amount
    new_being = %{being | resources: Map.put(being.resources, resource_type, new_amount)}
    Bucket.put(state.bucket_pid, state.being_id, new_being)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:move, new_node_pid}, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
    new_being = %{being | node: new_node_pid}
    Bucket.put(state.bucket_pid, state.being_id, new_being)
    {:noreply, state}
  end

  # already assumes that being has sufficient resources to perform this
  @impl true
  def handle_cast({:perform_ritual, ritual_index}, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
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
    Bucket.put(state.bucket_pid, state.being_id, new_being)
    {:noreply, state}
  end

  @impl true
  def handle_info(:cycle, state) do
    cycle(state)
    {:noreply, state}
  end

  # Private functions ---------------------------------------------------------------------

  defp cycle(bw) do
    being = Bucket.get(bw.bucket_pid, bw.being_id)

    if being.alive do
      Logger.info("#{inspect(self())} is updating being #{inspect(bw.being_id)}")
      # perform updates required each cycle
      {bw.bucket_pid, bw.being_id}
      |> pay_ichor()
      |> observe()
      |> make_decision()

      Process.send_after(self(), :cycle, @cycle_duration)
    end
  end

  defp pay_ichor({bucket_pid, being_id}) do
    being = Bucket.get(bucket_pid, being_id)
    old_amount = Map.get(being, :ichor)
    new_amount = old_amount - 1

    being =
      if new_amount <= 0 do
        Logger.info("#{inspect(being_id)} will cease to exist")
        being = %{being | alive: false}
      else
        being
      end

    new_being = %{being | ichor: new_amount}
    Bucket.put(bucket_pid, being_id, new_being)
    {bucket_pid, being_id}
  end

  @doc """
  This function let's the being collect whatever information it might
  want and is capable of obtaining.
  """
  defp observe({bucket_pid, being_id}) do
    being = Bucket.get(bucket_pid, being_id)
    node = NodeWorker.get(being.node)

    observations = %Observations{
      worker_pid: self(),
      being: being,
      node: node
    }

    {bucket_pid, being_id, observations}
  end

  defp make_decision({bucket_pid, being_id, observations}) do
    Logger.info("#{inspect(self())} will make a decision")

    parameters = %Parameters{
      ichor_threshold: 10
    }

    DecisionTree.take_action(:survival_tree, observations, parameters)
  end

  defp choose_action(policy, observations) do
    # implement
  end
end
