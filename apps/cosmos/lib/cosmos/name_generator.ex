defmodule Cosmos.NameGenerator do
  use GenServer, restart: :permanent

  @entity_module %{"being" => Cosmos.Beings.Name, "node" => Cosmos.Locations.Name}

  # client ---------------------------------------------------------------------
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_name(entity_type, entity_sub_type) do
    GenServer.call(__MODULE__, {:name, entity_type, entity_sub_type})
  end

  # callbacks ------------------------------------------------------------------
  def init(args) do
    state = %{
      "being_names" => Cosmos.Beings.Name.get_all_names_list(),
      "being_name_idx" => %{"weird_science" => 0}
    }

    {:ok, state}
  end

  def handle_call({:name, "beings", culture}, _from, state) do
    # get index and increment it by one it
    {name_idx, state} = get_and_update_in(state, ["being_name_idx", culture], &{&1, &1 + 1})

    name = Enum.at(get_in(state, ["being_names", culture]), name_idx)

    {:reply, name, state}
  end
end
