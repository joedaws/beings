defmodule Exp.ServerBeing do
  @moduledoc """
  beings now have ichor and resources

  resources are used to sustain life

  ichor is used to rank up and

  {:ok, sb} =
  Exp.ServerBeing.start_link(%{
    name: "Johnson",
    node: "hello_world_station"
  })

  :timer.sleep(60 * 1000)
  """
  use GenServer

  alias Exp.ServerBeing
  alias Exp.ServerNode

  defstruct [
    # string to represent the beings name
    :name,
    # an integer for now, but will be mapped to a name.
    :rank,
    # a map from resource_type to ammount
    :resources,
    # integer amoung of ichor
    :ichor,
    # boolean for status of the being
    :alive,
    # list of pids to friends
    :friends,
    # nil | pid of occupied name
    :node
  ]

  def actions() do
    [
      # do nothing this cycle
      :rest,
      # get one dolalr, expend one food
      :work,
      # find beings to add to friends list
      :discover_beings,
      # must know other being, but ask for food
      :request_resource_from_being,
      # move to a random new node
      :move
    ]
  end

  # Client ----------------------------------------------------------------
  def start_link(default) when is_map(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def receive_resource(pid, resource_type, amount) do
    GenServer.cast(pid, {:receive_resource, resource_type, amount})
  end

  def check_resource(pid, resource_type) do
    GenServer.cast(pid, {:check_resource, resource_type})
  end

  def get_resource_types(pid) do
    GenServer.call(pid, :get_resource_types)
  end

  @doc """
  Give a resource to the being with the given process id.

  Should only be used by another being acting as a client.
  """
  def give_resource(pid, resource_type, amount) do
    GenServer.call(pid, {:give_resource, resource_type, amount})
  end

  def add_friend(pid, friend_pid) do
    GenServer.cast(pid, {:add_friend, friend_pid})
  end

  # Callbacks
  @impl true
  def init(%{name: name, node: node_pid}) do
    sb = %ServerBeing{
      name: name,
      rank: 1,
      resources: %{bones: 10},
      ichor: 0,
      alive: true,
      friends: [],
      node: node_pid
    }

    if is_pid(node_pid) do
      ServerNode.attach(node_pid, self())
    end

    # starts the decision loop
    make_decision(sb)

    {:ok, sb}
  end

  @impl true
  def handle_cast({:receive_resource, resource_type, amount}, state) do
    old_resource = Map.get(state, resource_type)
    {:noreply, %{state | resource_type => old_resource + amount}}
  end

  @impl true
  def handle_cast({:move, node_pid}, state) do
    # first ask the current node for list of neighbors
    neighbors = ServerNode.list_neighbors(state.node)
    new_node = Enum.random(neighbors)

    # remove being from current node
    ServerNode.remove(state.node, self())

    # add being to new node
    ServerNode.attach(new_node, self())

    # update the state
    {:noreply, %{state | node: new_node}}
  end

  @impl true
  def handle_cast({:add_friend, friend_pid}, state) do
    {:noreply, %{state | friends: [friend_pid | state.friends]}}
  end

  @impl true
  def handle_call({:give_resource, resource_type, amount}, _from, state) do
    old_resource = Map.get(state, resource_type)

    {give_amount, new_resource} =
      if old_resource - amount < 0 do
        {old_resource, 0}
      else
        {amount, old_resource - amount}
      end

    {:noreply, give_amount, %{state | resource_type => new_resource}}
  end

  @impl true
  def handle_call({:check_resource, resource_type}, _from, state) do
    amount = Map.get(state.resources, resource_type)
    IO.puts("I have #{amount} #{resource_type}")
    {:reply, amount, state}
  end

  @impl true
  def handle_call(:get_resource_types, _from, state) do
    resource_types_list = Map.keys(state.resources)
    {:reply, resource_types_list, state}
  end

  @impl true
  def handle_info(:death, state) do
    {:noreply, %{state | alive: false}}
  end

  @impl true
  def handle_info(:make_decision, state) do
    case state.alive do
      true -> make_decision(state)
      _ -> IO.puts("I once lived.")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:rest, state) do
    IO.puts("thinking while resting")
    resource_type = Enum.at(Map.keys(state.resources), 0)
    old_resource = Map.get(state.resources, resource_type)
    {:noreply, %{state | resources: %{state.resources | resource_type => old_resource - 1}}}
  end

  @impl true
  def handle_info(:work, state) do
    IO.puts("working on my project")
    resource_type = Enum.at(Map.keys(state.resources), 0)
    old_resource = Map.get(state.resources, resource_type)
    old_ichor = state.ichor

    {:noreply,
     %{
       state
       | ichor: old_ichor + 1,
         resources: %{state.resources | resource_type => old_resource - 1}
     }}
  end

  @impl true
  def handle_info(:discover_beings, state) do
    # look at the occupants of the current node
    occupants = ServerNode.list_neighbors(state.node)

    # add a random friend if not currently friends
    random_friend = Enum.random(occupants)

    if random_friend not in state.friends do
      state = %{state | friends: [random_friend | state.friends]}
    end

    resource_type = Enum.at(Map.keys(state.resources), 0)
    old_resource = Map.get(state.resources, resource_type)
    {:noreply, %{state | resources: %{state.resources | resource_type => old_resource - 1}}}
  end

  @impl true
  def handle_info(:request_resource_from_being, state) do
    # chose a random friend to ask resources from
    if length(state.friends) > 0 do
      random_friend = Enum.random(state.friends)
      resource_list = ServerBeing.get_resource_types(random_friend)
      resource_type = Enum.random(resource_list)
      # TODO replace 1 with a more meaningful amount
      amount = ServerBeing.give_resource(random_friend, resource_type, 1)

      old_resource = 0

      if Map.get(state.resources, resource_type) do
        old_resource = Map.get(state.resources, resource_type)
      end

      state = %{state | resources: %{state.resources | resource_type => old_resource + amount}}
    end

    # pay the first resource amount to continue existing
    resource_type = Enum.at(Map.keys(state.resources), 0)
    old_resource = Map.get(state.resources, resource_type)
    {:noreply, %{state | resources: %{state.resources | resource_type => old_resource - 1}}}
  end

  defp make_decision(state) do
    Exp.ServerBeing.print_state(state)
    resource_type = Enum.at(Map.keys(state.resources), 0)
    old_resource = Map.get(state.resources, resource_type)

    if old_resource <= 0 do
      Process.send(self(), :death, [])
    end

    action = Enum.random(Exp.ServerBeing.actions())
    IO.puts("I have chosen to #{action}")
    Process.send(self(), action, [])

    # in 1 second
    Process.send_after(self(), :make_decision, 1 * 1000)
  end

  def print_state(state) do
    IO.puts("name: #{state.name}")
    IO.puts("node: #{ServerNode.get_name(state.node)}")
    resource_list = for {k, v} <- state.resources, do: "#{k}: #{v}"
    resource_str = Enum.join(resource_list, "\n")
    IO.puts(Enum.join(["resources...\n", resource_str]))
  end
end
