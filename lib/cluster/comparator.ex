defmodule Cluster.Comparator do
  @moduledoc """
  """

  def compare_apps(data) do
    data_stream =
      data
      |> Stream.with_index()

    total = Enum.count(data_stream)

    # TODO: refactor this to be a `Task.async_stream` also, so that it can happen concurrently
    # it will be "less performant" because it will re-test apps, but it will be
    # faster because it can happen 10 at a time
    # also, benchmark this
    data_stream
    |> Enum.reduce(%{}, fn {{app_id, _files}, index}, comparisons ->
      IO.inspect("comparing app #{index} / #{total}")
      compare(app_id, data, comparisons)
    end)
  end

  # compare one app to all other apps
  # if a comparison has already been done, it's in `comparisons`, so just use that score
  defp compare(app_id, data, comparisons)
       when is_map(data) and is_binary(app_id) and is_map(comparisons) do
    files = data[app_id]

    scores =
      data
      |> Stream.map(fn {other_app_id, other_files} ->
        existing_score = get_in(comparisons, [other_app_id, app_id])

        score =
          if existing_score do
            existing_score
          else
            compare_files(files, other_files)
          end

        {other_app_id, score}
      end)
      |> Enum.into(%{})

    Map.put(comparisons, app_id, scores)
  end

  def compare_files(files, other_files) do
    {files_trigrams_total, files_trigrams} = files
    {other_files_trigrams_total, other_files_trigrams} = other_files

    total_trigrams = files_trigrams_total + other_files_trigrams_total

    shared_trigrams =
      files_trigrams
      |> Stream.map(fn {trigram, count} ->
        if other_files_trigrams[trigram] do
          count + other_files_trigrams[trigram]
        else
          0
        end
      end)
      |> Enum.sum()

    shared_trigrams / total_trigrams
  end
end
