defmodule Cosmos.Beings.Name do
  @moduledoc """

  - template
    A list of keys which defines the order of the name parts.
  - name

  """
  require Logger
  alias Cosmos.Beings.Name

  defstruct template: [],
            parts: %{}

  @templates %{
    "weird_science" => ["model_name", "signifier"],
    "dream_realm" => ["shell_name", "core_prefix", "core_name"]
  }

  @default_part "z"
  @max_syllabes %{
    "model_name" => 1,
    "signifier" => 1,
    "shell_name" => 2,
    "core_prefix" => 1,
    "core_name" => 3
  }

  @name_syllables_path "names/beings.yaml"

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
  Dream realm beings have a
  - shell name
  - core prefix
  - core name
  """
  def show(["shell_name", "core_prefix", "core_name"], name) do
    "#{String.capitalize(Map.get(name.parts, "shell_name", @default_part))}\s#{String.capitalize(Map.get(name.parts, "core_prefix", @default_part))}#{Map.get(name.parts, "core_name", @default_part)}"
  end

  @doc """
  Generate a name of a descendant of the given being name.
  """
  def get_descendent_name(name) do
    :not_implemented
  end
end
