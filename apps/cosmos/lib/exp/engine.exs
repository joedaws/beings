defmodule Cosmos.Exp.Engine do
  def run() do
    task = Task.async(fn -> IO.puts("sometime has passed") end)
    :timer.sleep(1000)
    Task.await(task)
    run()
  end
end
