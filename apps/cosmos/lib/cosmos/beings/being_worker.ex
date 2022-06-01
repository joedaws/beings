defmodule Cosmos.Beings.BeingWorker do
  @moduledoc """
  Updates the being state held in the bucket
  """
  use GenServer
  require Logger
  alias Cosmos.Beings.Bucket
  alias Cosmos.Locations.NodeWorker

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
    old_other_resources = Cosmos.Beings.BeingWorker.get(other_pid, :resources)
    new_other_resources = Map.put(old_other_resources, resource_type, give_amount)
    Cosmos.Beings.BeingWorker.update(other_pid, :resources, new_other_resources)
    {:noreply, state}
  end

  @impl true
  def handle_info(:cycle, state) do
    cycle(state)
    {:noreply, state}
  end

  defp cycle(bw) do
    being = Bucket.get(bw.bucket_pid, bw.being_id)

    if being.alive do
      Logger.info("#{inspect(self())} is updating being #{inspect(bw.being_id)}")
      # perform updates required each cycle
      {bw.bucket_pid, bw.being_id}
      |> pay_ichor()
      |> make_decision()

      Process.send_after(self(), :cycle, 1 * 1000)
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

  defp make_decision({bucket_pid, being_id}) do
    Logger.info("#{inspect(self())} will make a decision")
    # chose among actions that this being is capable of
  end
end
