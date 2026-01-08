[![Hex version](https://img.shields.io/hexpm/v/giocci.svg "Hex version")](https://hex.pm/packages/giocci)
[![API docs](https://img.shields.io/hexpm/v/giocci.svg?label=hexdocs "API docs")](https://hexdocs.pm/giocci)
[![License](https://img.shields.io/hexpm/l/giocci.svg)](https://github.com/b5g-ex/giocci/blob/main/LICENSE)

# Giocci

Client Library for Giocci

## Description

Giocci is a computational resource permeating wide-area distributed platform towards the B5G era.

This repository is a library that provides functionality for the client in Giocci environment.
It should be used with followings which installed onto Giocci server(s).

- [zenod](https://github.com/eclipse-zenoh/zenoh/tree/main/zenohd)
- [giocci_relay](https://github.com/b5g-ex/giocci/tree/main/apps/giocci_relay)
- [giocci_engine](https://github.com/b5g-ex/giocci/tree/main/apps/giocci_engine)

The detailed instructions will be appeared ASAP,,,

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `giocci` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:giocci_client, "~> 0.3.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/giocci>.

## Giocci Communication Flow

This repository communicates over Zenohex (Zenoh) using Query/Reply and Pub/Sub. The sections below summarize the key paths and the main sequences.

### Components

- Client: `apps/giocci_client`
- Relay: `apps/giocci_relay`
- Engine: `apps/giocci_engine`
- Transport: Zenohex (Zenoh) session

### Key Map

- Client registration: `giocci/register/client/{relay_name}`
- Engine registration: `giocci/register/engine/{relay_name}`
- Save module (Client -> Relay): `giocci/save_module/client/{relay_name}`
- Distribute module (Relay -> Engine): `giocci/save_module/relay/{engine_name}`
- Engine inquiry: `giocci/inquiry_engine/client/{relay_name}`
- Sync exec request: `giocci/exec_func/client/{engine_name}`
- Async exec request (Engine subscribes): `giocci/exec_func_async/client/{engine_name}`
- Async exec result (Client subscribes): `giocci/exec_func_async/engine/{client_name}`
- If `key_prefix` is set, it is prepended (e.g., `prefix/giocci/...`).

### Flows

#### 1) Client Registration

```mermaid
sequenceDiagram
  participant Client
  participant Relay
  participant Engine

  Client->>Relay: Query giocci/register/client/{relay}
  Relay->>Relay: register client
  Relay->>Client: Reply :ok
```

#### 2) Engine Registration + Existing Module Distribution

```mermaid
sequenceDiagram
  participant Client
  participant Relay
  participant Engine

  Engine->>Relay: Query giocci/register/engine/{relay}
  Relay->>Relay: fetch existing modules from ModuleStore
  Relay->>Engine: Query giocci/save_module/relay/{engine}
  Engine->>Engine: :code.load_binary
  Engine->>Relay: Reply :ok
  Relay->>Engine: Reply :ok (registration complete)
```

#### 3) Save Module (Client -> Relay -> Engine)

```mermaid
sequenceDiagram
  participant Client
  participant Relay
  participant Engine

  Client->>Relay: Query giocci/save_module/client/{relay}
  Relay->>Relay: validate client + ModuleStore.put
  Relay->>Engine: Query giocci/save_module/relay/{engine}
  Engine->>Engine: :code.load_binary
  Engine->>Relay: Reply :ok
  Relay->>Client: Reply :ok
```

#### 4) Sync Execution (Client -> Relay -> Engine -> Client)

```mermaid
sequenceDiagram
  participant Client
  participant Relay
  participant Engine

  Client->>Relay: Query giocci/inquiry_engine/client/{relay}
  Relay->>Relay: select engine
  Relay->>Client: Reply {engine_name}

  Client->>Engine: Query giocci/exec_func/client/{engine}
  Engine->>Engine: validate module + exec
  Engine->>Client: Reply result
```

#### 5) Async Execution (Client -> Relay -> Engine -> Client)

```mermaid
sequenceDiagram
  participant Client
  participant Relay
  participant Engine

  Client->>Relay: Query giocci/inquiry_engine/client/{relay}
  Relay->>Relay: select engine
  Relay->>Client: Reply {engine_name}

  Client->>Engine: Put giocci/exec_func_async/client/{engine}
  Engine->>Engine: exec and build result
  Engine->>Client: Put giocci/exec_func_async/engine/{client}
  Client->>Client: send {:giocci_client, result}
```

### Notes

- Client <-> Relay uses Query/Reply; Engine uses Queryable for sync and Subscriber/Publisher for async.
- All communication is via Zenohex key space; `key_prefix` may be prepended.
- Engine selection is currently first-registered in `GiocciRelay.EngineRegistrar.select_engine/0`.

