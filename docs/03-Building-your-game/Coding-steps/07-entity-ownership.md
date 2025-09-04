## Entity & ownership

- Entities typically expose a `CEntity` child. Use `entity.IsOwnedByCurrentPeer()` to check authority and `$Stub.ProxyTakeAuthority(entity)` to request proxy/authority on a node from a client.
- Initialization payload: the server can send an initialization payload (JSON string) when spawning a player/entity. Demo uses `_on_mode_server_received_initialization_payload(payload)` to parse initialization parameters.
