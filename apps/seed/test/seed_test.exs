defmodule SeedTest do
  use ExUnit.Case
  doctest Seed

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

  test "read all nodes" do
    count = Seed.get_nodes()
    assert count == 106
  end
end
