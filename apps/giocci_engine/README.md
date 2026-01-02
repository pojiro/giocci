# GiocciEngine

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `giocci_engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:giocci_engine, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/giocci_engine>.

## How to build/push docker image

```bash
docker compose build giocci_engine
docker compose push giocci_engine
```

## How to run docker container

```bash
docker compose run --rm giocci_engine
```
