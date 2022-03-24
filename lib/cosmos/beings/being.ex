defmodule Cosmos.Beings.Being do
  @moduledoc """
  Beings have:
    - shell_name
    - core_prefix
    - core_name
    - ichor_count
    - node
    - age

  Think about implementing
  - Jobs for beings
  - How do they generate resources?
  """
  alias Cosmos.Beings.Being

  @data_path "./data"
  @max_age 99999
  @max_ichor 8888
  @max_starting_ichor 88

  defstruct [
    :shell_name,
    :core_prefix,
    :core_name,
    :age,
    :node,
    ichor_count: 0
  ]

  def get_full_name(b) do
    "#{b.shell_name} #{b.core_prefix}#{b.core_name}"
  end

  def get_location_node_name_and_type(b) do
    case b.node do
      nil -> "Lost in Space"
      _ -> "#{b.node.name}: #{b.node.type}"
    end
  end

  def get_random_being() do
    # Path.expand tries to convert relative paths
    path = Path.join(Path.expand(@data_path), "being_name_registry.yaml")

    {:ok, names} = YamlElixir.read_from_file(path)

    %Being{
      shell_name: Enum.random(Map.get(names, "shell_name")),
      core_prefix: Enum.random(Map.get(names, "core_prefix")),
      core_name: Enum.random(Map.get(names, "core_name")),
      age: :rand.uniform(@max_age),
      ichor_count: :rand.uniform(@max_starting_ichor),
      node: nil
    }
  end

  @doc """
  Generate a md5 for hashing the beings

  time is added to the hash string so that two beings can
  have the same name without colliding in the cosmos bucket
  """
  def generate_id(being) do
    :erlang.md5(get_full_name(being) <> (:os.system_time(:millisecond) |> to_string))
  end
end
