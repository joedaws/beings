defmodule Exp.Engine do
  alias Exp.ServerNode
  alias Exp.ServerBeing
  alias Exp.Resources

  def run() do
    # setup some places
    {:ok, node1} =
      ServerNode.start_link(%{
        name: "Train station",
        resource_type: Resources.get_random_resource(),
        neighbors: []
      })

    {:ok, node2} =
      ServerNode.start_link(%{
        name: "Lost Library",
        resource_type: Resources.get_random_resource(),
        neighbors: []
      })

    # add neighbors to node1 and node2
    ServerNode.add_neighbor(node1, node2)
    ServerNode.add_neighbor(node2, node1)

    # setup some beings
    {:ok, being1} = ServerBeing.start_link(%{name: "Johnson", node: node1})
    {:ok, being2} = ServerBeing.start_link(%{name: "Gorlap", node: node2})

    # add each being as friends
    ServerBeing.add_friend(being1, being2)
    ServerBeing.add_friend(being2, being1)

    # this is here to define the maximum length the simulation will run
    :timer.sleep(60 * 1000)
  end
end

Exp.Engine.run()
