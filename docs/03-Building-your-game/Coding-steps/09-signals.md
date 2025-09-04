## Signal and callback conventions (examples in demo)
### Overview

The Celte native runtime (the CPeer Godot binding) exposes a set of Godot signals that mirror the native HookTable callbacks. Game code (GDScript, C#, etc.) should connect to those signals to run game-specific logic at key lifecycle moments (connection, grape loading, client lifecycle, server-only events).

Important implementation notes
- Signals are registered in `CPeer::_bind_methods()` and are emitted from `CPeer` using `call_deferred("emit_signal", ...)`. That means handlers will run safely on the Godot main/thread loop and after the current call completes.
- Some signals provide parsed data: e.g. the client-disconnect payload is parsed from JSON into a Godot Dictionary before being emitted.
- Server-only signals are only set up when the runtime is running in server mode (see `CAPI::GetHandle()._mode_server`).

### Signals (name, params, when emitted, native hook mapping)

- `ready_user_callback()`
  - Params: none
  - Emitted: from `CPeer::_ready()` as soon as the CPeer node is ready. Use this to attach your signal handlers if you prefer wiring at runtime.
  - HookTable mapping: N/A (internal helper)

- `celte_connection_success()`
  - Params: none
  - Emitted: when the native runtime successfully connects to the Pulsar cluster.
  - Native HookTable: `onConnectionSuccess`

- `celte_connection_failed()`
  - Params: none
  - Emitted: when the native runtime fails to connect to the Pulsar cluster.
  - Native HookTable: `onConnectionFailed`

- `celte_client_disconnect(client_id: String, payload: Dictionary)`
  - Params: `client_id` (String), `payload` (Dictionary)
  - Emitted: when a client disconnects from the cluster. The native hook supplies a JSON payload (string); `CPeer` parses that JSON into a Godot `Dictionary` before emitting the signal.
  - Native HookTable: `onClientDisconnect` (C++ signature: `std::function<void(const std::string &, const std::string &)>`)
  - Note: handlers should tolerate missing keys or unexpected payload shapes since parsing may produce different results depending on the payload.

- `celte_load_grape(grape_id: String, locally_owned: bool)`
  - Params: `grape_id` (String), `locally_owned` (bool)
  - Emitted: when the runtime tells the engine to load a grape (map/scene). Use this to instantiate maps, load scenes, or spawn grape-specific objects.
  - Native HookTable: `onLoadGrape` (`std::function<void(const std::string &, bool)>`)

Server-only signals (only present when running in server mode)

- `mode_server_received_initialization_payload(payload: String)`
  - Params: `payload` (String)
  - Emitted: when the server sends an initialization payload for a newly attached client/entity.
  - Native HookTable: `onServerReceivedInitializationPayload` (`std::function<void(const std::string &)>`)

- `mode_server_celte_accept_new_client(client_id: String, spawner_id: String)`
  - Params: `client_id` (String), `spawner_id` (String)
  - Emitted: when the server accepts a new client. The game should use this to create the player's entity, associate it with a spawner/grape, or send initialization info.
  - Native HookTable: `onAcceptNewClient` (`std::function<void(const std::string &, const std::string &)>`)
  - Note: despite the `ADD_SIGNAL` registration listing only `client_id`, the emitted event includes both `client_id` and `spawner_id`. Connect handlers expecting both arguments.

- `mode_server_celte_client_request_disconnect(client_id: String)`
  - Params: `client_id` (String)
  - Emitted: when a connected client requested to disconnect (intent to leave gracefully).
  - Native HookTable: `onClientRequestDisconnect` (`std::function<void(const std::string &)>`)

- `mode_server_celte_client_not_seen(client_id: String)`
  - Params: `client_id` (String)
  - Emitted: when the server determines a client was not seen for a while (timeout / lost connection semantics).
  - Native HookTable: `onClientNotSeen` (`std::function<void(const std::string &)>`)

Mapping to native HookTable

The Godot signals map directly to the members of `celte::HookTable` (see `system/include/HookTable.hpp`). When the native runtime triggers a HookTable callback, `CPeer` forwards that to Godot by emitting the corresponding signal. This lets game code remain purely Godot-side (GDScript/C#) while the native code keeps the core networking logic.

Usage examples (GDScript)

Connect in the editor or at runtime. Example connecting at runtime in a Node that owns the CPeer node:

```gdscript
# Use Godot's UI to connect signals

func _on_celte_connection_success():
    print("Connected to Celte cluster")

func _on_celte_connection_failed():
    print("Celte connection failed")

func _on_celte_client_disconnect(client_id: String, payload: Dictionary):
    print("Client disconnected:", client_id, payload)

func _on_celte_load_grape(grape_id: String, locally_owned: bool):
    # load the scene or grape stub associated with grape_id
    print("Load grape", grape_id, "locally_owned:", locally_owned)

func _on_mode_server_celte_accept_new_client(client_id: String, spawner_id: String):
    # server: create player's entity and bind client_id -> entity
    pass

func _on_mode_server_received_initialization_payload(payload: String):
    # client: use the payload to configure the player's entity on attach
    pass
```
