defmodule Being do
  # TODO be sure to add ids to beings
  # need to find a way to generate ids

  @moduledoc """
  shell_name
  core_name
  ichor_count
  age
  position_x integer positions
  position_y integer positions
  """

  @data_path "./data"
  @max_age 99999
  @max_ichor 8888
  @max_starting_ichor 88

  defstruct [
    :shell_name,
    :core_name,
    :age,
    ichor_count: 0,
    position_x: 0,
    position_y: 0
  ]

  def say_full_name(b) do
    IO.puts("#{b.shell_name} #{b.core_name}")
  end

  def get_position(b) do
    {b.position_x, b.position_y}
  end

  # TODO consider just using one single move function

  def move_up(b, n \\ 1) do
    new_y = b.position_y + n
    %{b | position_y: new_y}
  end

  def move_down(b, n \\ 1) do
    new_y = b.position_y - n
    %{b | position_y: new_y}
  end

  def move_left(b, n \\ 1) do
    new_x = b.position_x - n
    %{b | position_x: new_x}
  end

  def move_right(b, n \\ 1) do
    new_x = b.position_x + n
    %{b | position_x: new_x}
  end

  def get_random_being() do
    # Path.expand tries to convert relative paths
    path = Path.join(Path.expand(@data_path), "being_name_registry.yaml")

    {:ok, names} = YamlElixir.read_from_file(path)

    %Being{
      shell_name: Enum.random(Map.get(names, "shell_name")),
      core_name: Enum.random(Map.get(names, "core_name")),
      age: :rand.uniform(@max_age),
      ichor_count: :random.uniform(@max_starting_ichor),
      position_x: 0,
      position_y: 0
    }
  end

  def generate_id() do
    # TODO fill in this function
    1
  end
end
