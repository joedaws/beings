defmodule CosmosServerTest do
  use ExUnit.Case
  doctest CosmosServer

  test "greets the world" do
    assert CosmosServer.hello() == :world
  end
end
