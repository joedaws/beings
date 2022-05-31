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
  require Logger

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
      ichor: 10,
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
    # 0 because this being hasn't encountered this resource yet
    old_resource = Map.get(state, resource_type, 0)
    state = %{state | resources: Map.put(state.resources, resource_type, old_resource + amount)}
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_friend, friend_pid}, state) do
    {:noreply, %{state | friends: [friend_pid | state.friends]}}
  end

  @impl true
  def handle_call({:give_resource, resource_type, amount}, from, state) do
    old_resource = Map.get(state, resource_type, 0)

    {give_amount, new_resource} =
      cond do
        old_resource == 0 -> {0, 0}
        old_resource - amount < 0 -> {old_resource, 0}
        true -> {amount, old_resource - amount}
      end

    state = %{state | resources: Map.put(state.resources, resource_type, new_resource)}
    {:noreply, give_amount, state}
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
    old_ichor = Map.get(state, :ichor)
    {:noreply, %{state | ichor: old_ichor - 1}}
  end

  @impl true
  def handle_info(:move, state) do
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
  def handle_info(:work, state) do
    IO.puts("working on my project")
    old_ichor = state.ichor

    old_ichor = Map.get(state, :ichor)
    {:noreply, %{state | ichor: old_ichor - 1}}
  end

  @impl true
  def handle_info(:discover_beings, state) do
    # look at the occupants of the current node
    Logger.info("looking for beings")
    occupants = ServerNode.list_neighbors(state.node)
    occupants_str = Enum.join(Enum.map(occupants, fn x -> inspect(x) end))
    Logger.info("Found #{occupants_str}")

    # add a random friend if not currently friends
    random_friend = Enum.random(occupants)

    state =
      if random_friend not in state.friends do
        %{state | friends: [random_friend | state.friends]}
      else
        state
      end

    old_ichor = Map.get(state, :ichor)
    {:noreply, %{state | resources: %{state | ichor: old_ichor - 1}}}
  end

  @impl true
  def handle_info(:request_resource_from_being, state) do
    state = request_resource(state, state.friends)

    # pay the first resource amount to continue existing
    old_ichor = Map.get(state, :ichor)
    {:noreply, %{state | ichor: old_ichor - 1}}
  end

  defp request_resource(state, []) do
    Logger.info("I have no friends")
    state
  end

  defp request_resource(state, friends) do
    random_friend = Enum.random(friends)
    resource_list = ServerBeing.get_resource_types(random_friend)
    resource_type = Enum.random(resource_list)
    Logger.info("#{inspect(self())} ask #{inspect(random_friend)} for #{resource_type}")
    amount = ServerBeing.give_resource(random_friend, resource_type, 1)

    old_resource = Map.get(state.resources, resource_type, 0)
    new_amount = old_resource + amount
    Map.put(state.resources, resource_type, new_amount)
    Logger.info("#{inspect(self())} had #{old_resource} and will now have #{new_amount}")

    state
  end

  defp make_decision(state) do
    Exp.ServerBeing.print_state(state)
    old_ichor = Map.get(state.resources, :ichor)

    # a being ceases to exist if it runs out of ichor
    if old_ichor <= 0 do
      Process.send(self(), :death, [])
    end

    action = Enum.random(Exp.ServerBeing.actions())
    IO.puts("I have chosen to #{action}")
    Process.send(self(), action, [])

    # in 1 second
    Process.send_after(self(), :make_decision, 1 * 1000)
  end

  def print_state(state) do
    info_str_list = [
      "#{inspect(self())}",
      "name: #{state.name}",
      "ichor: #{state.ichor}"
    ]

    # resource_list = for {k, v} <- state.resources, do: "#{k}: #{inspect(v)}"
    resource_list = [" "]
    logger_str = Enum.join(info_str_list ++ resource_list, "\n")
    Logger.info(logger_str)
  end
end
