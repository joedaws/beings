defmodule CosmosTest do
  use ExUnit.Case, async: true

  setup do
    cosmos = start_supervised!(Cosmos)
    %{cosmos: cosmos}
  end

  test "stores value by key", %{cosmos: cosmos} do
    assert Cosmos.get(cosmos, "being1") == nil

    b = Being.get_random_being()
    Cosmos.put(cosmos, 234, b)
    assert Cosmos.get(cosmos, 234) != nil
    assert Cosmos.get(cosmos, 234).age |> is_number
  end
end
