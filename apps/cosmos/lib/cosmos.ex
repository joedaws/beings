defmodule Cosmos do
  use Application

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    Cosmos.Beings.Supervisor.start_link(name: Cosmos.Beings.Supervisor)
  end
end
