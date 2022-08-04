defmodule Cosmos.Archive.Historian do
  @moduledoc """
  The historian keeps a record of events of all entities

  The history is a map whose keys are entity ids and
  whose values are lists of events.
  """
  use GenServer
  require Logger

  # length of a cycle in milliseconds
  @cycle_duration 5000

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
    Logger.info("Historian will record event for #{inspect(entity_id)}")
    GenServer.cast(__MODULE__, {:record_event, entity_id, event})
  end

  def stash_events() do
    # store events when history gets too big
    :not_implemented
  end

  # callbacks -----------------------------------------------------------------------
  @impl true
  def init(_) do
    history = %{}
    {:ok, history}
  end

  @impl true
  def handle_call({:get_entity_history, entity_id}, _from, history) do
    entity_history = Map.get(history, entity_id, [])
    {:reply, entity_history, history}
  end

  @impl true
  def handle_cast({:register_entity, entity_id}, history) do
    history = Map.put_new(history, entity_id, [])
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

  # private functions ---------------------------------------------------------------
  defp cycle(history) do
    publish(history)

    # TODO add send after
  end

  defp publish(history) do
    events =
      for {entity_id, history} <- Map.keys(history),
          into: %{},
          do: {entity_id, List.first(history)}

    Logger.info("Publishing most recent events")
  end
end
