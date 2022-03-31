defmodule Cosmos.Beings.ActionsTest do
  use ExUnit.Case
  doctest Cosmos.Beings.Actions

  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Actions

  setup do
    # add some being instances
    n1 = "Ghulop"
    n2 = "Jorsa"
    np = "L'"

    test_being_1 = %Being{
      shell_name: n1,
      core_prefix: np,
      core_name: n2,
      age: 666,
      ichor_count: 7
    }

    test_being_2 = %Being{
      shell_name: "Shaptuwy",
      core_prefix: np,
      core_name: "Fe",
      age: 3,
      ichor_count: 111
    }

    %{test_beings: [test_being_1, test_being_2]}
  end

  test "greet each other", %{test_beings: [b1, b2]} do
    assert is_bitstring(Actions.greet(b1, b2))
  end

  test "perform transfer", %{test_beings: [b1, b2]} do
    b1_original_ichor_count = b1.ichor_count
    b2_original_ichor_count = b2.ichor_count
    amount = 3
    commodity = :ichor_count

    {:ok, b1, b2} = Actions.transfer(commodity, amount, b1, b2)

    assert b1.ichor_count == b1_original_ichor_count - amount
    assert b2.ichor_count == b2_original_ichor_count + amount
  end
end
