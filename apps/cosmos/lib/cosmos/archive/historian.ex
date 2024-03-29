defmodule Cosmos.Archive.Historian do
  @moduledoc """
  The historian keeps a record of events of all entities

  The history is a map whose keys are entity ids and
  whose values are lists of events.
  """
  use GenServer, restart: :permanent
  require Logger
  alias Cosmos.Bucket
  alias Cosmos.Beings.BeingWorker
  alias Cosmos.Archive.Event

  # length of a cycle in milliseconds
  @cycle_duration 5 * 1000

  # maximum length of history list per entity
  @max_history_legnth 10

  # client API ----------------------------------------------------------------------
  def start_link(opts) do
    Logger.info("Staring Historian Process")
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_entity_history(entity_id) do
    GenServer.call(__MODULE__, {:get_entity_history, entity_id})
  end

  def register_entity(entity_id) do
    GenServer.cast(__MODULE__, {:register_entity, entity_id})
  end

  def record_event(entity_id, event) do
    GenServer.cast(__MODULE__, {:record_event, entity_id, event})
    Logger.info("Historian recorded event for #{inspect(entity_id)}")
  end

  def register_entities_in_bucket(bucket_name) do
    GenServer.cast(__MODULE__, {:register_entities_in_bucket, bucket_name})
    Logger.info("Historian registred entities from bucket #{bucket_name}")
  end

  def stash_events() do
    # store events when history gets too big
    :not_implemented
  end

  # callbacks -----------------------------------------------------------------------
  @impl true
  def init(_) do
    history = %{}

    cycle(history)
    {:ok, history}
  end

  @impl true
  def handle_call({:get_entity_history, entity_id}, _from, history) do
    entity_history = Map.get(history, entity_id, [])
    {:reply, entity_history, history}
  end

  @impl true
  def handle_cast({:register_entities_in_bucket, bucket_name}, history) do
    {:ok, bucket_worker} = Cosmos.Registry.lookup(Cosmos.Registry, bucket_name)
    all_entity_ids = Bucket.keys(bucket_worker)
    history = register_entities(history, all_entity_ids)
    {:noreply, history}
  end

  @impl true
  def handle_cast({:register_entity, entity_id}, history) do
    history = register_entity(history, entity_id)
    Logger.info("Historian registered entity #{inspect(entity_id)}")
    {:noreply, history}
  end

  @impl true
  def handle_cast({:record_event, entity_id, event}, history) do
    # only keep last @max_history_legnth events per list
    entity_history = Enum.take(Map.get(history, entity_id, []), @max_history_legnth)
    history = Map.put(history, entity_id, [event | entity_history])
    Logger.info("Historian Recorded event for #{inspect(entity_id)}")
    {:noreply, history}
  end

  def handle_info(:cycle, history) do
    cycle(history)
    {:noreply, history}
  end

  # private functions ---------------------------------------------------------------
  defp cycle(history) do
    if length(Map.keys(history)) > 0 do
      publish(history)
    else
      Logger.info("Historian has no registered entities")
    end

    # to simulate passage of time
    Process.send_after(self(), :cycle, @cycle_duration)
  end

  defp collect_diff(history) do
    diff_map =
      for {entity_id, event_history} <- history,
          into: %{},
          do:
            {entity_id,
             Cosmos.EntityWorkerModuleNameRegistry.get(entity_id).get(
               Cosmos.Beings.BeingWorkerCache.worker_process(
                 Cosmos.BucketNameRegistry.get(entity_id),
                 entity_id
               )
             )}
  end

  defp publish(history) do
    history_dir = Application.fetch_env!(:cosmos, :history_dir)
    history_path = Path.join(history_dir, "dev_history.txt")

    events =
      for {entity_id, entity_history} <- history,
          into: %{},
          do: {entity_id, List.first(entity_history)}

    events_str_list =
      for {entity_id, event} <- events,
          do: Enum.join([inspect(entity_id), Event.string(event)], ",")

    {:ok, file} = File.open(history_path, [:write])
    IO.binwrite(file, Enum.join(events_str_list, "\n"))
    File.close(file)

    Logger.info("Published most recent events")
  end

  defp register_entity(history, entity_id) do
    Map.put_new(history, entity_id, [])
  end

  defp register_entities(history, [entity_id | tail]) do
    history = register_entity(history, entity_id)
    register_entities(history, tail)
  end

  defp register_entities(history, []) do
    history
  end
end
