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
end
