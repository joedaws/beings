defmodule Cosmos.Locations.NodeWorkerCache do
  @doc """
  GenServer for getting NodeWorkers

  Use the worker_process function to get a pid given
  a node id.
  """
  use GenServer
  require Logger

  # client -------------------------------------------------------------------------------------
  def start_link(opts) do
    Logger.info("Starting Node Worker Cache")
    GenServer.start(__MODULE__, :ok, opts)
  end

  def worker_process(bucket_name, node_id) do
    GenServer.call(__MODULE__, {:worker_process, bucket_name, node_id})
  end

  # call backs ---------------------------------------------------------------------------------
  @impl true
  def init(_) do
    node_ids = %{}
    refs = %{}
    {:ok, {node_ids, refs}}
  end

  @impl true
  def handle_call({:worker_process, bucket_name, node_id}, _from, {node_ids, refs}) do
    # node_ids is a map from node ids to a worker process pid.
    case Map.fetch(node_ids, node_id) do
      {:ok, node_worker_pid} ->
        {:reply, node_worker_pid, {node_ids, refs}}

      # start a worker if one doesn't exist yet
      :error ->
        {:ok, new_worker_pid} =
          DynamicSupervisor.start_child(
            Cosmos.Locations.NodeWorkerSupervisor,
            {Cosmos.Locations.NodeWorker, [bucket_name, node_id]}
          )

        ref = Process.monitor(new_worker_pid)
        refs = Map.put(refs, ref, node_id)
        node_ids = Map.put(node_ids, node_id, new_worker_pid)

        {:reply, new_worker_pid, {node_ids, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _ids, _reason}, {node_ids, refs}) do
    {node_id, _ref} = Map.pop(refs, ref)
    names = Map.delete(node_ids, node_id)
    {:noreply, {node_ids, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in Cosmos.Locations.NodeWorkerCache: #{inspect(msg)}")
    {:noreply, state}
  end
end
