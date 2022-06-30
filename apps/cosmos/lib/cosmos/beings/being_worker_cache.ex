defmodule Cosmos.Beings.BeingWorkerCache do
  @doc """
  The cache associated the being ids with the being worker pid
  assigned to it.

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
  def start_link(_) do
    Logger.info("Starting Being Worker Cache")
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(bucket_pid, being_id) do
    GenServer.call(__MODULE__, {:server_process, bucket_pid, being_id})
  end

  # call backs ---------------------------------------------------------------------------------
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:server_process, bucket_pid, being_id}, _from, being_workers) do
    case Map.fetch(being_workers, being_id) do
      {:ok, being_worker} ->
        {:reply, being_worker, being_workers}

      # start a worker if one doesn't exist yet
      :error ->
        {:ok, new_worker} = Cosmos.Beings.BeingWorker.start_link([bucket_pid, being_id])

        {
          :reply,
          new_worker,
          Map.put(being_workers, being_id, new_worker)
        }
    end
  end
end
