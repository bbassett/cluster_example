defmodule Cluster do
  @moduledoc """
  Documentation for `Cluster`.
  """

  def test do
    __MODULE__.Parser.example_file()
    |> cluster_apps(0.8)
  end

  def cluster_apps(filepath, threshold) do
    {:ok, data} =
      filepath
      |> __MODULE__.Parser.parse_file()

    data
    |> __MODULE__.Normalizer.normalize_data()
    |> __MODULE__.Comparator.compare_apps()
    |> find_matches(threshold)
  end

  def find_matches(comparisons, threshold) do
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
  end
end
