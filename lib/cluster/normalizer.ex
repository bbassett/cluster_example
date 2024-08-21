defmodule Cluster.Normalizer do
  @moduledoc """
  Roughly normalizes the files of an app to better cluster later
  """

  # These files appear in every app, and are therefore not useful for clustering
  @ignored_files [
    "Payload/",
    "META-INF/com.apple.FixedZipMetadata.bin",
    "META-INF/com.apple.ZipMetadata.plist",
    "iTunesMetadata.plist",
    "META-INF/"
  ]

  @doc """
  Take a map of files from an app and normalize them
  to ensure matches are more accurate
  """
  @spec normalize_data(map()) :: map()
  def normalize_data(data) when is_map(data) do
    IO.inspect("normalizing data...")

    Task.async_stream(
      data,
      fn {key, value} ->
        {key, normalize(value)}
      end,
      max_concurrency: 10
    )
    # TODO: why do we have to do this?
    |> Stream.map(fn {:ok, kv} -> kv end)
    |> Enum.into(%{})
  end

  @doc """
  Take a list of files from an app and normalize them
  to ensure matches are more accurate
  """
  @spec normalize(list(String.t())) :: list(String.t())
  def normalize(files) when is_list(files) do
    files
    |> Stream.filter(fn file -> file not in @ignored_files end)
    |> Stream.map(fn file -> remove_leading_folder(file) end)
    |> get_trigrams()
  end

  def get_trigrams(files) do
    trigrams =
      files
      |> Stream.map(fn file ->
        file
        |> String.graphemes()
        |> Stream.chunk_every(3, 1)
        |> Stream.map(fn trigram -> Enum.join(trigram) end)
      end)
      |> Stream.concat()

    trigram_map =
      trigrams
      |> Enum.group_by(& &1)
      |> Stream.map(fn {trigram, matches} ->
        {trigram, Enum.count(matches)}
      end)
      |> Enum.into(%{})

    {Enum.count(trigrams), trigram_map}
  end

  # every file begines with Payload/ so by removing that
  # we get more accurage match results
  defp remove_leading_folder("Payload/" <> file) do
    file
  end

  defp remove_leading_folder(file) do
    file
  end
end
