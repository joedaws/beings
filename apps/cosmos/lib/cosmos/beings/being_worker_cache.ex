defmodule Cosmos.Beings.BeingWorkerCache do
  @doc """
  GenServer for getting BeingWorkers

  ## Examples

      iex> {:ok, cache} = Cosmos.Beings.BeingWorkerCache.start()
      {:ok, cache}

      iex> being = Cosmos.Beings.Being.get_random_being()
      being

      iex> being_id = Cosmos.Beings.Being.generate_id(being)
      being_id
  """
  use GenServer
  require Logger

  # client -------------------------------------------------------------------------------------
  def start_link(opts) do
    Logger.info("Starting Being Worker Cache")
    GenServer.start(__MODULE__, :ok, opts)
  end

  def worker_process(bucket_name, being_id) do
    GenServer.call(__MODULE__, {:worker_process, bucket_name, being_id})
  end

  # call backs ---------------------------------------------------------------------------------
  @impl true
  def init(_) do
    being_ids = %{}
    refs = %{}
    {:ok, {being_ids, refs}}
  end

  @impl true
  def handle_call({:worker_process, bucket_name, being_id}, _from, {being_ids, refs}) do
    # being_ids is a map from being ids to a worker process pid.
    case Map.fetch(being_ids, being_id) do
      {:ok, being_worker_pid} ->
        {:reply, being_worker_pid, {being_ids, refs}}

      # start a worker if one doesn't exist yet
      :error ->
        {:ok, new_worker_pid} =
          DynamicSupervisor.start_child(
            Cosmos.Beings.BeingWorkerSupervisor,
            {Cosmos.Beings.BeingWorker, [bucket_name, being_id]}
          )

        ref = Process.monitor(new_worker_pid)
        refs = Map.put(refs, ref, being_id)
        being_ids = Map.put(being_ids, being_id, new_worker_pid)

        {
          :reply,
          new_worker_pid,
          {being_ids, refs}
        }
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _ids, _reason}, {being_ids, refs}) do
    {being_id, _ref} = Map.pop(refs, ref)
    names = Map.delete(being_ids, being_id)
    {:noreply, {being_ids, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in Cosmos.Beings.BeingWorkerCache: #{inspect(msg)}")
    {:noreply, state}
  end
end
