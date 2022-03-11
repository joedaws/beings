defmodule BeingTest do
  use ExUnit.Case

  setup do
    # setup a test being
    n1 = "Ghulop"
    n2 = "Jorsa"

    test_being = %Being{
      shell_name: n1,
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
    assert b.core_name == nil
    assert b.age == nil
  end

  test "say full name", %{test_being: test_being, n1: n1} do
    # Name should read n1 <> n2 in the output
    assert test_being.shell_name == n1
    Being.say_full_name(test_being)
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
    IO.puts("#{b.shell_name} #{b.core_name} was randomly generated")
  end

  test "generate id from being", %{test_being: b} do
    assert Being.generate_id(b) != nil
  end
end
