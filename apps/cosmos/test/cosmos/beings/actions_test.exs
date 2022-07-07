defmodule Cosmos.Beings.ActionsTest do
  use ExUnit.Case
  doctest Cosmos.Beings.Actions

  @moduletag :capture_log

  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Actions
  alias Cosmos.Beings.Name
  alias Cosmos.Beings.Rank

  setup do
    # setup a test being
    n1 = "Ghulop"
    n2 = "Jorsa"
    np = "L'"
    name_template = ["shell_name", "core_prefix", "core_name"]
    parts = %{"shell_name" => n1, "core_prefix" => np, "core_name" => n2}

    name = %Name{template: name_template, parts: parts}

    test_being_1 = %Being{
      name: name,
      age: 666,
      node: nil,
      ichor: 7,
      rank: Rank.get_lowest_rank()
    }

    # setup a test being
    n1 = "Shaptuwy"
    n2 = "Fe"
    np = "L'"
    name_template = ["shell_name", "core_prefix", "core_name"]
    parts = %{"shell_name" => n1, "core_prefix" => np, "core_name" => n2}

    name = %Name{template: name_template, parts: parts}

    test_being_2 = %Being{
      name: name,
      age: 3,
      ichor: 111
    }

    %{test_beings: [test_being_1, test_being_2]}
  end

  test "greet each other", %{test_beings: [b1, b2]} do
    assert is_bitstring(Actions.greet(b1, b2))
  end

  test "perform transfer", %{test_beings: [b1, b2]} do
    b1_original_ichor = b1.ichor
    b2_original_ichor = b2.ichor
    amount = 3
    commodity = :ichor

    {:ok, b1, b2} = Actions.transfer(commodity, amount, b1, b2)

    assert b1.ichor == b1_original_ichor - amount
    assert b2.ichor == b2_original_ichor + amount
  end
end
