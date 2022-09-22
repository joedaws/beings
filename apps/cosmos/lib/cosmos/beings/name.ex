defmodule Cosmos.Beings.Name do
  @moduledoc """
  name struct for beings
  - template
    A list of keys which defines the order of the name parts.
  - parts
    A map whose keys are name parts and whose values are the name values

  When ading new templates:
  - add template list to @templates by adding part types
  - udpate the names yaml with additional section for new template
  - add key to @max_syllables for each new part type.
  """
  require Logger
  alias Cosmos.Beings.Name

  defstruct template: [],
            parts: %{}

  @templates %{
    "weird_science" => ["model_name", "signifier"],
    "dream_realm" => ["shell_name", "core_prefix", "core_name"],
    "deep_denizen" => ["epithet", "deep_name"]
  }

  @default_part "z"

  @max_syllables %{
    "model_name" => 1,
    "signifier" => 1,
    "shell_name" => 3,
    "core_prefix" => 1,
    "core_name" => 3,
    "epithet" => 1,
    "deep_name" => 3
  }

  @name_syllables_path "names/beings.yaml"

  @doc """
  retrieve syllables parts from the name file
  """
  def name_syllables() do
    data_path = Application.fetch_env!(:cosmos, :data_path)
    path = Path.join(data_path, @name_syllables_path)

    # Logger.info("Pulling name data from #{path}")

    {:ok, all_syllables} = YamlElixir.read_from_file(path)
    all_syllables
  end

  def get_max_syllables() do
    @max_syllables
  end

  @doc """
  Template types
  - "weird_science"
  - "dream_realm"
  - "deep_denizen"
  """
  def generate_name(template_type, name_tuple) do
    all_syllables = name_syllables()

    syllables = Map.get(all_syllables, template_type)
    template = Map.get(@templates, template_type)

    parts =
      for part <- template,
          into: %{},
          do:
            {part,
             create_name_part(
               Map.get(syllables, part),
               :rand.uniform(Map.get(@max_syllables, part))
             )}

    name = %Name{
      template: template,
      parts: parts
    }

    Logger.info(
      "Created a #{template_type} random name `#{string(name)}` from tempalte: #{Enum.join(template, " ")}"
    )

    name
  end

  @doc """
  Template types
  - "weird_science"
  - "dream_realm"
  - "deep_denizen"
  """
  def generate_name(template_type) do
    all_syllables = name_syllables()

    syllables = Map.get(all_syllables, template_type)
    template = Map.get(@templates, template_type)

    parts =
      for part <- template,
          into: %{},
          do:
            {part,
             create_name_part(
               Map.get(syllables, part),
               :rand.uniform(Map.get(@max_syllables, part))
             )}

    name = %Name{
      template: template,
      parts: parts
    }

    Logger.info(
      "Created a #{template_type} random name `#{string(name)}` from tempalte: #{Enum.join(template, " ")}"
    )

    name
  end

  def permutations([]) do
    [[]]
  end

  def permutations(list) do
    for h <- list, t <- permutations(list -- [h]), do: [h | t]
  end

  @doc """
  Creates a queue for each tempalte type of all permutations of
  all possible being names.

  "weird_science" => ["model_name", "signifier"],
  "dream_realm" => ["shell_name", "core_prefix", "core_name"],
  "deep_denizen" => ["epithet", "deep_name"]
  """
  def get_all_names_list() do
    %{
      "weird_science" => get_all_names_list("weird_science"),
      "dream_realm" => get_all_names_list("dream_realm"),
      "deep_denizen" => get_all_names_list("deep_denizen")
    }
  end

  def get_all_names_list("weird_science") do
    all_syllables = name_syllables()
    template = Map.get(@templates, "weird_science")

    syllables = Map.get(all_syllables, "weird_science")

    all_parts_combos =
      for syl1 <-
            all_combos(
              Map.get(syllables, "model_name"),
              [],
              Map.get(@max_syllables, "model_name")
            ),
          syl2 <-
            all_combos(
              Map.get(syllables, "signifier"),
              [],
              Map.get(@max_syllables, "signifier")
            ),
          do: [syl1, syl2]

    all_parts_combos = Enum.shuffle(all_parts_combos)

    all_names = for p <- all_parts_combos, do: %Name{template: template, parts: p}
  end

  def get_all_names_list("dream_realm") do
    all_syllables = name_syllables()
    template = Map.get(@templates, "dream_realm")

    syllables = Map.get(all_syllables, "dream_realm")

    all_parts_combos =
      for syl1 <-
            all_combos(
              Map.get(syllables, "shell_name"),
              [],
              Map.get(@max_syllables, "shell_name")
            ),
          syl2 <-
            all_combos(
              Map.get(syllables, "core_prefix"),
              [],
              Map.get(@max_syllables, "core_prefix")
            ),
          syl3 <-
            all_combos(Map.get(syllables, "core_name"), [], Map.get(@max_syllables, "core_name")),
          do: [syl1, syl2, syl3]

    all_parts_combos = Enum.shuffle(all_parts_combos)

    all_names = for p <- all_parts_combos, do: %Name{template: template, parts: p}
  end

  def get_all_names_list("deep_denizen") do
    all_syllables = name_syllables()
    template = Map.get(@templates, "deep_denizen")

    syllables = Map.get(all_syllables, "deep_denizen")

    all_parts_combos =
      for syl1 <-
            all_combos(
              Map.get(syllables, "epithet"),
              [],
              Map.get(@max_syllables, "epithet")
            ),
          syl2 <-
            all_combos(
              Map.get(syllables, "deep_name"),
              [],
              Map.get(@max_syllables, "deep_name")
            ),
          do: [syl1, syl2]

    all_parts_combos = Enum.shuffle(all_parts_combos)

    all_names = for p <- all_parts_combos, do: %Name{template: template, parts: p}
  end

  def all_combos(syllables_list, accumulator, 1) do
    for(syl <- syllables_list, do: [syl]) ++ accumulator
  end

  @doc """
  Returns all names composed of 1,...,n syllables from the given list
  """
  def all_combos(syllables_list, accumulator, n) do
    new_combos =
      case n do
        4 -> all_4_combos(syllables_list)
        3 -> all_3_combos(syllables_list)
        2 -> all_2_combos(syllables_list)
      end

    all_combos(syllables_list, new_combos ++ accumulator, n - 1)
  end

  @doc """
  Returns all names composed of 2 syllables from the given list
  """
  def all_2_combos(syllable_list) do
    for syl1 <- syllable_list, syl2 <- syllable_list, do: [syl1, syl2]
  end

  @doc """
  Returns all names composed of 3 syllables from the given list
  """
  def all_3_combos(syllable_list) do
    for syl1 <- syllable_list,
        syl2 <- syllable_list,
        syl3 <- syllable_list,
        do: [syl1, syl2, syl3]
  end

  @doc """
  Returns all names composed of 3 syllables from the given list
  """
  def all_4_combos(syllable_list) do
    for syl1 <- syllable_list,
        syl2 <- syllable_list,
        syl3 <- syllable_list,
        syl4 <- syllable_list,
        do: [syl1, syl2, syl3, syl4]
  end

  @doc """
  Template types
  - "weird_science"
  - "dream_realm"
  - "deep_denizen"
  """
  def get_name_from_tuple(template_type, part_name_to_tuple_map) do
    all_syllables = name_syllables()

    syllables = Map.get(all_syllables, template_type)
    template = Map.get(@templates, template_type)

    parts =
      for {part, tup} <- part_name_to_tuple_map,
          into: %{},
          do: {part, for(idx <- Tuple.to_list(tup), do: Enum.at(Map.get(syllables, part), idx))}

    name = %Name{
      template: template,
      parts: parts
    }

    Logger.info(
      "Created a #{template_type} random name `#{string(name)}` from tempalte: #{Enum.join(template, " ")}"
    )

    name
  end

  @doc """
  Creates a name part using n syllables from the given list of syllables
  """
  def create_name_part(syllables_list, n) do
    Enum.join(for _ <- 1..n, do: Enum.random(syllables_list))
  end

  def string(name) do
    string(name.template, name)
  end

  @doc """
  Dream realm beings have names with template
  - shell name
  - core prefix
  - core name
  """
  def string(["shell_name", "core_prefix", "core_name"], name) do
    # shell = "#{String.capitalize(Map.get(name.parts, "shell_name", @default_part))}"
    # prefix = "#{String.capitalize(Map.get(name.parts, "core_prefix", @default_part))}"
    # core = "#{String.capitalize(Map.get(name.parts, "core_name", @default_part))}"
    shell = "#{String.capitalize(Enum.join(Enum.at(name.parts, 0), " "))}"
    prefix = "#{String.capitalize(Enum.join(Enum.at(name.parts, 1), " "))}"
    core = "#{String.capitalize(Enum.join(Enum.at(name.parts, 2), " "))}"
    shell <> "\s" <> prefix <> core
  end

  @doc """
  Deep denizen beings have names with template
  - epithet
  - deep_name
  """
  def string(["epithet", "deep_name"], name) do
    # epithet = "#{String.capitalize(Map.get(name.parts, "epithet", @default_part))}"
    # deep_name = "#{String.capitalize(Map.get(name.parts, "deep_name", @default_part))}"
    epithet = "#{String.capitalize(Enum.join(Enum.at(name.parts, 0), " "))}"
    deep_name = "#{String.capitalize(Enum.join(Enum.at(name.parts, 1), " "))}"
    epithet <> "\s" <> deep_name
  end

  def string(["model_name", "signifier"], name) do
    # model = "#{String.capitalize(Map.get(name.parts, "model_name", @default_part))}"
    # signifier = "#{String.capitalize(Map.get(name.parts, "signifier", @default_part))}"
    model = "#{String.capitalize(Enum.join(Enum.at(name.parts, 0), " "))}"
    signifier = "#{String.capitalize(Enum.join(Enum.at(name.parts, 1), " "))}"
    model <> "\s" <> signifier
  end

  @doc """
  Generate a name of a descendant of the given being name.
  """
  def get_descendent_name(name) do
    :not_implemented
  end

  @doc """
  Given a template type count the number of unique names of that type.

  Let $k$ be the number of parts in a template
  Let $n_i$ for $i=1,...,k$ be the max number of syllables for
  that part.
  Let $m_i$ for $i=1,...k$ be the number of syllables from the
  name file for the part associated with index i.
  Then for a single part, the number of unique
  possible names is

  \prod_{i=1}^k \sum_{j=1}^{n_i} m_i^j
  """
  def count_unique_names(template_type) do
    template = Map.fetch!(@templates, template_type)
    k = length(template)

    # elements of n correspond to n_i in doc string
    n = for part <- template, into: %{}, do: {part, Map.get(@max_syllables, part)}

    all_syllables = name_syllables()
    syllables = Map.get(all_syllables, template_type)
    # elements of m correspond to m_i in doc string
    m = for {part, syllables_list} <- syllables, into: %{}, do: {part, length(syllables_list)}

    Enum.reduce(template, 1, fn i, acc ->
      acc *
        Enum.reduce(1..Map.get(n, i), 0, fn j, acc2 -> pow(Map.get(m, i), j) + acc2 end)
    end)
  end

  def pow(n, k), do: pow(n, k, 1)
  defp pow(_, 0, acc), do: acc
  defp pow(n, k, acc), do: pow(n, k - 1, n * acc)
end
