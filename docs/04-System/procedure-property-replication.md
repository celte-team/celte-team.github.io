# Replicating properties using Celte

Game objects properties can be replicated over the network, but doing so is a complex task as each property can have a different logic for its replication.
As Celte is not yet tightly integrated in a game engine, changes in properties are currently broadcasted to the topic of the entity container owning the entity only if the property has been registered manually as being replicated.
The user can define callbacks to update the value of properties directly into the engine.


Clients send their inputs to the input channel of the entity container that contains their avatar. All clients can use that input to simulate the client entity. Other entities have to be correctly synchronized for simulation, keeping random values only to the server.
Any discrepency between the simulated values and the real one on the server node can be corrected by doing a rollback to the replicated property when an update is sent to the replication topic of the entity container owning the entity.

## GODOT API

```c
func initReplicatedProps(entity: CEntity):
	entity.RegisterReplicated("pos",
		func(): return JSON.stringify([position.x, position.y, position.z]), 	# get
		func(p): call_deferred("update_position", p))							# set
```
Some important considerations:
- since the setter is called whenever there is an update received from the network, this call **is not thread safe** and the user should take all the necessary precautions (using call_deferred for example).
- the format of the value does not matter as long as it is returned as a string (which may be binary data or not).
- Celte does not yet provide a way to automatically interpolate values to smooth the transition when the client rollbacks. This might come in the future.

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
