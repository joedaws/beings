defmodule CosmosServer.Command do
  @doc ~S"""
  Parses the given 'line' into a command.

  ## Examples

      iex> CosmosServer.Command.parse("CREATE BUCKET beings\r\n")
      {:ok, {:create, :bucket, "beings"}}

      iex> CosmosServer.Command.parse("CREATE BEING\r\n")
      {:ok, {:create, :being}}

      iex> CosmosServer.Command.parse("CREATE NODE\r\n")
      {:ok, {:create, :node}}

  Unknown commands or commands with the wrong number of args return an error.
      iex> CosmosServer.Command.parse "UNKNOWN unknown ohno\r\n"
      {:error, :unknown_command}

      iex> CosmosServer.Command.parse "CREATE thing\r\n"
      {:error, :unknown_command}
  """
  def parse(line) do
    case String.split(line) do
      ["CREATE", "BUCKET", bucket] -> {:ok, {:create, :bucket, bucket}}
      ["CREATE", "BEING"] -> {:ok, {:create, :being}}
      ["CREATE", "NODE"] -> {:ok, {:create, :node}}
      _ -> {:error, :unknown_command}
    end
  end

  @doc """
  Runs the given command
  """
  def run(command) do
    {:ok, "OK\r\n"}
  end
end
