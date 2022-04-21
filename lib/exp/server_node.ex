defmodule Exp.ServerNode do
  # TODO finish adding in the
  use GenServer
  alias Cosmos.Locations.Node
  alias Cosmos.Beings.Bucket

  @moduledoc """
  let's use genserver a holder of a resource
  which differntially gives it out to callers.

  The client processes call this genserver and try to get ichor
  """

  # client API
  @doc """
  starts the node
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Extracts a certain commodity from the node if there is availability

  needs to remove some amount of resource from a node if possible.

  Returns `{:ok, commodity_amount}` if successful or `:error` if not
  note that if there is no more commodity, commodity_amount returned
  is 0.
  """
  def extract(server, commodity_type, amount) do
    GenServer.call(server, {:extract, commodity_type, amount})
  end

  @doc """
  Reset the amount of the commodities for the node attached to
  this genserver.
  """
  def reset(server, commodity_type) do
    GenServer.cast(server, {:rest, commodity_type})
  end

  @doc """
  client version to attach a node to this genserver
  """
  def attach(server, node) do
    GenServer.cast(server, {:attach, node})
  end

  @doc """
  gets a base amount of the commdity
  """
  def get_commodity_supply(commodity_type) do
    cond do
      commodity_type == "ichor" -> 100
      true -> 3
    end
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:extract, commodity_type, amount}, _from, nodes) do
    # TODO consider a callback to use a way to update ichor amount in node
    node_hash = Enum.at(Map.keys(nodes))
    node = Map.fetch(nodes, node_hash)
    # update the node
    old_amount = Map.get(node, commodity_type)
    new_amount = old_amount - amount

    if new_amount >= 0 do
      node = %{node | ichor: new_amount}
    end

    # update the nodes map in this server
    nodes = %{nodes | node_id => node}
    {:reply, amount, nodes}
  end

  @doc """
  attach a node to the map of nodes held by this genserver
  """
  @impl true
  def handle_cast({:attach, node}, nodes) do
    node_hash = Node.generate_id(node)

    if Map.has_key?(nodes, node_hash) do
      {:noreply, nodes}
    else
      {:noreply, Map.put(nodes, node_hash, node)}
    end
  end

  @impl true
  def handle_cast({:reset, commodity_type}, commodities) do
    {:noreply, Map.replace(commodities, commodity_type, get_commodity_supply(commodity_type))}
  end
end
