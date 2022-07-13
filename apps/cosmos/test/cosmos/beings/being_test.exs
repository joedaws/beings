defmodule Cosmos.Beings.BeingTest do
  use ExUnit.Case

  @moduletag :capture_log

  require Logger
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Rank
  alias Cosmos.Beings.Name

  setup do
    # setup a test being
    n1 = "Ghulop"
    n2 = "Jorsa"
    np = "L'"
    name_template = ["shell_name", "core_prefix", "core_name"]
    parts = %{"shell_name" => n1, "core_prefix" => np, "core_name" => n2}

    name = %Name{template: name_template, parts: parts}

    test_being = %Being{
      name: name,
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
    assert b.name == nil
    assert b.node == nil
  end

  test "say full name", %{test_being: test_being} do
    assert Being.get_full_name(test_being) |> is_bitstring
  end

  test "get node name", %{test_being: b} do
    assert Being.get_location_node_name_and_type(b) == "Lost in Space"
  end

  test "generate random being" do
    b = Being.get_random_being()
    name = Being.get_full_name(b)
    Logger.info("#{name} was randomly genereated")
  end

  test "generate id from being", %{test_being: b} do
    assert Being.generate_id(b) != nil
  end

  test "changes of rank", %{test_being: test_being} do
    # starting rank should be the lowest
    assert test_being.rank == Rank.get_lowest_rank()
    test_being = %{test_being | ichor: 222}
    {:ok, test_being} = Being.change_rank(test_being)
    assert test_being.rank != Rank.get_lowest_rank()
  end
end
