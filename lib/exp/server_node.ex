defmodule Exp.ServerNode do
  # TODO finish adding in the
  use GenServer

  def get_commodity_supply(commodity_type) do
    case do
      commodity_type == "ichor" -> 100
      _ -> 3
    end
  end

  @moduledoc """
  let's use genserver a holder of a resource
  which differntially gives it out to callers.

  Assume that the server node is initialized with
  100 units of ichor

  The client processes call this genserver and try to get ichor
  """

  @impl true
  def init(:ok) do
    {:ok, %{ichor_supply: get_ichor_supply("ichor")}}
  end

  @impl true
  def handle_call({:extract, commodity_type, amount}, _from, commodities) do
    Map.fetch()
    {:reply, Map.fetch(names, name), names}
  end

  @impl true
  def handle_cast({:reset, commodity_type}, commodities) do
    {:noreply, Map.replace(commodities, commodity_type, get_commodity_supply(commodity_type))}
  end
end
