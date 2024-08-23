defmodule Cluster do
  @moduledoc """
  Documentation for `Cluster`.
  """
  require Logger

  @second_in_microseconds 1_000_000

  def cluster_apps(filepath, threshold) do
    with {:ok, data} <- __MODULE__.Parser.parse_file(filepath),
         {:ok, normalized_data} <- __MODULE__.Normalizer.normalize_data(data),
         {:ok, scored_data} <- __MODULE__.Comparator.compare_apps(normalized_data),
         {:ok, matches} <- find_matches(scored_data, threshold) do
      {:ok, matches}
    else
      {:error, reason} ->
        Logger.error("Error processing data: #{reason}")
        {:error, reason}
    end
  end

  def find_matches(comparisons, threshold) do
    matches =
      comparisons
      |> Stream.map(fn {app_id, scores} ->
        matching_apps =
          scores
          |> Stream.filter(fn {_app_id, app_score} -> app_score >= threshold end)
          |> Enum.map(fn {app_id, _app_score} -> app_id end)

        {app_id, matching_apps}
      end)
      |> Enum.reduce([], fn {app_id, matching_apps}, acc ->
        if Enum.any?(acc, fn matches -> app_id in matches end) do
          acc
        else
          [matching_apps | acc]
        end
      end)
      |> Enum.sort_by(fn matches -> Enum.count(matches) end, :desc)

    {:ok, matches}
  end

  @doc """
  developer function to help with measuring performance
  """
  def benchmark(function) do
    {time, value} =
      function
      |> :timer.tc()

    Logger.info("Function ran in #{time / @second_in_microseconds} seconds")

    value
  end
end
