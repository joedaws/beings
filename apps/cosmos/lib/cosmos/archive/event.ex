defmodule Cosmos.Archive.Event do
  alias Cosmos.Archive.Event

  @event_types [
    "being_creation",
    "being_update",
    "being_death",
    "being_action",
    "being_social_interaction",
    "node_creation",
    "node_update",
    "entity_status"
  ]

  defstruct [
    :created_at,
    :event_type,
    :description
  ]

  def new(event_type, description) do
    %Event{
      created_at: NaiveDateTime.utc_now(),
      event_type: event_type,
      description: description
    }
  end

  def string(event) do
    Enum.join([event.created_at, event.event_type, event.description], ",")
  end

  def all_event_types() do
    @event_types
  end
end
