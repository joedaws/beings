defmodule Cosmos.NameGenerator do
  use GenServer

  @entity_module %{"being" => Cosmos.Beings.Name, "node" => Cosmos.Locations.Name}

  # client ---------------------------------------------------------------------
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def get_name(entity_type, culture) do
    GenServer.call(__MODULE__, {:name, entity_type, culture})
  end

  # callbacks ------------------------------------------------------------------
  def init(args) do
    entity_types = Map.keys(@entity_module)

    entity_name_max_syl_map =
      for entity_type <- entity_types,
          into: %{},
          do: {entity_type, Map.get(@entity_module, entity_type).get_max_syllables()}

    entity_name_all_syl_map =
      for entity_type <- entity_types,
          into: %{},
          do: {entity_type, Map.get(@entity_module, entity_type).name_syllables()}

    entity_name_idx =
      for entity_type <- entity_types,
          into: %{},
          do:
            {entity_type,
             starting_idx(
               Map.get(entity_name_all_syl_map, entity_type),
               Map.get(entity_name_max_syl_map, entity_type)
             )}

    state = %{
      "all_syl" => entity_name_all_syl_map,
      "max_syl" => entity_name_max_syl_map,
      "idx" => entity_name_idx
    }

    {:ok, state}
  end

  def handle_call({:name, entity_type, culture}, state) do
    num_syl = Map.get(@entity_module, entity_type).get_max_syllables()
    culture_tuple_map = get_in(state, ["idx", entity_type, culture])

    part_name = :oops
    # right now still choose a random number of syllables
    syllables_in_name = :rand.uniform(Map.get(num_syl, part_name))

    part_name_to_syl_index_map =
      for {part_name, idx} <- culture_tuple_map,
          into: %{},
          do: {part_name, Map.get(idx, syllables_in_name)}

    culture_syl = get_in(state, ["all_syl", culture])

    name =
      Map.get(@entity_module, entity_type).get_name_from_tuple(
        culture,
        part_name_to_syl_index_map
      )

    # TODO increment tuple
    # increment_tuple(state, entity_type, culture, )
    state = update_in(state, ["idx", entity_type, culture, part_name, num_syl], &(&1 + 1))

    {:reply, name, state}
  end

  # helpers --------------------------------------------------------------------
  @doc """
  generates a name from a given map of the form
  %{"deep_denizen" => %{"name_epithet" => {1}, "deep_name" => {3,7,2}}}
  """
  def get_name_from_tuple(name_idx_tuple, culture_syl) do
    all_syllables = %{oops: "whoa"}

    template_type = "yo"
    syllables = Map.get(all_syllables, template_type)
    template = Map.get(@templates, template_type)

    # parts =
    #  for part <- template,
    #      into: %{},
    #      do:
    #        {part,
    #         create_name_part(
    #           Map.get(syllables, part),
    #           :rand.uniform(Map.get(@max_syllables, part))
    #         )}

    # name = %Map.get(@entity_module, entity_type){
    #  template: template,
    #  parts: parts
    # }
  end

  def starting_idx(all_syllables, max_syl) do
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
                  do: {num, 0}
                )}
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
