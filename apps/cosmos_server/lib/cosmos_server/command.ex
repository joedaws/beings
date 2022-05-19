defmodule CosmosServer.Command do
  @doc ~S"""
  Parses the given 'line' into a command.

  ## Examples

      iex> CosmosServer.Command.parse("CREATE BUCKET beings\r\n")
      {:ok, {:create, :bucket, "beings"}}

      iex> CosmosServer.Command.parse("CREATE BEING bucket\r\n")
      {:ok, {:create, :being, "bucket"}}

      iex> CosmosServer.Command.parse("CREATE NODE\r\n")
      {:ok, {:create, :node}}

      iex> CosmosServer.Command.parse("GET BEING ALL bucket\r\n")
      {:ok, {:get, :being, :all, "bucket"}}

  Unknown commands or commands with the wrong number of args return an error.
      iex> CosmosServer.Command.parse "UNKNOWN unknown ohno\r\n"
      {:error, :unknown_command}

      iex> CosmosServer.Command.parse "CREATE thing\r\n"
      {:error, :unknown_command}
  """
  def parse(line) do
    case String.split(line) do
      ["CREATE", "BUCKET", bucket] -> {:ok, {:create, :bucket, bucket}}
      ["CREATE", "BEING", bucket] -> {:ok, {:create, :being, bucket}}
      ["CREATE", "NODE"] -> {:ok, {:create, :node}}
      ["GET", "BEING", "ALL", bucket] -> {:ok, {:get, :being, :all, bucket}}
      _ -> {:error, :unknown_command}
    end
  end

  @doc """
  Runs the given command
  """
  def run(command)

  def run({:create, :bucket, bucket}) do
    Cosmos.Beings.Registry.create(Cosmos.Beings.Registry, bucket)
    {:ok, "OK\r\n"}
  end

  def run({:create, :being, bucket}) do
    being = Cosmos.Beings.Being.get_random_being()
    {:ok, bucket} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket)
    Cosmos.Beings.Bucket.put(bucket, Cosmos.Beings.Being.generate_id(being), being)
    {:ok, "OK\r\n"}
  end

  def run({:get, :being, :all, bucket}) do
    {:ok, bucket} = Cosmos.Beings.Registry.lookup(Cosmos.Beings.Registry, bucket)
    values = Cosmos.Beings.Bucket.keys(bucket)
    string_values = Enum.map(values, fn x -> Base.encode64(x) end)
    {:ok, "#{string_values}\n"}
  end
end
