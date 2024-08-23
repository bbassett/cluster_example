defmodule ClusterTest do
  use ExUnit.Case
  doctest Cluster

  test "two copies of the same app get clustered when threshold is 1" do
    filepath = "./test/fixtures/two_copies.json"

    assert Cluster.cluster_apps(filepath, 1) == {:ok, [["ID1", "ID2"]]}
  end

  test "two really close apps get clustered when threshold is 0.99" do
    filepath = "./test/fixtures/really_close.json"

    assert Cluster.cluster_apps(filepath, 0.99) == {:ok, [["ID1", "ID2"]]}
  end

  test "a single item returns correctly regardless of threshold" do
    filepath = "./test/fixtures/single_app.json"

    assert Cluster.cluster_apps(filepath, 0.99) == {:ok, [["ID1"]]}
  end

  test "no files returns an error" do
    filepath = "./test/fixtures/no_files.json"

    assert Cluster.cluster_apps(filepath, 0.99) == {:error, "Encountered an app without files"}
  end

  test "no unfiltered files returns an error" do
    filepath = "./test/fixtures/no_unfiltered_files.json"

    assert Cluster.cluster_apps(filepath, 0.99) == {:error, "Encountered an app without files"}
  end

  # the following two are disabled because they take a long time to run
  # you can test via `mix test --include disabled`
  @tag :disabled
  test "big example returns 38 groups when threshold is 0.8" do
    filepath = "./test/fixtures/big_example.json"
    {:ok, result} = Cluster.cluster_apps(filepath, 0.8)

    assert Enum.count(result) == 38
  end

  @tag :disabled
  test "big example returns 19 groups when threshold is 0.7" do
    filepath = "./test/fixtures/big_example.json"
    {:ok, result} = Cluster.cluster_apps(filepath, 0.7)

    assert Enum.count(result) == 19
  end
end
