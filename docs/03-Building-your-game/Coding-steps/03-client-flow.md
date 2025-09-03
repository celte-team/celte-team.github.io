## Typical runtime flow (client)

1. Discover the lobby: demo reads `~/.celte.yaml` and builds a lobby URL.
2. Ask the lobby to connect: POST `/connect` with a JSON body containing the `clientId` key — the lobby returns an object with keys `clusterHost`, `clusterPort` and `SessionId`.
3. Call the runtime API to connect to the cluster and join the session:

```gdscript
# inside a CPeer-derived script (see demo-tek Scenes/Main/c_peer.gd)
func on_connected_to_lobby(responseJSON: Dictionary) -> void:
    var clusterHost = responseJSON["clusterHost"]
    var clusterPort = int(responseJSON["clusterPort"])
    var sessionId = responseJSON["SessionId"]
    print("Client connecting to session " + sessionId)
    Celte.api.ClientConnect(clusterHost, clusterPort, sessionId)
```

4. When the runtime signals a successful Pulsar/cluster connection (demo shows `_on_celte_connection_success`), the client asks the lobby to link it to a server node: POST `/link` — lobby returns quickly or the lobby calls the Master to perform `client/link`.
5. When the Master/lobby accepts the client, your server-mode code (on the target spawner) will receive an accept callback. In demo-tek the server side implements `_on_mode_server_celte_accept_new_client(client_id, spawner_id)` and calls `TeamManager.spawn(client_id, spawner_id)` which in turn uses `CMultiplayerInstantiator.SpawnEntity(...)`.
