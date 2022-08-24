defmodule Cosmos.Archive.HistorianTest do
  use ExUnit.Case

  alias Cosmos.Beings.Being
  alias Cosmos.Archive.Event

  setup do
    Cosmos.Registry.create(Cosmos.Registry, "beings")
    {:ok, beings} = Cosmos.Registry.lookup(Cosmos.Registry, "beings")

    b = Being.get_random_being()
    b = %{b | ichor: 100, status: "hibernating"}
    b_id = b.id

    c = Being.get_random_being()
    c = %{c | ichor: 100, status: "hibernating"}
    c_id = c.id

    Cosmos.Bucket.put(beings, b.id, b)
    Cosmos.Bucket.put(beings, c.id, c)

    %{b_id: b_id, c_id: c_id}
  end

  test "register entity", %{b_id: b_id} do
    Cosmos.Archive.Historian.register_entity(b_id)
    eh = Cosmos.Archive.Historian.get_entity_history(b_id)
    assert eh != nil
  end

  test "register entities from bucket", %{b_id: b_id, c_id: c_id} do
    Cosmos.Archive.Historian.register_entities_in_bucket("beings")
    eh = Cosmos.Archive.Historian.get_entity_history(b_id)
    assert eh != nil
    eh = Cosmos.Archive.Historian.get_entity_history(c_id)
    assert eh != nil
  end

  test "record event" do
    ev = %Event{
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
