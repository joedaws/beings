defmodule Beings.CosmosTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, cosmos} = Beings.Cosmos.start_link([])
    %{cosmos: cosmos}
  end

  test "stores value by key", %{cosmos: cosmos} do
    assert Beings.Cosmos.get(cosmos, "being1") == nil

    b = Being.get_random_being()
    Beings.Cosmos.put(cosmos, 234, b)
    assert Beings.Cosmos.get(cosmos, 234) != nil
    assert Beings.Cosmos.get(cosmos, 234).age |> is_number
  end
end
