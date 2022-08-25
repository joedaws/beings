defmodule Cosmos.Locations.Name do
  @moduledoc """
  name struct for locations
  - template
    A list of keys which define the order of the name parts.
    The templates for the different location types are
    found in the templates module map below.
  - parts
    A map whose keys are name parts and whose values are the name values
  """
  require Logger
  alias Cosmos.Locations.Name

  defstruct template: [],
            parts: %{}

  @default_part "y"

  @templates %{
    "warped_nature" => ["adjective", "proper_noun_nature", "ecosystem"],
    "human_built" => ["structure_type", "room_in_structure"],
    "dream_place" => ["proper_noun_dream_place", "dream_modifier"],
    "deep_dimension" => ["deep_adjective", "proper_noun_deep_place"],
    "lost_in_time" => ["adjective", "verb"]
  }

  @name_syllables_path "names/nodes.yaml"

  @max_syllables %{
    "adjective" => 1,
    "proper_noun_nature" => 3,
    "ecosystem" => 1,
    "structure_type" => 1,
    "room_in_structure" => 1,
    "proper_noun_dream_place" => 2,
    "dream_modifier" => 1,
    "deep_adjective" => 1,
    "proper_noun_deep_place" => 1,
    "verb" => 1
  }

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
  Template types are the keys of the module variable templates
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
  "warped_nature" => ["adjective", "proper_noun_nature", "ecosystem"]
  """
  def string(["adjective", "proper_noun_nature", "ecosystem"], name) do
    adjective = "#{String.capitalize(Map.get(name.parts, "adjective", @default_part))}"
    proper_noun = "#{String.capitalize(Map.get(name.parts, "proper_noun_nature", @default_part))}"
    ecosystem = "#{String.capitalize(Map.get(name.parts, "ecosystem", @default_part))}"
    adjective <> "\s" <> proper_noun <> "\s" <> ecosystem
  end

  @doc """
  "human_built" => ["structure_type", "room_in_structure"]
  """
  def string(["structure_type", "room_in_structure"], name) do
    structure = "#{String.capitalize(Map.get(name.parts, "structure_type", @default_part))}"
    room = "#{String.capitalize(Map.get(name.parts, "room_in_structure", @default_part))}"
    structure <> "\s" <> room
  end

  @doc """
  "dream_place" => ["proper_noun_dream_place", "dream_modifier"]
  """
  def string(["proper_noun_dream_place", "dream_modifier"], name) do
    place = "#{String.capitalize(Map.get(name.parts, "proper_noun_dream_place", @default_part))}"
    modifier = "#{String.capitalize(Map.get(name.parts, "dream_modifier", @default_part))}"
    modifier <> "\s" <> place
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
