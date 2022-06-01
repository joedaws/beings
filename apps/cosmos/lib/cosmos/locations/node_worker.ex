defmodule Cosmos.Locations.NodeWorker do
  use GenServer
  alias Cosmos.Locations.NodeWorker
  alias Cosmos.Beings.Bucket

  defstruct [
    :bucket_pid,
    :node_id
  ]

  # client ------------------------------
  def start_link(init_args) when is_list(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  def get(pid, attribute_type) do
    GenServer.call(pid, {:get, attribute_type})
  end

  def attach(pid, being_worker_pid) do
    GenServer.cast(pid, {:attach, being_worker_pid})
  end

  def yeild_resource(pid) do
    GenServer.call(pid, :yeild_resource)
  end

  # callbacks ---------------------------
  @impl true
  def init([bucket_pid, node_id]) do
    nw = %NodeWorker{
      bucket_pid: bucket_pid,
      node_id: node_id
    }

    {:ok, nw}
  end

  @impl true
  def handle_cast({:attach, being_worker_pid}, state) do
    node = Bucket.get(state.bucket_pid, state.node_id)
    old_occupants = node.occupants
    new_node = %{node | occupants: [being_worker_pid | old_occupants]}
    Bucket.put(state.bucket_pid, state.node_id, new_node)
    {:noreply, state}
  end

  @impl true
  def handle_call({:get, attribute_type}, _from, state) do
    node = Bucket.get(state.bucket_pid, state.node_id)
    amount = Map.get(node, attribute_type)
    {:reply, amount, state}
  end

  @impl true
  def handle_call(:yeild_resource, _from, state) do
    node = Bucket.get(state.bucket_pid, state.node_id)
    resource_type = node.resource_type
    amount = node.resource_yeild
    {:reply, {:ok, resource_type, amount}, state}
  end
end
