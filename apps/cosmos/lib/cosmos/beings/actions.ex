defmodule Cosmos.Beings.Actions do
  require Logger
  alias Cosmos.Beings.Being

  @moduledoc """
  Definitions of basic actions
  """

  @doc """
  The first being greets the second by name

  if they don't know each other then only use names.
  """
  def greet(b1, b2) do
    b1_says = "#{Being.get_full_name(b1)}: Hello, I'm #{Being.get_full_name(b1)}"

    b2_says = "#{Being.get_full_name(b2)}: Greetins fellow being, I'm #{Being.get_full_name(b2)}}"

    Logger.info(b1_says)
    Logger.info(b2_says)
    b1_says <> "\n" <> b2_says
  end

  @doc """
  Function to perform the transfer of commodity between two beings

  The giver gives amount of commodity to the receiver
  """
  def transfer(commodity, amount, giver, receiver) do
    # TODO add in check to make sure that giver has enough commodity to transfer
    # take commodity away from giver
    giver = %{giver | commodity => Map.get(giver, commodity) - amount}
    # give commodity to receiver
    receiver = %{receiver | commodity => Map.get(receiver, commodity) + amount}

    {:ok, giver, receiver}
  end
end
