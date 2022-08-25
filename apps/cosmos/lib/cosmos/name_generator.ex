defmodule Cosmos.NameGenerator do
  use GenServer

  @entity_module %{"being" => Cosmos.Beings.Name, "node" => Cosmos.Locations.Name}

  # client ---------------------------------------------------------------------
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def generate_name(entity_type) do
    GenServer.call(__MODULE__, {:name, entity_type})
  end

  # callbacks ------------------------------------------------------------------
  def init(args) do
    entity_type = "being"
    # TODO set up starting index for each entity type
    all_syllables = Map.get(@entity_module, entity_type).name_syllables()
    max_syl = Map.get(@entity_module, entity_type).get_max_syllables()
    # TODO set up starting index
    {:ok, %{}}
  end

  def handle_call({:name, entity_type}, state) do
    max_syl = Map.get(@entity_module, entity_type).get_max_syllables()
    all_syllables = Map.get(@entity_module, entity_type).name_syllables()
    name = "BOB"
    {:reply, name, state}
  end

  # helpers --------------------------------------------------------------------
  @doc """
  Returns a map like
  %{"deep_denizen" => %{"name_epithet" => {1}, "deep_name" => {3,7,2}}}

  which can be used to generate a name
  """
  def get_new_name_idx(entity_type, template) do
    :not_implemented
  end

  @doc """
  generates a name from a given map of the form
  %{"deep_denizen" => %{"name_epithet" => {1}, "deep_name" => {3,7,2}}}
  """
  def from_name_idx(name_idx) do
    :not_implemented
  end

  def starting_idx(all_syllables, max_syl) do
    for {culture, part_type_map} <- all_syllables,
        into: %{},
        do:
          {culture,
           for(
             {part_name, parts_list} <- part_type_map,
             into: %{},
             do: {part_name, for(num <- 1..Map.get(max_syl, part_name), into: %{}, do: {num, 0})}
           )}
  end

  def permuted_indices(all_syllables, max_syl) do
    for {culture, part_type_map} <- all_syllables,
        into: %{},
        do:
          {culture,
           for(
             {part_name, parts_list} <- part_type_map,
             into: %{},
             do:
               {part_name,
                for(
                  num <- 1..Map.get(max_syl, part_name),
                  into: %{},
                  do: {num, Enum.shuffle(for i <- 0..(length(parts_list) - 1), do: i)}
                )}
           )}
  end
end
