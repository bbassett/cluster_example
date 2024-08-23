# Cluster

Determine if an application is likely to match other applications (as a group) based on similar file structure

## Getting Started

```elixir
git clone https://github.com/bbassett/cluster.git
cd cluster
mix deps.get
iex -S mix
```

## Usage
```elixir
iex(1)> threshold = 0.8
0.8
iex(2)> Cluster.cluster_apps("./path/to/file.json", threshold)
{:ok,
 [
   ["ID1", "ID2"],
   ["ID3", "ID4"],
 ]}
```

## Testing

#### basic tests
```bash
mix test
```

#### all tests, including example file (takes ~20s)
```bash
mix test --include disabled
```


