# Loading the API

Celte is designed to run with a backed that is engine agnostic. Some engines, such as Godot, do not have a good solution for handling conditional compilation. In godot, even if it is possible to create two binaries when exporting the game, this process is cumbersome and cannot really be used during developement because it is impossible to specify target features in the editor (thus making it impossible to test a server and a client in editor mode).

To accelerate development, Celte's backend (called *Celte Systems*) is loaded by and engine specific API as a dynamic library.

## Setup

Servers must run with a specific environment for the API to load the server bindings. To enable server mode, export the **`CELTE_MODE`** variable with the `server` value.

<details open>
  <summary>Windows</summary>

  ```batch
  set CELTE_MODE=server
  ```
</details>

 <details>
 <summary>Linux</summary>

   ```batch
  set CELTE_MODE=server
  ```

</details>

<details>
<summary>MacOS</summary>

```batch
  export CELTE_MODE=server
```
</details>


If the **`CELTE_MODE`** variable is not set or if its value is not set to `server`, the API will launch in client mode.

## Loading the bindings

The bindings are automatically loaded when the `CelteSingleton.gd` is loaded into the engine. It is recommended to set it as a singleton using Godot's autoload system. During the rest of this tutorial, we will refer to this singleton as `Celte` in the code.

# Connecting to the server

## Before connecting
### Prepare the cluster
Before attempting a connection to the servers, make sure that both the pulsar cluster and the redis cluster are up and running.

### Prepare the hooks
Celte manages the top level logic of the networking, but most actions require to be adapted to your game. To let you customize every aspect of what appens, Celte provides you with a list of hooks that will be called automatically at key points in the program's execution. Before attempting a connection to the server, make sure that all hooks have been set.

```python
	Celte.api.SetOnConnectionFailedHook(onConnectionFailed)
	Celte.api.SetOnConnectionSuccessHook(onConnectionSuccess)
	# functions meant that interact with the node tree should be called in a thread safe way
	Celte.api.SetOnLoadGrapeHook(func(gid, lowned): call_deferred("onLoadGrape", gid, lowned))
	Celte.api.SetOnInstantiateEntityHook(func(e, p): call_deferred("onInstantiateEntity", e, p))

	if Celte.server_mode:
		Celte.api.SetOnGetClientInitialGrapeHook(onGetClientInitialGrapeHook)
		Celte.api.SetOnAcceptNewClientHook(func(c): call_deferred("onAcceptNewClient", c))

```
**Note:** All the available hooks are not used in this example for the sake of conciseness. Please refer to the in engine documentation of the API to see all of the available hooks.

## Connect

You can connect to the cluster using the same method for your servers and your clients:

```python
	Celte.api.ConnectToClusterWithAddress("localhost", 6650)
```

Or, if you have the cluster ip set in the environment (useful for servers):

```python
	Celte.api.ConnectToCluster()
```

If the connection timesout or fail, the `onConnectionFailed` hook will be called.