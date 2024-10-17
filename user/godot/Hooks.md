
# Hooks: how to set a hook with a custom function

## _ready()

In the function _ready() of the script, we can set the hook with the function we want to use. We can set the hook as follows:

```gdscript
		CELTE.api.SetHookServerConnectionOnSpawnPositionRequest(onSpawnPositionReq)
```

Be careful to check if the hook is for the client or the server. You need to set the hook in the right place.
```gdscript
        if OS.has_feature("server"):
```

## Your custom function

You can define your custom function as follows:

```gdscript
func onSpawnPositionReq(clientId):
	var spawn_location_name = "leChateauDuMechant"
	var x = 2.0
	var y = 1.0
	var z = 0.0
	return [spawn_location_name, clientId, x, y, z]
```

The function must return what the hook expects and take as parameters what the hook expects. In this case, the hook expects a clientId and returns an array with the spawn location name, the clientId, and the x, y, z coordinates.