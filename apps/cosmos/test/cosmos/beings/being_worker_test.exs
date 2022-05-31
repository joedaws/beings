defmodule Cosmos.Beings.BeingWorkerTest do
  use ExUnit.Case, async: true
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.BeingWorker

  setup do
    registry = start_supervised!(Cosmos.Beings.Registry)
    Cosmos.Beings.Registry.create(registry, "beings")

    {:ok, beings} = Cosmos.Beings.Registry.lookup(registry, "beings")

    b = Being.get_random_being()
    # alive false prevents the cycle logic from running while testing
    b = %{b | ichor: 100, alive: false}
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

  test "ichor decrease each cycle", %{beings: _beings, worker: worker} do
    old_ichor = BeingWorker.get(worker, :ichor)
    BeingWorker.revive(worker)
    BeingWorker.hibernate(worker)
    new_ichor = BeingWorker.get(worker, :ichor)

    assert new_ichor == old_ichor - 1
  end
end
