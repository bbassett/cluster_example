import Config

config :rl,
  "{lib,config}/**/*.{ex,exs}": Rl.Watcher.CompileFormat,
  "mix.exs": Rl.Watcher.Compile,
  "test/**/*.exs": "mix test --stale --color",
  "{lib,config,test}/**/*.*": Rl.Watcher.Nothing
