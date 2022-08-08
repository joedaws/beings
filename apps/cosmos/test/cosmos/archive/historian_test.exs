defmodule Cosmos.Archive.HistorianTest do
  use ExUnit.Case

  alias Cosmos.Beings.Being
  alias Cosmos.Archive.EventRecord

  setup do
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, "beings")
    {:ok, beings} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, "beings")

    b = Being.get_random_being()
    # hibernating beings do not run cycles
    b = %{b | ichor: 100, status: "hibernating"}
    b_id = b.id

    %{b_id: b_id}
  end

  test "registry entity", %{b_id: b_id} do
    Cosmos.Archive.Historian.register_entity(b_id)
    eh = Cosmos.Archive.Historian.get_entity_history(b_id)
    assert eh != nil
  end

  test "record event" do
    ev = %EventRecord{
      created_at: NaiveDateTime.utc_now(),
      event_type: "being_update",
      description: "This is a test update"
    }

    eh = Cosmos.Archive.Historian.get_entity_history("new_id")
    assert length(eh) == 0

    Cosmos.Archive.Historian.record_event("new_id", ev)
    eh = Cosmos.Archive.Historian.get_entity_history("new_id")
    assert length(eh) == 1
  end
end
