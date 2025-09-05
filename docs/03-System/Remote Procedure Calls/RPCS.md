# Remote Procedure Calls

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

## Use Case of Customs RPCs

### What's a Custom RPCs

The goal of a custom rpc is to let the possibility to the Godot developer to execute his own RPC and logic.
It's a modular RPC that re-use the system documented previously and adapt it to execute any code in different context (client, server or global)

### Implementation inside the `C++`

#### Custom RPC Template Class

Like you can see this class is the core of the Custom RPC system.
It's a simple class with
    - a ***map*** of function
    - a methode to Register a function inside the map
    - a methode to execute a function from the map with specific arguments

This class will be used by all the context (Global, client and server)

```C++
    class CustomRPCTemplate {

    protected:
        std::map<std::string, std::function<void(std::string)>> _rpcs;

    public:
        void RegisterRPC(const std::string& name, std::function<void(std::string)> func)
        {
            if (_rpcs.find(name) != _rpcs.end())
                // Error handling

            _rpcs[name] = func;
        }

        inline void Handler(std::string RPCname, std::string args, std::string id)
        {

            if (_rpcs.find(RPCname) != _rpcs.end())
                _rpcs[RPCname](args);
            else
            // Error handling
        }
    };
```

#### Global RPC

This RPC will reach everyone, server and client without exception.
There is a filter system in the export that permit to only call the servers or clients.

Like you can see he heritate from *CustomRPCTemplate* and wrap the Custom handler into his own to give him the right context

* @param *tp::global_rpc()* : It's here to tell on wich topic listening the call
* @param *this* : He's here to give the current context to the subscriber

```C++
// In the .cpp
Global::Global()
{
    GlobalRPCHandlerReactor::subscribe(tp::global_rpc(), this);
}

// In the Include
class Global : public CustomRPCTemplate {
public:
  Global();
  void RPCHandler(std::string RPCname, std::string args) {
    Handler(RPCname, args, tp::global_rpc());
  }
};

REGISTER_RPC(Global, RPCHandler)
```

#### Entity RPC

This RPC will be only executed by a specific entity and only if the call is from his owner server.

There is a filter system in the export that provide any server to register the RPC, it can also during the call specify if this rpc is only executed by the entity or this entity in all the instance of the game (if it's applied to all player or only the concerned player).

```C++
// ETTRegistry.cpp
// The server mode subscribe to both peer service and rpc
// If you send the call to only the server instance (peer) of the entity 
// Or to all the instance of the entity (rpc) he will be triggered
// The others (the rest of the client and non owner server) only sub to the RPC

void Entity::initRPCService() 
{
#ifdef CELTE_SERVER_MODE_ENABLED
  if (ContainerRegistry::GetInstance().ContainerIsLocallyOwned(
          ownerContainerId))
    EntityRPCHandlerReactor::subscribe(tp::peer(id), this);

#endif
  EntityRPCHandlerReactor::subscribe(tp::rpc(id), this);
}


// Entity.hpp
struct Entity : public CustomRPCTemplate {

    void RPCHandler(std::string RPCname, std::string args)
    {
        Handler(RPCname, args, id);
    }
};

REGISTER_RPC(Entity, RPCHandler)

```

#### Peer RPC

Similar to the Entity RPC but it only concern Client instead of any Entity

```C++
// PeerService.hpp

// if this function is called by a client, he register it as a peer
// if this function is called by a server he register to the rpc
// this way only the client execute the call OR only the servers execute it

void PeerService::__initPeerRPCs()
{

#ifdef CELTE_SERVER_MODE_ENABLED
    PeerServiceRPCHandlerReactor::subscribe(tp::rpc(id), this);
#else
    PeerServiceRPCHandlerReactor::subscribe(tp::peer(id), this);
}


// PeerService.hpp
class PeerService : public CustomRPCTemplate {

  void RPCHandler(std::string RPCname, std::string args) 
  {
    Handler(RPCname, args, tp::peer(RUNTIME.GetUUID()));
  }

}
REGISTER_RPC(PeerService, RPCHandler);
```

#### Grape RPC

This RPC will be executed by all the client/server sub to his topic or only executed by the specified server.

```C++
// Grapes.cpp
void Grape::initRPCService()
{
#ifdef CELTE_SERVER_MODE_ENABLED

if (isLocallyOwned) {
    GrapeRPCHandlerReactor::subscribe(tp::peer(id), this);
}

#endif
GrapeRPCHandlerReactor::subscribe(tp::rpc(id), this);
}

// Grapes.hpp
struct Grape : public CustomRPCTemplate {
    void RPCHandler(std::string RPCname, std::string args)
    {
        Handler(RPCname, args, id);
    }
}
REGISTER_RPC(Grape, RPCHandler);
```

### Exportation to The Godot API

A part of the security is handled during the export in the Call binding.

It's also here that is determined wich scope will be used (peer or rpc)

#### RegisterRPC Export

The filter is an argument that specify who will register (and by extension execute) the RPC

The only exception is the ClientRPC who only concern client...

* 0 = everyone
* 1 = only the servers
* 2 = only the clients

```C++
EXPORT void RegisterGlobalRPC(const std::string &name, int filter,
                              std::function<void(std::string)> f) {

  if (filter == 0)
    RUNTIME.GetPeerService().GetGlobalRPC().RegisterRPC(name, f);

#ifdef CELTE_SERVER_MODE_ENABLED
  else if (filter == 1)
  ...

#else
  else if (filter >= 2)
  ...
#endif
}

EXPORT void RegisterGrapeRPC(const std::string &grapeId, int filter,
                             const std::string &name,
                             std::function<void(std::string)> f) {

  if (filter == 0)
    GRAPES.RunWithLock(grapeId,
                       [name, f](celte::Grape &g) { g.RegisterRPC(name, f); });
#ifdef CELTE_SERVER_MODE_ENABLED
  else if (filter == 1)
    ...
#else
  else if (filter >= 2)
  ...
#endif
}

EXPORT void RegisterEntityRPC(const std::string &entityId, int filter,
                              const std::string &name,
                              std::function<void(std::string)> f) {
  if (filter == 0)
    ETTREGISTRY.RunWithLock(
        entityId, [name, f](celte::Entity &e) { e.RegisterRPC(name, f); });
#ifdef CELTE_SERVER_MODE_ENABLED
  else if (filter == 1)
    ...
#else
  else if (filter >= 2)
    ...
#endif
}
```

This one is special, it can only be registerd by the concerned client
```C++
EXPORT void RegisterClientRPC(const std::string &clientId, int filter,
                              const std::string &name,
                              std::function<void(std::string)> f) {
#ifdef CELTE_CLIENT_MODE_ENABLED
  if (RUNTIME.GetUUID() == clientId)
    RUNTIME.GetPeerService().RegisterRPC(name, f);
#endif
}
```


#### CallRPC Export

The Global RPC can be called by anyone and executed by anyone (the filter is set at the registry)

```C++
EXPORT void CallGlobalRPC(const std::string& name, const std::string& args)
{
    celte::CallGlobalRPCHandler()
        .on_scope(celte::tp::global_rpc())
        .on_fail_log_error()
        .fire_and_forget(name, args);
}
```

The GrapeRPC can only be called if the grape exist, the developer choose if it should be executed only on the grapes or also on his subscriber
```C++
EXPORT void CallGrapeRPC(bool isPrivate, const std::string& grapeId,
    const std::string& name, const std::string& args)
{
    if (GRAPES.GrapeExists(grapeId))
        if (isPrivate)
            celte::CallGrapeRPCHandler()
                .on_peer(grapeId)
                .on_fail_log_error()
                .fire_and_forget(name, args);
        else
            celte::CallGrapeRPCHandler()
                .on_scope(grapeId)
                .on_fail_log_error()
                .fire_and_forget(name, args);
    else
        std::cout << "Grape not registered" << std::endl;
}
```

The EntityRPC can only be called if the entity exist, the developer choose if it should be executed only on the grapes or also on his subscriber
```C++
EXPORT void CallEntityRPC(bool isPrivate, const std::string& entityId,
    const std::string& name, const std::string& args)
{
    if (ETTREGISTRY.IsEntityRegistered(entityId) && ETTREGISTRY.IsEntityLocallyOwned(entityId))
        if (isPrivate)
            celte::CallEntityRPCHandler()
                .on_peer(entityId)
                .on_fail_log_error()
                .fire_and_forget(name, args);
        else
            celte::CallEntityRPCHandler()
                .on_scope(entityId)
                .on_fail_log_error()
                .fire_and_forget(name, args);
    else
        std::cout << "Entity not registered" << std::endl;
}
```

The ClientRPC can only be called by a server, and can only be executed by the concerned client (secured during the register)
```C++
EXPORT void CallClientRPC(const std::string& clientId, const std::string& name,
    const std::string& args)
{

#ifdef CELTE_SERVER_MODE_ENABLED
    celte::CallPeerServiceRPCHandler()
        .on_peer(clientId)
        .on_fail_log_error()
        .fire_and_forget(name, args);
#endif
}
```


### Bindings in Godot

#### In Celte API
All of the function are defined inside the CAPI.cpp but only the Global is bind inside it. The others are bind inside there own file (CClient.cpp, CEntity.cpp and CSN.cpp)

Here is an exemple of the implementation inside the CAPI.cpp
```C++

void CAPI::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("RegisterGlobalRPC", "filter", "name", "handler"), &CAPI::RegisterGlobalRPC,
        "Register a global RPC that can be called by any peer in the cluster.\n"
        "@param filter The filter for the RPC (all, server, client)\n"
        "@param name The name of the RPC.\n"
        "@param handler The handler to call when the RPC is called.");

    ClassDB::bind_method(D_METHOD("CallGlobalRPC", "name", "args"), &CAPI::CallGlobalRPC,
        "Call a global RPC.\n"
        "@param name The name of the RPC to call.\n"
        "@param args The arguments to pass to the RPC.");
}


void CAPI::RegisterGlobalRPC(int filter, const String& name, Callable c)
{
    if (not celteBindingsSingleton.RegisterGlobalRPC) {
        UtilityFunctions::push_error("RegisterGlobalRPC not loaded");
        return;
    }
    celteBindingsSingleton.RegisterGlobalRPC(std::string(name.utf8().get_data()), filter,
        [c](const std::string& args) {
            Dictionary d_args = JSON::parse_string(String(args.c_str()));
            c.call(d_args).operator String();
        });
}

void CAPI::CallGlobalRPC(const String& name, Dictionary args)
{
    if (not celteBindingsSingleton.CallGlobalRPC) {
        UtilityFunctions::push_error("CallGlobalRPC not loaded");
        return;
    }
    std::string s(JSON::stringify(args).utf8().get_data());
    celteBindingsSingleton.CallGlobalRPC(std::string(name.utf8().get_data()), s);
}
```
#### In Godot project
In this exemple you can see both how tu use the global and the grapes RPCs
1. Create a function
2. Register the function
3. Call the function

```python
# inside PlayerInit.gd

func _on_timer_timeout():
    if input_status == 0:
        var csn = get_node("/root/WorldMap/TopLevelExecutor/DynamicGrapeStub/CSN")
        if csn:
            print("find csn")
            csn.CallGrapeRPC(false, "rpc_test", {"to_print": "Grape RPC get Called"})
            csn.CallGrapeRPC(true, "rpc_test", {"to_print": "Call Private Grape RPC"})
        else:
            print("csn not found")
    elif input_status == 1:
        Celte.api.CallGlobalRPC("global_rpc_test", {"to_print": "Global RPC get Called"})
    input_status += 1

# Inside DynamicGrapeStub.gd

func global_rpc_test(args: Dictionary):
    print("in global rpc test:")
    print(args["to_print"])


func Init(name: String, locallyOwned: bool):
    $CSN.RegisterGrapeRPC(0, "rpc_test", func(args): call_deferred("rpc_test", args))
    Celte.api.RegisterGlobalRPC(0, "global_rpc_test", func(args): call_deferred("global_rpc_test", args))
```
