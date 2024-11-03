
# Hooks in Godot: how to add a hook in Godot

Be careful with hooks, some rules are especially for client or server.
You need to define and set it inside the good `#ifdef` in the `CAPI.cpp` and `CAPI.h` files.

## CAPI.cpp: first step

In the CAPI.cpp file, we define the hooks that we want to use in Godot. We define the hooks as functions that we can call from the Godot script. We can define the hooks as follows:

```cpp
void CAPI::SetHookServerGrapeLoadGrape(Callable call) {
  auto &runtime = celte::runtime::CelteRuntime::GetInstance();
  runtime.Hooks().server.grape.loadGrape =
      std::function<bool(std::string, bool)>(
          [call](std::string grapeId, bool isLocal) {
            if (call.is_valid()) {
              Array args;
              args.append(String(grapeId.c_str()));
              args.append(isLocal);
              call.callv(args);
            }
            return true;
          });
}
```

This function will set the hook `ServerGrapeLoadGrape` to the function `call`. The return value must be set here:

    ```cpp
std::function<bool
```
And the types of arguments must be set here:

    ```cpp
    (std::string, bool)
```
And the arguments must be passed to the function `call` as follows:

    ```cpp
    [call](std::string grapeId, bool isLocal) {
            if (call.is_valid()) {
              Array args;
              args.append(String(grapeId.c_str()));
              args.append(isLocal);
              call.callv(args);
            }
            return true;
          });
```

## CAPI.cpp: second step

You need put the hook function inside the function `CAPI::_bind_methods()` for using it in Godot.

```cpp
ClassDB::bind_method(D_METHOD("SetHookClientGrapeLoadGrape", "call"),
                       &CAPI::SetHookClientGrapeLoadGrape);
```

## CAPI.h

In the CAPI.h file, we define the hooks that we want to use in Godot. We define the hooks as functions that we can call from the Godot script. We can define the hooks as follows:

```cpp
void SetHookServerConnectionOnConnectionSuccess(Callable call);
```

This function will set the hook `ServerConnectionOnConnectionSuccess` to the function `call`. The name of the function must be the path of the hook we want to call.
```cpp
void SetHookServerConnectionOnConnectionSuccess(Callable call);

Hooks().server.connection.onConnectionSuccess
```