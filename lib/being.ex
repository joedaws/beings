defmodule Being do
  @moduledoc """
  shell_name
  core_name
  ichor_count
  age
  position_x integer positions
  position_y integer positions
  """
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
end
