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
end
