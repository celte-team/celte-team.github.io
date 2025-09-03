## CReplicationGraph and containers

- Stubs in demo-tek use a `CReplicationGraph` child to create containers and to control interest rules. It is expected that any node representing a server node has a `CReplicationGraph` child.
- Containers are used to group entities and optimize replication. Entities in a container are replicated to clients based on distance to the container and interest rules.
- Containers are created with `CReplicationGraph.CreateContainer(Callable then)`. The `then` callback is called when the container is ready to be used.
- Example usage in `Scenes/Stubs/stub.gd`:

```gdscript
var container = $Stub/CReplicationGraph.CreateContainer(func():
    # callback called when the network/container is ready
    print("Container is ready!")
)
container.global_position = $Stub.global_position
label.text = container.GetId().substr(0, 4)
container.add_child(label)
```

- You can configure metrics and interest rules via the replication graph API exposed on the `CReplicationGraph` object:

```gdscript
$Stub/CReplicationGraph.SetMetricToGetDistanceToContainer(getDistanceToContainer)
$Stub/CReplicationGraph.SetContainerServerInterestRule(containerServerInterestRule)
$Stub/CReplicationGraph.SetContainerInterestRule(containerInterestRule)
$Stub/CReplicationGraph.SetDebugAssigns(debugAssign)
```
