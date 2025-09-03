## Typical runtime flow (server node)

1. Server node is started with `CELTE_MODE=server`. The demo server calls `Celte.api.ServerNodeConnect()` to register with the Master/cluster.
2. The server node registers spawn points (see `Singletons/team_manager.gd` in the demo) using `CMultiplayerInstantiator` instances.
3. When a client is accepted, the server receives a callback (a Celte-provided signal) and calls `SpawnEntity` to instantiate the player and provide the initialization payload back to the client.
