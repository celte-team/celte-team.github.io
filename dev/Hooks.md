# Hooks : how to use them

From within the celte systems (not talking about engine encapsulation yet), a hook is used by calling it/ setting it
from the celte::api::HooksTable class (CelteHooks.hpp). Available hooks are different for clients and server nodes.
Set a hook like so:

```c++
  // This will be replaced by a setter in Celte's engine APIs. The contents of the lambda is user defined code.
  HOOKS.client.connection.onConnectionProcedureInitiated = []() {
    std::cout << "Connection procedure initiated" << std::endl;
    return true;
  };
```

And use it like this:

```c++
  // this is extracted from the procedure of connecting the client to the server.
  // the way this is called cannot be customized by the user.
  if (not HOOKS.client.connection.onConnectionProcedureInitiated()) {
    std::cerr << "Connection procedure hook failed" << std::endl;
    HOOKS.client.connection.onConnectionError();
    transit<Disconnected>();
  }
```

You can see that hooks are divided into sections such as client / server, and subsections (client.connection, client.player, ...). This is for better logical segmentation but does not have any major influence on how the hooks are used.

Find a complete list of the hooks, checkout this [page](../doxygen/html/classcelte_1_1api_1_1_hooks_table.html).