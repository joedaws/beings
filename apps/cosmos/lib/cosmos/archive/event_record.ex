defmodule Cosmos.Archive.EventRecord do
  @event_types [
    "being_creation",
    "being_update",
    "being_death",
    "being_action",
    "node_creation",
    "node_update",
    "entity_status"
  ]

  defstruct [
    :created_at,
    :event_type,
    :description
  ]

  def all_event_types() do
    @event_types
  end
end
