defmodule Cosmos.Beings.BeingTest do
  use ExUnit.Case
  alias Cosmos.Beings.Being

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
      ichor_count: 7,
      position_x: 0,
      position_y: 0
    }

    %{test_being: test_being, n1: n1, n2: n2}
  end

  test "being nil defaults" do
    b = %Being{}
    # test for default nils
    assert b.shell_name == nil
    assert b.core_prefix == nil
    assert b.core_name == nil
    assert b.age == nil
  end

  test "say full name", %{test_being: test_being, n1: n1} do
    assert test_being.shell_name == n1
    assert Being.get_full_name(test_being) |> is_bitstring
  end

  test "get tuple position", %{test_being: b} do
    assert Being.get_position(b) == {b.position_x, b.position_y}
  end

  test "move around", %{test_being: b} do
    b = Being.move_up(b, 2)
    assert b.position_y == 2

    b = Being.move_down(b, 3)
    assert b.position_y == -1

    b = Being.move_left(b, 2)
    assert b.position_x == -2

    b = Being.move_right(b, 4)
    assert b.position_x == 2
  end

  test "generate random being" do
    b = Being.get_random_being()
    IO.puts("#{Being.get_full_name(b)} was randomly generated")
  end

  test "generate id from being", %{test_being: b} do
    assert Being.generate_id(b) != nil
  end
end
