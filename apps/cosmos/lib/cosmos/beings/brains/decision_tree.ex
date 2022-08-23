defmodule Cosmos.Beings.Brains.DecisionTree do
  @moduledoc """
  observations:
    - resources
    - ritual
    - ichor
    - worker_pid

  This module implements parameterized decision tree
  which being instances can use to make decisions.

  The struct determines parameters needed to
  make a decision using this decision tree

  first choice:
  - low on ichor or not

  level 2:
  - look for resourcdes
  - if not low on ichor then search for
  """
  require Logger
  alias Cosmos.Magic.Ritual
  alias Cosmos.Beings.BeingWorker
  alias Cosmos.Beings.Being
  alias Cosmos.Beings.Actions
  alias Cosmos.Beings.Brains.DecisionTreeNode

  @doc """
  This function returns the root node of a tree geared at survival.
  """
  def get_graph(:survival_tree, observations, parameters) do
    n_move_to_node = %DecisionTreeNode{
      action: fn ->
        Actions.move_to_node(observations.being.id, Enum.random(observations.node.neighbors))
      end,
      description: "Action: move to a random node."
    }

    n_perform_ritual = %DecisionTreeNode{
      action: fn ->
        Actions.perform_ritual(
          observations.being.id,
          :random.uniform(length(observations.being.rituals) - 1)
        )
      end,
      description: "Action: perform random ritual."
    }

    n_harvest = %DecisionTreeNode{
      action: fn -> Actions.harvest(observations.being.id) end,
      description: "Action: harvest from current node."
    }

    # next == 0 means we can obtain needed resources
    n11 = %DecisionTreeNode{
      next:
        if observations.node.resource_type in Map.keys(observations.being.resources) do
          0
        else
          1
        end,
      children: [n_harvest, n_move_to_node],
      description: "Can I collect needed ritual resources?"
    }

    # next == 1 means we can perform ritual
    n10 = %DecisionTreeNode{
      next: DecisionTreeNode.get_can_perform_any_ritual_index(observations.being),
      children: [n11, n_perform_ritual],
      description: "Can I perform a ritual?"
    }

    n00 = %DecisionTreeNode{
      next:
        DecisionTreeNode.get_partition_index(
          [parameters.ichor_threshold],
          observations.being.ichor
        ),
      children: [n10, n11],
      description: "Am I low on ichor?"
    }
  end

  @doc """
  Given a root node of a tree, this function follows the path
  based on the decisions to a leaf node containing a decision.
  """
  def decision_path(node) do
    if node.action == nil do
      # move to next node
      decision_path(Enum.at(node.children, node.next))
    else
      # perform the action
      node.action.()
      Logger.info("Decision: #{node.description}")
    end
  end

  @doc """
  Entry point which constructs the graph and moves down the path.
  """
  def make_decision(graph_type, observations, parameters) do
    if observations.node do
      root_node = get_graph(graph_type, observations, parameters)
      decision_path(root_node)
    else
      Logger.info(
        "Decision cannot be made since #{inspect(observations.being.id)} is not attached to a node"
      )
    end
  end
end
