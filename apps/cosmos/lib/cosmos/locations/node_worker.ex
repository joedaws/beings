defmodule Cosmos.Locations.NodeWorker do
  use GenServer, restart: :temporary
  alias Cosmos.Locations.NodeWorker
  alias Cosmos.Beings.Bucket

  defstruct [
    :bucket_name,
    :node_id
  ]

  @default_node_bucket_name "nodes"

  # client ------------------------------
  def start_link(init_args) when is_list(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  def get(pid, attribute_type \\ nil) do
    # get the process id
    GenServer.call(pid, {:get, attribute_type})
  end

  def connect(pid, new_neighbor_id) do
    GenServer.cast(pid, {:connect, new_neighbor_id})
  end

  def attach(pid, being_id) do
    GenServer.cast(pid, {:attach, being_id})
  end

  def yeild_resource(pid) do
    GenServer.call(pid, :yeild_resource)
  end

  # callbacks ---------------------------
  @impl true
  def init([bucket_name, node_id]) do
    nw = %NodeWorker{
      bucket_name: bucket_name,
      node_id: node_id
    }

    Cosmos.BucketNameRegistry.register(node_id, bucket_name)

    {:ok, nw}
  end

  @impl true
  def init([node_id]) do
    bucket_name = @default_being_bucket_name

    nw = %NodeWorker{
      bucket_name: bucket_name,
      node_id: node_id
    }

    Cosmos.BucketNameRegistry.register(node_id, bucket_name)

    {:ok, nw}
  end

  @impl true
  def handle_cast({:connect, new_neighbor_id}, state) do
    node = get_node(state.bucket_name, state.node_id)
    old_neighbors = node.neighbors

    new_node =
      if new_neighbor_id not in old_neighbors do
        %{node | neighbors: [new_neighbor_id | old_neighbors]}
      else
        node
      end

    put_node(state.bucket_name, state.node_id, new_node)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:attach, being_id}, state) do
    node = get_node(state.bucket_name, state.node_id)
    old_occupants = node.occupants
    new_node = %{node | occupants: [being_id | old_occupants]}
    put_node(state.bucket_name, state.node_id, new_node)
    {:noreply, state}
  end

  @impl true
  def handle_call({:get, nil}, _from, state) do
    node = get_node(state.bucket_name, state.node_id)
    {:reply, node, state}
  end

  @impl true
  def handle_call({:get, attribute_type}, _from, state) do
    node = get_node(state.bucket_name, state.node_id)
    amount = Map.get(node, attribute_type)
    {:reply, amount, state}
  end

  @impl true
  def handle_call(:yeild_resource, _from, state) do
    node = get_node(state.bucket_name, state.node_id)
    resource_type = node.resource_type
    amount = node.resource_yeild
    {:reply, {:ok, resource_type, amount}, state}
  end

  # public helper -------------------------------------------------------------------------
  def get_default_node_bucket_name() do
    @default_node_bucket_name
  end

  # Private functions ---------------------------------------------------------------------
  defp get_node(bucket_name, node_id) do
    {:ok, bucket_pid} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket_name)
    Bucket.get(bucket_pid, node_id)
  end

  defp put_node(bucket_name, node_id, node) do
    {:ok, bucket_pid} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket_name)
    Bucket.put(bucket_pid, node_id, node)
  end
end
