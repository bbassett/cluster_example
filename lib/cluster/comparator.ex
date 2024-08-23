defmodule Cluster.Comparator do
  @moduledoc """
  """
  require Logger
  alias Cluster.Normalizer

  def compare_apps(data) do
    any_empty_apps? = Enum.any?(data, fn {_app_id, %Normalizer{count: count}} -> count == 0 end)

    if any_empty_apps? do
      {:error, "Encountered an app without files"}
    else
      scored_data =
        data
        |> Enum.reduce(%{}, fn {app_id, _files}, comparisons ->
          Logger.debug("comparing app #{app_id}")
          compare(app_id, data, comparisons)
        end)

      {:ok, scored_data}
    end
  end

  # compare one app to all other apps
  @spec compare(String.t(), map(), map()) :: map()
  defp compare(app_id, data, comparisons) do
    trigram_data = data[app_id]

    # This generates a map for each app, with %{id => score, id => score}
    #  where each key is another app id, and each value is the score for how that app
    # compares to the current app
    scores =
      data
      |> Stream.map(fn {other_app_id, other_trigram_data} ->
        # if existing_score isn't `nil`, the comparison has already been done
        #   but in reverse, but a + b = b + a, so just re-use the score and don't recalculate
        existing_score = get_in(comparisons, [other_app_id, app_id])
        score = existing_score || score_trigrams(trigram_data, other_trigram_data)

        {other_app_id, score}
      end)
      |> Enum.into(%{})

    Map.put(comparisons, app_id, scores)
  end

  @doc """
  Score the similarity of two groups of files, after normalized and "trigramized"
  """
  @spec score_trigrams(Normalizer.t(), Normalizer.t()) :: float()
  def score_trigrams(%Normalizer{} = normalized, %Normalizer{} = other_normalized) do
    total_trigrams = normalized.count + other_normalized.count

    shared_trigrams =
      normalized.trigrams
      |> Stream.map(fn {trigram, count} ->
        if other_normalized.trigrams[trigram] do
          count + other_normalized.trigrams[trigram]
        else
          0
        end
      end)
      |> Enum.sum()

    shared_trigrams / total_trigrams
  end
end
