## Overview

- Clients may request a spawn for themselves (server can accept or deny).
- Server Nodes (SN) may create entities directly for gameplay reasons.
- The Master coordinates which SN will handle a client when a new client joins and may be involved in computing spawn positions.

## C++ (core runtime) — canonical entrypoints

```c++
// Server-side: ask the grape (server-owned map) to spawn an entity at position
void Grape::SpawnEntity(const std::string &payload, float x, float y, float z,
                        const std::string &uuid = "");

// Client-side: request the server to spawn the client's entity. Server may accept or refuse.
void CelteRuntime::RequestSpawn(const std::string &clientId,
                                const std::string &grapeId,
                                const std::string &payload);
```

These runtime hooks are used by the server mesh. The engine-side glue that turns those native spawn events into Godot nodes is `CMultiplayerInstantiator` (documented below).

## Godot: CMultiplayerInstantiator (engine bridge)

`CMultiplayerInstantiator` is a Godot node (native binding) used by the runtime to deterministically place and initialize engine-side entities. It exposes both instance methods used by game code and static helpers invoked by the native runtime.

Key points:
- Instance method `SpawnEntity(namePrefab, clientId, payload)` — call this from game/server code to request an entity be spawned at this instantiator's transform.
- Static helpers `InstantiateEntity(namePrefab, clientId, payload, cmiId)` and `InstantiateFromPayload(ettId, payload)` — used by the native runtime to actually create the node on the main thread. You normally don't call these directly unless you are integrating low-level runtime code.
- Properties: the binding exposes `id` (string) and `ownerStub` (string). `id` registers the instantiator in a registry so the runtime can find it by id; `ownerStub` is used to indicate which server/stub is responsible for local instantiation.
- Ownership: `TakeOwnership(csn)` will set the instantiator as owned by the current stub (server) and writes the owner into Redis KVPs so remote `SpawnEntity` calls route to the correct SN.

Validation rules enforced by the instantiator code:
- The prefab must contain a `CEntity` child node (named `CEntity` in the prefab). The instantiator validates this and logs an error if missing.
- If `clientId` is provided (non-empty), the prefab must also contain a `CClient` node.
- The instantiated entity script must implement an `Init(payload)` method — the instantiator calls this after adding the node to the scene.
- A top-level `CExecutor` (top-level executor) and a `CReplicationGraph` must exist in the running scene; missing pieces produce logged warnings.

Example usage (GDScript)

```gdscript
# Add a CMultiplayerInstantiator to your scene (for example in a spawn point)
var cmi_scene = preload("res://addons/celte/scenes/CMultiplayerInstantiator.tscn")
var cmi = cmi_scene.instantiate()
cmi.id = "spawn_point_1"           # registers in the instantiator registry
cmi.ownerStub = ""                # optional: set to your stub id if you want local ownership
add_child(cmi)

# When server accepts a client, spawn their entity at this instantiator
func spawn_for_client(client_id: String) -> void:
    var payload = {"name": "Player_" + client_id}
    cmi.SpawnEntity("res://prefabs/player.tscn", client_id, payload)

# Notes:
# - If this node's `ownerStub` matches the local stub id, `SpawnEntity` calls local InstantiateEntity and the node is created locally.
# - Otherwise, SpawnEntity looks up the owner in Redis and forwards the spawn request to the owner via a runtime RPC (CallCMIInstantiate).
```

Example (engine/runtime integration) — what the runtime calls

```gdscript
# These are performed by the native runtime when handling a remote spawn.
# The engine-side code path will ultimately call:
CMultiplayerInstantiator.InstantiateEntity(namePrefab, clientId, payload, cmiId)
# or, when reconstructing from a saved/native payload:
CMultiplayerInstantiator.InstantiateFromPayload(ettId, payload)
```

Implementation notes (behavior observed in the binding):
- `InstantiateEntity` defers to `__instantiateEntity` which loads the PackedScene, validates the prefab (CEntity & optional CClient), sets entity payload and id, adds the node to the top-level executor and finalizes initialization by calling the entity's `Init(payload)` method.
- `InstantiateFromPayload` schedules a main-thread task that runs `__instantiatePayload` — this is the path used when the native runtime asks the engine to recreate an entity from a serialized payload.
- `SpawnEntity` checks the instantiator's `_ownerStub`. If the owner is local it calls `InstantiateEntity` directly. If not, it reads the owner from Redis (`GetRedisKVP(_id)`) and issues a `CallCMIInstantiate(owner, _id, namePrefab, payload, clientId)` to the owning server.
- `TakeOwnership` performs checks (server-only, locally owned CSN) and writes the owner id to Redis synchronously.

## Spawn flow (high level)

1. Client connects to lobby/master and receives an SN to connect to.
2. Client connects to assigned SN (Celte.api.ClientConnect).
3. Client may send a `RequestSpawn` or server may call `Grape::SpawnEntity`. The runtime uses `CMultiplayerInstantiator` instances present on the target SN to place the entity.
4. Native runtime or the instantiator finalizes engine-side initialization and registers the entity with the replication graph so it is replicated to interested peers.

## Practical notes and debugging

- Keep the spawn payload small and JSON-serializable — payload travels through Pulsar topics and must be parsed efficiently.
- If instantiation fails, check the engine logs for the following common causes:
  - "No entity found in the prefab. Please add an CEntity node to the prefab." → prefab missing `CEntity` child.
  - "No Init method found in the entity script." → add `func Init(payload):` to your script.
  - "No top level executor found." → ensure a top-level `CExecutor` node is present in the active scene.
- For debugging ownership routing, verify the Redis KVP for the CMI id and ensure the owning stub has network connectivity.

## Diagrams

The project includes `procedure-spawn.drawio.svg` illustrating the spawn sequence. Use it when describing spawn choreography in design docs.
