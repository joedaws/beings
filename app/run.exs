defmodule SimulationRunner do
  alias Cosmos.Beings.Actions
  alias Cosmos.Beings.Being
  alias Cosmos.Locations.Node

  # generate some beings
  def setup_beings() do
    for n <- 1..10, do: Being.get_random_being()
  end

  # generate a node
  def generate_single_node() do
    Node.generate_random_node()
  end

  def run_simple() do
    IO.puts("Setting up the beings and node")
    beings = setup_beings()
    node = generate_single_node()

    # round one
    # ---------------------------------
    # the all attach to the single node
    IO.puts("attaching beings to node")
    {beings, node} = Being.occupy_node(beings, [], node)
    IO.puts(node.occupancy)

    # round two
    # ---------------------------------
    IO.puts("Each being collects ichor from node")
    # TODO implement beings collecting ichor
  end
end

SimulationRunner.run_simple()
