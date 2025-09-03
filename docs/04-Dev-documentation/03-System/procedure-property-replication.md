# Replicating properties using Celte

Game objects properties can be replicated over the network, but doing so is a complex task as each property can have a different logic for its replication.
As Celte is not yet tightly integrated in a game engine, changes in properties are currently broadcasted to the topic of the entity container owning the entity only if the property has been registered manually as being replicated.
The user can define callbacks to update the value of properties directly into the engine.


Clients send their inputs to the input channel of the entity container that contains their avatar. All clients can use that input to simulate the client entity. Other entities have to be correctly synchronized for simulation, keeping random values only to the server.
Any discrepency between the simulated values and the real one on the server node can be corrected by doing a rollback to the replicated property when an update is sent to the replication topic of the entity container owning the entity.

## GODOT API (code bindings)

The Godot binding and editor addon expose a scene-driven replication configuration rather than a raw per-property getter/setter registration in editor scripts.

Primary API you'll use from GDScript / the editor plugin:

- `RegisterReplicatedPropertyToConfig(path, property, is_angle, interpolate, interpolationIntervalMs, property_type)` — add a property to the entity's replication config. The `path` is relative to the `CEntity` parent node (empty string for the parent itself). `property_type` should be a Godot variant type (e.g. `TYPE_VECTOR3`).
- `GetReplicationConfig()` / `SetReplicationConfig(config)` — read/write the replication config programmatically.
- The editor addon (Replication Editor) calls `RegisterReplicatedPropertyToConfig` when you add a property in the UI; the configuration is stored on the node as the `replication_config` exported property (so it is saved with the scene).

Example: register a Vector3 property from script using the same binding the addon uses

```gdscript
# path: path to the child node relative to the entity parent (empty string means the parent node itself)
var path = ""
var property = "position"
var is_angle = false
var interpolate = true
var interpolationIntervalMs = 200
var property_type = TYPE_VECTOR3

current.RegisterReplicatedPropertyToConfig(path, property, is_angle, interpolate, interpolationIntervalMs, property_type)
```

Notes about serialization and supported types:
- The runtime serializes a few types with specialized serializers: `VECTOR3`, `VECTOR2`, and `COLOR` are serialized to compact JSON objects. Other types fall back to `JSON::stringify`.
- The editor limits selectable types to common ones: BOOL, INT, STRING, VECTOR2, VECTOR3, COLOR (see the replication editor UI).

Thread-safety reminder:
- The setter/handler that applies network updates runs on the engine main loop (the binding polls updates in `_process`). Even so, the setter is effectively a network-driven callback and may change game state; keep setters lightweight and use `call_deferred` or engine queues when updating scene state.

Interpolation support (rollback smoothing):
- The runtime supports interpolation for properties when `interpolate` is enabled for a replicated property. When enabled the engine will create interpolation data and smoothly lerp from the current value to the rollback target over `interpolationIntervalMs` milliseconds. This is implemented in the native `Interpolate` helpers (see `Interpolate.cpp`).

## Godot addon UI

The Celte Godot addon now provides a small UI to configure replicated properties from the editor, so you don't need to call `RegisterReplicated` manually in code for simple cases.

What the addon does (assumptions):
- It exposes a `Replicated Properties` panel in the Celte plugin or in the `CEntity` inspector.
- Each entry lets you enter the property name and optionally the names of the getter and setter methods (or select them from the scene). When you save the scene the addon persists this configuration in the scene metadata and wires it at runtime by calling `CEntity.RegisterReplicated(...)` for the corresponding entity instance.

How to use the addon (quick steps):
1. Open the scene that contains your `CEntity` node.
2. Select the `CEntity` node and open the `Replicated Properties` panel provided by the Celte addon (look in the inspector or the Celte dock).
3. Click `Add Property` and enter:
   - Name: the replication key (e.g. `pos`).
   - Getter: (optional) the method name that returns a string representing the value (if empty the addon will use the property value as a string).
   - Setter: the method name to call when a network update arrives (the setter will be called with a single String argument).
4. Save the scene. At runtime the plugin will call `RegisterReplicated` for that entity and the configured getter/setter will be used.

Notes and caveats:
- The setter is invoked when an update arrives from the network; it is still not thread-safe. Use `call_deferred`, engine queues, or otherwise forward the update to the main thread in your setter implementation.
- The addon stores the replication configuration in the scene (metadata). If you change the property name or method names, update the scene's config accordingly.
- The addon aims to cover common use-cases. For advanced or dynamic replication rules (computed getters, conditional replication, custom serialization) continue to call `RegisterReplicated` from code.

## Complete example for position replication, very simple interpolation

```c
extends CharacterBody3D

var _rollback_interp_modifier = Vector3(0, 0, 0)
var _rollback_received_timestamp = Time.get_ticks_msec()
var rollabackDt = 200  # ms, time it takes to correct errors from rollback
var _rollback_target_pos = position


# call this in celte initialization of the entity, after OnSpawn has been called
func initReplicatedProps(entity):
	entity.RegisterReplicated("pos",
		func(): return JSON.stringify([position.x, position.y, position.z]), 	# get
		func(p): call_deferred("update_position", p))							# set


func update_position(p: String):
	var arr = JSON.parse_string(p)
	var pos: Vector3 = Vector3(arr[0], arr[1], arr[2])

	_rollback_interp_modifier = (pos - position) / rollabackDt
	_rollback_received_timestamp = Time.get_ticks_msec()
	_rollback_target_pos = pos


func correct_position_from_rollback_data(delta):
	# if we are too far away we snap directly to the rollback position
	if position.distance_to(_rollback_target_pos) > 5.0:
		position = _rollback_target_pos
		print("SNAPPING position to ", _rollback_target_pos)
		return

	var curr_time = Time.get_ticks_msec()
	if (curr_time - _rollback_received_timestamp) > rollabackDt:
		return # we are done with the rollback

	position += _rollback_interp_modifier * delta * 1000 # delta is in seconds

func _physics_process(delta):
	var entity = get_node("CEntity")
	if (entity == null):
		push_error("CEntity is null in physics process")
	if not entity.IsOwnedByCurrentPeer():
		correct_position_from_rollback_data(delta) # correct the position from the last rollback received

    # process input data

    move_and_slide()
```

## Quick recipe: using addon + code together

You can combine the addon configuration with small glue code in the scene when you need an engine-side setter that does extra work. Example:

1. Use the addon to register the replicated key `pos` and set the setter method name to `on_network_pos`.
2. Implement the setter in the same script and forward the actual update to a deferred method that updates engine state:

```gdscript
func on_network_pos(p: String):
    # addon called this method when a network update arrived
    call_deferred("update_position", p)
```
