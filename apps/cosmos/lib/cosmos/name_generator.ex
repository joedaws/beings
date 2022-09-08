defmodule Cosmos.NameGenerator do
  use GenServer

  @entity_module %{"being" => Cosmos.Beings.Name, "node" => Cosmos.Locations.Name}

  # client ---------------------------------------------------------------------
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def get_name(entity_type, entity_sub_type) do
    GenServer.call(__MODULE__, {:name, entity_type, entity_sub_type})
  end

  # callbacks ------------------------------------------------------------------
  def init(args) do
    state = %{
      "beings" => Cosmos.Beings.Name.get_all_names_queue(),
      "nodes" => Cosmos.Locations.Name.get_all_names_queue()
    }

    {:ok, state}
  end

  def handle_call({:name, "beings", culture}, state) do
    name = :queue.out(get_in(state, ["beings", culture]))
    {:reply, name, state}
  end
end
