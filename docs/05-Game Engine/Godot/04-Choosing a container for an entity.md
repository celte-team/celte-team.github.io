# Choosing a container

Containers are used to divide the workload of adjacent servers, so that they can replicate some of the entities of another server without having to deal with them all (which would just double the work and be counter productive).

Using the CReplicationgraph, one can set a metric to compute the logical distance of an entity to a container. The most naive implementation is to base this calculation on the physical distance between the entity and the position of the container, but the calculus can be as esoteric as needs be.

Celte will uses the K-means algorithm behind the hood to recalcutate the positions of containers, and adds entities to containers based on the custom metric provided.

```python
	$CSN/CReplicationGraph.SetMetricToGetDistanceToContainer(getDistanceToContainer)
```

```python
func getDistanceToContainer(entity: Node3D, container: CContainer):
		return entity.position.distance_to(container.position)
```

# Debuging containers

A callback will be called on containers with the list of the entities assigned to this container passed in argument. Use it to debug your containers, or running extra logic (such as adding more containers to alleviate the workload).

```python

func debugAssign(container, entities: Array):
# we draw a bounding box around all the entities owned by the container.
# this will only be visible on the server that owns the containers.
		if entities.size() == 0:
			return
		var min_coords = Vector3(INF, INF, INF)
		var max_coords = Vector3(-INF, -INF, -INF)

		for entity in entities:
			if entity is Node3D:
				var global_position = entity.global_transform.origin
				min_coords.x = min(min_coords.x, global_position.x)
				min_coords.y = min(min_coords.y, global_position.y)
				min_coords.z = min(min_coords.z, global_position.z)

				max_coords.x = max(max_coords.x, global_position.x)
				max_coords.y = max(max_coords.y, global_position.y)
				max_coords.z = max(max_coords.z, global_position.z)

		var center = (min_coords + max_coords) * 0.5
		var extents = (max_coords - min_coords) * 0.5

	  	# if coords are too close from one antoher we draw a bit larger
		if extents.length() < 5:
			extents = Vector3(5, 5, 5)
		DebugDraw3D.draw_box(center, Quaternion(0, 0, 0, 1), extents, Color(0.5, 0.5, 0.5), true, 10.0 / 60.0)

```