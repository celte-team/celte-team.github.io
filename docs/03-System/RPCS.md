# Remote procedure calls

Peers on the network can remotely call methods on other peers, either by specifically targeting them or by invoking the method over the scope of an entity container, grape, or even the global scope.

## Using RPCs in `c++`
### Setup
Set up a `route` for the current peer to listen RPCs on:

```c++
  auto service = celte::net::RPCService(celte::net::RPCService::Options{
      .thisPeerUuid = RUNTIME.GetUUID(),
      .listenOn = "pulsar://persistent/default/route/to/listen/to",
      .responseTopic = RUNTIME.GetUUID() + "." + tp::RPCs,
      .serviceName = "demo_rpcs",
  });
```

- `thisPeerUuid` is used to trace the call to its original owner
- `listenOn` remote peers can call for this service to execute RPCs on this apache pulsar topic
- `responseTopic` is the pulsar topic onto which return values will be sent when this service invokes a remote method.
- `serviceName` is used by pulsar for partitioning.

### Registering RPC Methods
You can register RPC methods that can be called remotely. The Register method allows you to register functions with different signatures.

### Registering a Function with Arguments

```c++
service.Register<int, int, int>("add", [](int a, int b) {
    return a + b;
});
```

### Registering a Function without Arguments

```c++
service.Register<void>("sayHello", []() {
    std::cout << "Hello, world!" << std::endl;
});
```

### Calling RPC Methods
You can call registered RPC methods on remote peers using the Call method. The Call method sends a request to the specified topic and waits for a response.

```c++
try {
    int result = service.Call<int>("pulsar://persistent/default/route/to/call", "add", 5, 3);
    std::cout << "Result: " << result << std::endl;
} catch (const celte::net::RPCTimeoutException &e) {
    std::cerr << "RPC call timed out: " << e.what() << std::endl;
}
```
Note that the `Call` method is blocking. If you wish to wait for the return value asynchronously, use `CallAsync`:

```c++
service.CallAsync<int>("pulsar://persistent/default/route/to/call", "add", 5, 3)
    .Then([](int result) {
        std::cout << "Result: " << result << std::endl;
    })
```

Alternatively, if the called function does not return any value or you do not wish to use the return value, use `CallVoid` to fire and forget (non-blocking call).

```c++
service.CallVoid<int>("pulsar://persistent/default/route/to/call", "sayHello");
```