defmodule Cosmos.Locations.NodeTest do
  use ExUnit.Case

  @moduletag :capture_log

  alias Cosmos.Locations.Node

  setup do
    # make a simple node
    test_node = %Node{
      name: "test_node",
      type: Node.get_random_node_type(),
      occupants: [],
      occupancy_limit: 10
    }

    %{test_node: test_node}
  end

  test "node attributes", %{test_node: test_node} do
    assert test_node.name |> is_bitstring
    assert test_node.name |> is_bitstring
    assert length(test_node.occupants) < test_node.occupancy_limit
  end

  test "test generate node with given name" do
    node = Node.generate_node("The hello Cafe")
    assert length(node.occupants) == 0
  end

  test "test generate random node" do
    node = Node.generate_random_node()
    assert node.name |> is_bitstring
  end
end
