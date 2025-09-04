# Remote procedure calls (CRPC)

The project now uses the CRPC framework for remote procedure calls. CRPC provides a high-level builder (`CRPCBuilder`) and generated wrappers to declare, call, and subscribe to RPCs with built-in timeout, retry and failure policies.

Key components
- `RPCCallerStub`: low-level caller that sends requests and receives responses. Used internally by the builder and can also be called directly.
- `RPCCalleeStub`: low-level callee registry; it manages subscribing to Pulsar scopes and dispatching incoming RPC requests to local handlers.
- `CRPCBuilder<SomeCall>`: a typed builder for a specific remote method. The project exposes convenience macros that generate `SomeCall` types.
- Macros: `REGISTER_RPC`, `REGISTER_SERVER_RPC`, `REGISTER_CLIENT_RPC`, and `REGISTER_RPC_REACTOR` generate call wrappers and reactor helpers.

Basic usage (recommended)

1) Declare an RPC on a class (server or client depending on build flags)

```c++
// in your header or cpp (global scope)
REGISTER_RPC(MyGrape, compute_spawn_position)

// Now `CallMyGrapecompute_spawn_position` is generated.
```

2) On the caller side use the generated call wrapper with options

```c++
CallMyGrapecompute_spawn_position::Options opts;
opts.timeout = std::chrono::milliseconds(1500);
opts.retry = 1; // retry once on failure
opts.fail_callback = [](celte::CStatus &s) { /* handle failure */ };

CallMyGrapecompute_spawn_position call(opts);
auto maybePos = call.call_on_peer<std::tuple<float,float,float>>("peer-uuid", /* args... */);
if (maybePos.has_value()) {
    auto pos = maybePos.value();
    // use pos
} else {
    // call failed (timeout, remote error, or retries exhausted)
}
```

3) Asynchronous call

```c++
call.call_async_on_peer<std::tuple<float,float,float>>("peer-uuid", [](auto pos){
    // pos is the return value
});
```

4) Fire-and-forget

```c++
call.fire_and_forget_on_peer("peer-uuid", /* args... */);
// or broadcast to a scope
call.fire_and_forget_on_scope("grape-uuid", /* args... */);
```

Alternative: explicit registration of callee methods

If you prefer not to use macros, you can register handlers directly with `RPCCalleeStub`:

```c++
// register a member method as a handler for scope "grape-uuid"
MyClass instance;
RPCCalleeStub::instance().register_method(&instance, "grape-uuid", "method_name", &MyClass::method_name);

// the method will receive arguments as typed values and should return a JSON-serializable type
```

Subscribe / Reactors

The `REGISTER_RPC_REACTOR` / `REGISTER_RPC` macros generate a Reactor helper with `subscribe(topic, instance)` and `unsubscribe(topic)` convenience methods. Use these to subscribe an object to incoming RPCs on a topic.

Failure handling, timeouts and retries

The CRPC builder exposes a small policy DSL (fluent API):
- `on_fail_do(callback)` — run a callback when the call ultimately fails.
- `on_fail_log_error()` — default logging handler.
- `on_fail_ignore()` — ignore failures.
- `on_fail_throw()` — rethrow the exception (use carefully with async calls).
- `with_timeout(ms)` — specify timeout per call.
- `retry(n)` — number of retries before failing.

Example fluent usage (manual builder):

```c++
// Manually using the builder (advanced)
auto result = CallSomeThing().on_peer("peer").on_fail_do(cb).with_timeout(std::chrono::milliseconds(1000)).retry(2).call<ReturnType>(args...);
```

Low-level API

If you need lower-level control you can call `RPCCallerStub::instance().fire_and_forget(scope, name, args...)` or `RPCCallerStub::instance().call(scope, name, rpc_id, args...)` (the latter returns a variant containing an exception or a future to the JSON response). Prefer the generated wrappers where possible — they handle serialization/deserialization and policies.

Exceptions and errors

- `celte::CRPCTimeoutException` is thrown/reported when a call times out.
- Callers will typically receive `std::optional<T>` (empty on failure) or have the failure delivered to the configured fail handler.

Best practices

- Use generated call wrappers (REGISTER_RPC) — they ensure consistent naming and TypeIdentifier wiring across the codebase.
- Keep RPC arguments and return values JSON-serializable and small (they travel over Pulsar topics).
- Use timeouts and sensible retry counts for network calls.
- Log failures with `on_fail_log_error()` in production; for noisy or optional calls consider `on_fail_ignore()`.

Examples

Register and subscribe (server side):

```c++
REGISTER_RPC(MyGrape, compute_spawn_position)

// At runtime, subscribe each grape instance to its topic
MyGrape grape;
CallMyGrapecompute_spawn_positionReactor::subscribe("grape-uuid", &grape);
```

Call from a client to a grape instance:

```c++
CallMyGrapecompute_spawn_position::Options opts;
opts.timeout = std::chrono::milliseconds(1000);
CallMyGrapecompute_spawn_position call(opts);
auto pos = call.call_on_peer<std::tuple<float,float,float>>("grape-uuid");
```

That's the gist of the CRPC framework — it replaces the older RPCService model and centralizes timeout/retry/failure policies in a typed, generated API.

## Real code examples from the codebase

Below are short, real excerpts copied from the repository showing how the generated CRPC wrappers and reactors are used in practice.

- Grape: reactor subscription and fetching existing containers (excerpt from `system/common_src/Grape.cpp`)

```c++
// reactors are subscribed during grape initialization
GrapeRPCHandlerReactor::subscribe(tp::rpc(id), this);

// fetching existing containers using a generated call wrapper
std::vector<std::string> existingContainers =
    CallGrapeGetExistingOwnedContainers()
        .on_peer(id)
        .on_fail_log_error()
        .with_timeout(std::chrono::milliseconds(1000))
        .retry(3)
        .call<std::vector<std::string>>(id)
        .value_or(std::vector<std::string>{});
```

- PeerService: force-connect and async call (excerpt from `system/common_src/PeerService.cpp`)

```c++
// synchronous call returning a bool (with timeout/retry)
bool ok = CallPeerServiceForceConnectToNode()
              .on_peer(clientId)
              .on_fail_log_error()
              .with_timeout(std::chrono::milliseconds(1000))
              .retry(3)
              .call<bool>(RUNTIME.GetAssignedGrape())
              .value_or(false);

// asynchronous call with callback
CallPeerServiceSubscribeClientToContainer()
    .on_peer(clientId)
    .on_fail_log_error()
    .with_timeout(std::chrono::milliseconds(1000))
    .retry(3)
    .call_async<bool>([then, containerId, clientId](bool ok) {
        if (ok) { then(); }
    }, containerId, RUNTIME.GetAssignedGrape());
```

- AuthorityTransfer: fire-and-forget example (excerpt from `system/common_src/AuthorityTransfer.cpp`)

```c++
CallContainerTakeAuthority()
    .on_scope(args["t"].get<std::string>())
    .on_fail_do([](CStatus &status) { /* handle error */ })
    .fire_and_forget(args.dump());
```

- GrapeRegistry: propagate container subscription to remote grape (excerpt from `system/common_src/GrapeRegistry.cpp`)

```c++
CallGrapeSubscribeToContainer()
    .on_peer(grapeId)
    .on_fail_log_error()
    .with_timeout(std::chrono::milliseconds(1000))
    .retry(3)
    .call<bool>(ownerOfContainerId, containerId);
```

These snippets show the common patterns you will find across the codebase:
- generated call wrappers named with the `Call<Class><Method>` prefix,
- fluent policy configuration (.on_peer/.on_scope, .with_timeout, .retry, .on_fail_*),
- synchronous `.call<T>()`, asynchronous `.call_async<T>(callback, ...)`, and fire-and-forget `.fire_and_forget(...)`, and
- reactor subscription helpers `...Reactor::subscribe(topic, instance)` for incoming handlers.
