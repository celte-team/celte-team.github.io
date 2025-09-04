## Troubleshooting

- If you see errors like "API is not valid" in logs, confirm the gdextension is present and that `CAPI.new()` works in `addons/celte/CelteSingleton.gd`.
- If lobby calls fail, check `~/.celte.yaml` and the `CELTE_LOBBY_HOST` value; the demo reads this file to build the lobby URL.
- For spawn/replication issues, enable debug draws (demo uses `DebugDraw3D`) and verify containers are created and assigned.

Next steps & suggestions
- Add small ready-to-run snippets for common tasks (connect to lobby, spawn player, request authority). I can add them as separate short files in `docs/examples/` if you'd like.
- Create a small test harness scene that performs a lobby flow end-to-end against the local `celte-godot/projects/lobby-server` example.

Small troubleshooting snippets (GDScript)

1) Check gdextension and CAPI handle

```gdscript
# run this in a script attached to a node to sanity check the native binding
func check_celte():
	if not Engine.has_singleton("Celte"): # demo exposes Celte singleton
		push_error("Celte singleton not found; make sure the gdextension is loaded")
		return
	var ok = Celte.api.IsValid()
	if not ok:
		push_error("Celte API handle is not valid; check the gdextension and init order")
	else:
		print("Celte binding OK")


```

2) Read `~/.celte.yaml` (demo pattern)

```gdscript
func load_lobby_host_from_yaml() -> String:
	var yaml_path = OS.get_environment("HOME") + "/.celte.yaml"
	var file = FileAccess.open(yaml_path, FileAccess.READ)
	if file == null:
		push_error("YAML config not found at: " + yaml_path)
		return ""
	var in_block = false
	var host = ""
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.begins_with("celte:"):
			in_block = true
		elif in_block and line.find("CELTE_LOBBY_HOST:") != -1:
			host = line.get_slice(":", 1).strip_edges()
			break
	file.close()
	return host


```

3) Connect to lobby and then to cluster (demo pattern)

```gdscript
func connect_to_lobby_and_cluster(lobby_url: String):
	Celte.api.SendHttpRequest(lobby_url + "/connect", {"clientId": Celte.api.GetUUID()},
		func(response: Dictionary):
			# response contains clusterHost, clusterPort, SessionId
			Celte.api.ClientConnect(response["clusterHost"], int(response["clusterPort"]), response["SessionId"])
		,
		func(err, msg):
			push_error("Failed to connect to lobby: " + str(err) + " " + str(msg))
	)


```

4) Spawn a player on server accept (demo pattern)

```gdscript
# If you want to spawn directly from a CMultiplayerInstantiator:
func spawn_from_instantiator(inst: CMultiplayerInstantiator, client_id: String):
	inst.SpawnEntity("res://player/player.tscn", client_id, {"test": "meta"})


```

5) Handle client disconnect payload (safe parsing)

```gdscript
func _on_celte_client_disconnect(client_id: String, payload: Dictionary) -> void:
	# payload may be empty or have unexpected keys; guard access
	if payload == null:
		print("Client disconnected", client_id, "(no payload)")
		return
	# access safely
	var reason = payload.has("reason") ? payload["reason"] : "unknown"
	print("Client", client_id, "disconnected; reason:", reason)


```
