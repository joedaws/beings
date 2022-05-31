defmodule Cosmos.Beings.BeingTest do
  use ExUnit.Case
  require Logger
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Rank
  alias Cosmos.Locations.Node

  setup do
    # setup a test being
    n1 = "Ghulop"
    n2 = "Jorsa"
    np = "L'"

    test_being = %Being{
      shell_name: n1,
      core_prefix: np,
      core_name: n2,
      age: 666,
      node: nil,
      ichor: 7,
      rank: Rank.get_lowest_rank()
    }

    %{test_being: test_being, n1: n1, n2: n2}
  end

  test "being nil defaults" do
    b = %Being{}
    # test for default nils
    assert b.shell_name == nil
    assert b.core_prefix == nil
    assert b.core_name == nil
  end

  test "say full name", %{test_being: test_being, n1: n1} do
    assert test_being.shell_name == n1
    assert Being.get_full_name(test_being) |> is_bitstring
  end

  test "get node name", %{test_being: b} do
    assert Being.get_location_node_name_and_type(b) == "Lost in Space"
  end

  test "set being node", %{test_being: b} do
    node = %Node{
      name: "here",
      type: Node.get_random_node_type(),
      occupancy: 1,
      occupancy_limit: 10
    }

    b = %{b | node: node}

    assert Node.get_name(node) == Node.get_name(b.node)
  end

  test "generate random being" do
    b = Being.get_random_being()
    name = Being.get_full_name(b)
    Logger.info("#{name} was randomly genereated")
  end

  test "generate id from being", %{test_being: b} do
    assert Being.generate_id(b) != nil
  end

  test "test changes of rank", %{test_being: test_being} do
    # starting rank should be the lowest
    assert test_being.rank == Rank.get_lowest_rank()
    test_being = %{test_being | ichor: 222}
    {:ok, test_being} = Being.change_rank(test_being)
    assert test_being.rank != Rank.get_lowest_rank()
  end
end
