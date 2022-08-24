defmodule Cosmos.Engine.BasicRunner do
  use GenServer
  # alias Cosmos.Beings.Being
  # alias Cosmos.Bucket

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(_) do
    {:ok, %{}, {:continue, :schedule_next_run}}
  end

  @impl true
  def handle_continue(:schedule_next_run, state) do
    # 5000 milliseconds is 5 seconds
    next_run_delay = 5000
    # TODO add functionality to create new beings until there are 10
    Process.send_after(self(), :create_new_being, next_run_delay)
    {:noreply, state}
  end

  @doc """
  add new being to state as long as there 10 or fewer beings
  """
  @impl true
  def handle_info(:create_new_being, state) do
    IO.puts("hello there")
    {:noreply, state, {:continue, :schedule_next_run}}
  end
end
