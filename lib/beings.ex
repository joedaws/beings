defmodule Beings do
  @moduledoc """
  Definitions of basic beings and their attributes
  """
  import Being

  @doc """
  The first being greets the second by shell name

  if they don't know each other then only use shell names.
  """
  def interact(b1, b2) do
    IO.puts("#{b1.shell_name}: Hello, I'm #{b1.shell_name}")
    IO.puts("#{b2.shell_name}: Greetins fellow being, I'm #{b2.shell_name}")
  end

  def hello() do
    :world
  end
end
