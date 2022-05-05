defmodule Cosmos.Beings.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Cosmos.Beings.Registry, name: Cosmos.Beings.Registry}
    ]

    # :one_for_one means that if a child dies,
    # it will be the only one restarted.
    Supervisor.init(children, strategy: :one_for_one)
  end
end
