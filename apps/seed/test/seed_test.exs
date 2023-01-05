defmodule SeedTest do
  use ExUnit.Case

  alias Cosmos.NameGenerator
  alias Cosmos.Locations.Resource

  test "connect to a database" do
    conn = Seed.get_conn()
    assert is_reference(conn)
  end

  test "read node" do
    conn = Seed.get_conn()
    # Prepare a statement
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select * from nodes;")
    :ok = Exqlite.Sqlite3.bind(conn, statement, [])

    # Step is used to run statements
    {:row, values} = Exqlite.Sqlite3.step(conn, statement)
    assert is_list(values)

    :ok = Exqlite.Sqlite3.release(conn, statement)
  end

  test "read node and validate types" do
    conn = Seed.get_conn()
    # Prepare a statement
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select * from nodes;")
    :ok = Exqlite.Sqlite3.bind(conn, statement, [])

    # Step is used to run statements
    {:row, values} = Exqlite.Sqlite3.step(conn, statement)
    assert is_list(values)

    name = "a place"
    type = Cosmos.Locations.Node.get_random_node_type()
    resource_type = Resource.get_random_resource_type()

    x = Enum.at(values, 1)
    assert is_float(x)

    y = Enum.at(values, 2)
    assert is_float(y)

    plane = Enum.at(values, 3)
    assert is_bitstring(plane)

    stratum_id = Enum.at(values, 4)
    assert is_integer(stratum_id)

    cluster_id = Enum.at(values, 5)
    assert is_integer(cluster_id)

    is_population_center = Enum.at(values, 6)
    assert is_integer(is_population_center)

    resource_yeild = Enum.at(values, 7)
    assert is_integer(resource_yeild)

    neighbors = %{}

    occupants = %{}

    occupancy_limit = 10

    node1 =
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

    assert node1.id

    :ok = Exqlite.Sqlite3.release(conn, statement)
  end

  test "create single node form db" do
    conn = Seed.get_conn()
    # Prepare a statement
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select * from nodes;")
    :ok = Exqlite.Sqlite3.bind(conn, statement, [])

    # Step is used to run statements
    {:row, values} = Exqlite.Sqlite3.step(conn, statement)

    node1 = Seed.new_node(values)

    assert node1.id

    :ok = Exqlite.Sqlite3.release(conn, statement)
  end

  test "read all nodes" do
    count = Seed.get_nodes()
    assert count == 106
  end
end
