defmodule Exp.ServerNode do
  use GenServer
  alias Exp.ServerNode

  defstruct [
    :name,
    :resource_type,
    :occupants,
    # these are other nodes that are connected to this node
    :neighbors
  ]

  # CLIENT
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def attach(node_pid, being_pid) do
    GenServer.cast(node_pid, {:attach, being_pid})
  end

  # Callbacks
  @impl true
  def init([%{name: name, resource_type: rt, neighbors: neighbors}]) do
    sn = %ServerNode{
      name: name,
      resource_type: rt,
      # this starts as an empty list if no beings are initialized
      occupants: [],
      # this is a list, empty if no neighbors
      neighbors: neighbors
    }

    distribute_resource(sn)

    {:ok, sn}
  end

  @impl true
  def handle_cast({:attach, being_pid}, state) do
    state = %{state | occupants: [being_pid | state.occupants]}
    {:reply, state}
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
    IO.puts("name: #{state.name}")
    IO.puts("resource_type: #{state.resource_type}")
    IO.puts("number occupants: #{length(state.occupants)}")
  end
end
