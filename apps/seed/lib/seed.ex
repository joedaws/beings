defmodule Seed do
  @moduledoc """
  Module to help seed the cosmos simulation
  """

  @db_path "start_cosmos.db"

  def get_conn do
    data_path = Application.fetch_env!(:cosmos, :data_path)
    path = Path.join(data_path, @db_path)
    {:ok, conn} = Exqlite.Sqlite3.open(path)
    conn
  end

  def get_nodes do
    conn = get_conn()
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select * from nodes;")
    :ok = Exqlite.Sqlite3.bind(conn, statement, [])

    # Step is used to run statements
    sqlite_step(conn, statement)
  end

  def sqlite_step(conn, statement) do
    output = Exqlite.Sqlite3.step(conn, statement)
    node_counter = 1
    sqlite_step(conn, statement, output, node_counter)
  end

  def sqlite_step(conn, statement, output, node_counter) when output == :done do
    # return the index of the final thing
    node_counter - 1
  end

  def sqlite_step(conn, statement, output, node_counter) do
    output = Exqlite.Sqlite3.step(conn, statement)

    sqlite_step(conn, statement, output, node_counter + 1)
  end

  @doc """
  Creates a new Node struct given the values which
  were read from the database

  If updating the schema of the database, you'll need
  to also update this function accordingly.
  """

  def new_node(values) do
    conn = Seed.get_conn()
    # Prepare a statement
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select * from nodes;")
    :ok = Exqlite.Sqlite3.bind(conn, statement, [])

    # Step is used to run statements
    {:row, values} = Exqlite.Sqlite3.step(conn, statement)

    name = "a place"
    type = Cosmos.Locations.Node.get_random_node_type()
    resource_type = Cosmos.Locations.Resource.get_random_resource_type()

    x = Enum.at(values, 1)
    y = Enum.at(values, 2)
    plane = Enum.at(values, 3)
    stratum_id = Enum.at(values, 4)
    cluster_id = Enum.at(values, 5)
    is_population_center = Enum.at(values, 6)
    resource_yeild = Enum.at(values, 7)

    neighbors = %{}
    occupants = %{}
    occupancy_limit = 10

    Cosmos.Locations.Node.new(
      name,
      type,
      resource_yeild,
      resource_type,
      x,
      y,
      plane,
      stratum_id,
      cluster_id,
      is_population_center,
      neighbors,
      occupants,
      occupancy_limit
    )
  end
end
