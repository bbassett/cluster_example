defmodule Cluster.Parser do
  @moduledoc """
  Parses a file and returns elixir terms
  """
  require Logger

  @doc """
  Parse a string into a list of tokens.
  """
  def stream(filepath) do
    if File.exists?(filepath) do
      filepath
      |> File.stream!([], :line)
      |> Jaxon.Stream.from_enumerable()
      |> Jaxon.Stream.values()
    else
      # return an error in accordance with application conventions
      {:error, "File does not exist"}
    end
  end

  @doc """
  Reads a file and returns parsed json
  """
  def parse_file(filepath) do
    with {:exists, true} <- {:exists, File.exists?(filepath)},
         {:ok, filedata} <- File.read(filepath),
         {:ok, json} <- Jason.decode(filedata) do
      {:ok, json}
    else
      {:exists, false} -> {:error, "File does not exist"}
      {:ok, ""} -> {:error, "File is empty"}
      {:error, reason} -> {:error, reason}
    end
  end

  def example_file do
    "#{File.cwd!()}/priv/fixtures/classifier-sample.json"
  end
end
