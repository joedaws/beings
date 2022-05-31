defmodule Exp.ServerNode do
  use GenServer
  require Logger
  alias Exp.ServerNode

  defstruct [
    :name,
    :resource_type,
    :occupants,
    # these are other nodes that are connected to this node
    :neighbors
  ]

  # CLIENT ---------------------------------------------------------------------
  # default should be map like the input to init below
  def start_link(default) when is_map(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def attach(node_pid, being_pid) do
    GenServer.cast(node_pid, {:attach, being_pid})
  end

  def remove(node_pid, being_pid) do
    GenServer.cast(node_pid, {:remove, being_pid})
  end

  def list_neighbors(node_pid) do
    GenServer.call(node_pid, :list_neighbors)
  end

  def add_neighbor(node_pid, neighbor_pid) do
    GenServer.cast(node_pid, {:add_neighbor, neighbor_pid})
  end

  def get_name(node_pid) do
    GenServer.call(node_pid, :get_name)
  end

  # Callbacks -------------------------------------------------------------------
  @impl true
  def init(%{name: name, resource_type: rt, neighbors: neighbors}) do
    sn = %ServerNode{
      name: name,
      resource_type: rt,
      # this starts as an empty list if no beings are initialized
      occupants: [],
      # this is a list of process ids, empty if no neighbors
      neighbors: neighbors
    }

    distribute_resource(sn)

    {:ok, sn}
  end

  @impl true
  def handle_cast({:attach, being_pid}, state) do
    state = %{state | occupants: [being_pid | state.occupants]}
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove, being_pid}, state) do
    # delete the being pid if it is an occupant
    new_occupants = List.delete(state.occupants, being_pid)
    state = %{state | occupants: new_occupants}
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_neighbor, neighbor_pid}, state) do
    state = %{state | neighbors: [neighbor_pid | state.neighbors]}
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_name, _from, state) do
    {:reply, state.name, state}
  end

  @impl true
  def handle_call(:list_neighbors, _from, state) do
    {:reply, state.neighbors, state}
  end

  @impl true
  def handle_info(:distribute_resource, state) do
    # TODO change the amount maybe?
    amount = 1

    # send resources to each being attached using the ServerBeing client API
    Enum.map(state.occupants, fn pid ->
      Exp.ServerBeing.receive_resource(pid, state.resource_type, amount)
    end)

    distribute_resource(state)

    # nothing to update in the current state
    {:noreply, state}
  end

  defp distribute_resource(state) do
    Exp.ServerNode.print_state(state)

    Process.send_after(self(), :distribute_resource, 1 * 1000)
  end

  def print_state(state) do
    logger_str = ["name: #{state.name}", "occupants: #{length(state.occupants)}"]
    Logger.info(Enum.join(logger_str, " "))
  end
end
