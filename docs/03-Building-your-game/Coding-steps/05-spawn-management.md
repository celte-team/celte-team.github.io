## Spawn management (TeamManager example)


Use `CMultiplayerInstantiator` for deterministic spawning and to pass an initialization payload to the client.
The `CMultiplayerInstantiator` node automatically detects which server hosts the spawn point and ensures that the object will be spawned on the correct server.

```gdscript
# spawn an entity for a client
$CMI.SpawnEntity("res://player/player.tscn", client_id, {"test": "hello blue"})
```

Note that a custom payload can be passed to the networked entity when spawning it. This payload is sent to the client and can be used to initialize the entity on all peers connected to the server.
The entity will spawn at the location of the `CMultiplayerInstantiator` node.