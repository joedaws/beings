defmodule Cosmos.Beings.BeingWorker do
  @moduledoc """
  Updates the being state held in the bucket
  """
  use GenServer
  alias Cosmos.Beings.Bucket

  defstruct [
    :bucket_pid,
    :being_id
  ]

  # client ---------------------------------
  def start_link(init_args) when is_list(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  def get(pid, attribute_type) do
    GenServer.call(pid, {:get, attribute_type})
  end

  def update(pid, attribute_type, new_value) do
    GenServer.cast(pid, {:update, attribute_type, new_value})
  end

  # callbacks ------------------------------
  @impl true
  def init([bucket_pid, being_id]) do
    {:ok, %{bucket_pid: bucket_pid, being_id: being_id}}
  end

  @impl true
  def handle_call({:get, attribute_type}, _from, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
    amount = Map.get(being, attribute_type)
    {:reply, amount, state}
  end

  @impl true
  def handle_cast({:update, attribute_type, new_value}, state) do
    being = Bucket.get(state.bucket_pid, state.being_id)
    new_being = %{being | attribute_type => new_value}
    Bucket.put(state.bucket_pid, state.being_id, new_being)
    {:noreply, state}
  end
end
