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
      ichor: 7
    }

    test_being_2 = %Being{
      shell_name: "Shaptuwy",
      core_prefix: np,
      core_name: "Fe",
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
