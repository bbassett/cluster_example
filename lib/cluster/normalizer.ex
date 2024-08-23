defmodule Cluster.Normalizer do
  @moduledoc """
  Roughly normalizes the files of an app to better cluster later
  """
  require Logger

  defstruct [:trigrams, :count]

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
  @spec normalize_data(map()) :: {:ok, map()}
  def normalize_data(data) when is_map(data) do
    Logger.debug("normalizing data...")

    normalized =
      Task.async_stream(
        data,
        fn {key, value} ->
          {key, normalize(value)}
        end,
        max_concurrency: 10
      )
      |> Stream.map(fn
        {:ok, kv} ->
          kv

        {:error, reason} ->
          Logger.error("Error normalizing data: #{reason}")
          raise "Error normalizing data"
      end)
      |> Enum.into(%{})

    {:ok, normalized}
  end

  @doc """
  Take a list of files from an app and normalize them
    to ensure matches are more accurate, and then
    converts them to trigrams
  """
  @spec normalize(list(String.t())) :: list(String.t())
  def normalize(files) when is_list(files) do
    trigrams =
      files
      |> Stream.filter(fn file -> file not in @ignored_files end)
      |> Stream.map(fn file -> remove_leading_folder(file) end)
      |> generate_trigrams()

    total_trigrams = Enum.count(trigrams)

    %__MODULE__{
      trigrams: get_trigram_counts(trigrams),
      count: total_trigrams
    }
  end

  # every un-filtered file begins with `Payload/` so by removing that
  # we get more accurate match results
  defp remove_leading_folder("Payload/" <> file), do: file
  defp remove_leading_folder(file), do: file

  @doc """
  Convert a list of strings (filepaths) to a map of trigrams
  """
  def get_trigrams(files) do
    trigrams = generate_trigrams(files)
    total_trigrams = Enum.count(trigrams)

    trigram_map =
      trigrams
      |> Enum.reduce(%{}, fn trigram, acc ->
        Map.update(acc, trigram, 1, &(&1 + 1))
      end)

    {total_trigrams, trigram_map}
  end

  @doc """
  Convert a list of strings (filepaths) to a list of trigrams

  for each string we:
  - split into characters (graphemes)
  - group in three's
  - re-join into trigram
  """
  def generate_trigrams(files) do
    files
    |> Stream.flat_map(fn file ->
      file
      |> String.graphemes()
      |> Stream.chunk_every(3, 1)
      |> Stream.map(fn trigram -> Enum.join(trigram) end)
    end)
  end

  @doc """
  Convert a list of trigrams to a map of [trigram] => number of times it appears
  """
  def get_trigram_counts(trigrams) do
    trigrams
    |> Enum.reduce(%{}, fn trigram, acc ->
      Map.update(acc, trigram, 1, &(&1 + 1))
    end)
  end
end
