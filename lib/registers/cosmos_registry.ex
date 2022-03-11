defmodule Registers.CosmosRegistry do
  use GenServer

  # Client API
  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the cosmos pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a cosmos associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  # Defining GenServer Callbacks

  @impl true
  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, state) do
    {names, _} = state
    {:reply, Map.fetch(names, name), state}
  end

  @impl true
  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, cosmos} = Cosmos.start_link([])
      ref = Process.monitor(cosmos)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, cosmos)
      {:noreply, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _ids, _reason}, {names, refs}) do
    {name, ref} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in Registers.CosmosRegistry: #{inspect(msg)}")
    {:noreply, state}
  end
end
