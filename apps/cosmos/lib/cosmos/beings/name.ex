defmodule Cosmos.Beings.Name do
  @moduledoc """
  name struct
  - template
    A list of keys which defines the order of the name parts.
  - parts
    A map whose keys are name parts and whose values are the name values

  When ading new templates:
  - add template list to @templates by adding part types
  - udpate the names yaml with additional section for new template
  - add key to @max_syllabes for each new part type.
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
  @max_syllabes %{
    "model_name" => 1,
    "signifier" => 1,
    "shell_name" => 2,
    "core_prefix" => 1,
    "core_name" => 3,
    "epithet" => 1,
    "deep_name" => 3
  }

  @name_syllables_path "names/beings.yaml"

  @doc """
  Template types
  - "weird_science"
  - "dream_realm"
  - "deep_denizen"
  """
  def generate_name(template_type) do
    data_path = Application.fetch_env!(:cosmos, :data_path)
    path = Path.join(data_path, @name_syllables_path)

    Logger.info("Pulling name data from #{path}")

    {:ok, all_syllabes} = YamlElixir.read_from_file(path)

    syllabes = Map.get(all_syllabes, template_type)
    template = Map.get(@templates, template_type)

    Logger.info("Creating a #{template_type} random name with")
    Logger.info("tempalte: #{Enum.join(template, " ")}")

    parts =
      for part <- template,
          into: %{},
          do:
            {part,
             create_name_part(
               Map.get(syllabes, part),
               :rand.uniform(Map.get(@max_syllabes, part))
             )}

    %Name{
      template: template,
      parts: parts
    }
  end

  @doc """
  Creates a name part using n syllabes from the given list of syllabes
  """
  def create_name_part(syllabes_list, n) do
    Enum.join(for _ <- 1..n, do: Enum.random(syllabes_list))
  end

  def show(name) do
    show(name.template, name)
  end

  @doc """
  Dream realm beings have names with template
  - shell name
  - core prefix
  - core name
  """
  def show(["shell_name", "core_prefix", "core_name"], name) do
    shell = "#{String.capitalize(Map.get(name.parts, "shell_name", @default_part))}"
    prefix = "#{String.capitalize(Map.get(name.parts, "core_prefix", @default_part))}"
    core = "#{Map.get(name.parts, "core_name", @default_part)}"
    shell <> "\s" <> prefix <> core
  end

  @doc """
  Deep denizen beings have names with template
  - epithet
  - deep_name
  """
  def show(["epithet", "deep_name"], name) do
    epithet = "#{String.capitalize(Map.get(name.parts, "epithet", @default_part))}"
    deep_name = "#{String.capitalize(Map.get(name.parts, "deep_name", @default_part))}"
    epithet <> "\s" <> deep_name
  end

  @doc """
  Generate a name of a descendant of the given being name.
  """
  def get_descendent_name(name) do
    :not_implemented
  end
end
