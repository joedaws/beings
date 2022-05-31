defmodule Cosmos.Beings.BeingWorkerTest do
  use ExUnit.Case, async: true
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.BeingWorker

  setup do
    registry = start_supervised!(Cosmos.Beings.Registry)
    Cosmos.Beings.Registry.create(registry, "beings")

    {:ok, beings} = Cosmos.Beings.Registry.lookup(registry, "beings")

    b = Being.get_random_being()
    b = %{b | ichor: 100}
    b_id = Being.generate_id(b)

    Cosmos.Beings.Bucket.put(beings, b_id, b)

    {:ok, worker} = BeingWorker.start_link([beings, b_id])

    %{beings: beings, worker: worker}
  end

  test "get being state", %{beings: _beings, worker: worker} do
    assert 100 == BeingWorker.get(worker, :ichor)
  end

  test "update being state", %{beings: _beings, worker: worker} do
    new_ichor_amount = 300
    BeingWorker.update(worker, :ichor, new_ichor_amount)
    ichor = BeingWorker.get(worker, :ichor)
    assert new_ichor_amount == ichor
  end
end
