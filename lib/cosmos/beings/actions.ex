defmodule Cosmos.Beings.Actions do
  @moduledoc """
  Definitions of basic actions
  """

  @doc """
  The first being greets the second by shell name

  if they don't know each other then only use shell names.
  """
  def greet(b1, b2) do
    b1_says = "#{Cosmos.Beings.Being.get_full_name(b1)}: Hello, I'm #{b1.shell_name}"

    b2_says =
      "#{Cosmos.Beings.Being.get_full_name(b2)}: Greetins fellow being, I'm #{b2.shell_name}"

    IO.puts(b1_says)
    IO.puts(b2_says)
    b1_says <> "\n" <> b2_says
  end
end
