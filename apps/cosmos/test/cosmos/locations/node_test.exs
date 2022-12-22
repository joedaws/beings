defmodule Cosmos.Locations.NodeTest do
  use ExUnit.Case

  @moduletag :capture_log

  alias Cosmos.Locations.Node
  alias Cosmos.Locations.Name

  setup do
    # make a simple node
    test_node = %Node{
      name: Name.generate_name("warped_nature"),
      type: Node.get_random_node_type(),
      occupants: [],
      occupancy_limit: 10
    }

    %{test_node: test_node}
  end

  test "node attributes", %{test_node: test_node} do
    assert Name.string(test_node.name) |> is_bitstring
    assert length(test_node.occupants) < test_node.occupancy_limit
  end

  test "generate node with given name" do
    name = Name.generate_name("warped_nature")
    node = Node.generate_node(name)
    assert length(node.occupants) == 0
  end

  test "generate random node" do
    node = Node.generate_random_node()
    assert Node.get_name(node) |> is_bitstring
  end

  test "test char to strings protocol", %{test_node: test_node} do
    node_string = to_string(test_node)
    assert is_bitstring(node_string)
  end
end
