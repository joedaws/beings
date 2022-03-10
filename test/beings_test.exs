defmodule BeingsTest do
  use ExUnit.Case
  doctest Beings

  setup do
    # add some being instances
    n1 = "Ghulop"
    n2 = "Jorsa"

    test_being_1 = %Being{
      shell_name: n1,
      core_name: n2,
      age: 666,
      ichor_count: 7,
      position_x: 0,
      position_y: 0
    }

    test_being_2 = %Being{
      shell_name: "Shaptuwy",
      core_name: "Fe",
      age: 3,
      ichor_count: 111,
      position_x: 0,
      position_y: 0
    }

    %{test_beings: [test_being_1, test_being_2]}
  end

  test "greet each other", %{test_beings: [b1, b2]} do
    Beings.interact(b1, b2)
    assert Beings.hello() == :world
  end
end
