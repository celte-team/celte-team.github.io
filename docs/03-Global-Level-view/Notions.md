# Celte's server meshing implementation

Celte's implementation of server meshing relies of the idea that, in order to achieve server meshing, information must be shared between servers to ensure seamless interactions and transitions between servers.
To achieve this, Celte relies on Apache pulsar to broadcast data to the relevant actors of the system, and divides information in order to reduce the load on individual machines. The repartition of the information can be dynamically updated to ensure a good repartition of the workload.

## Scopes

The idea is that every piece of information is relevant to a number of peers and can thus be categorized so that peers looking for it can find it more easily. Each piece of information has a scope. Peers outside of this scope do not have access to the information, and peers inside of the scope should be automatically notified of all the updaters happening in this scope. Scopes are of two sorts:
- Functional, meaning that they define scopes based on *function*: data that concerns only servers, clients...
- Logical, meaning that they are used to partition the data based on relevance (often spatial relevance although that is not always the case).

### Logical partitionning

The game world is divided spatially into zones that are under the authority of a single server (server node). Servers and clients may be aware of mutliple servers at the same time, depending on their position. To avoid having to replicate all the data of a server node at once, the data of each server is split once more into **Containers**. This split is done using custom logic from the user and can be arbitrary, but in its most basic form it can be pure spatial partionning of the entities in the game world. This allows a peer connected to a server to remain aware only of the entities that are relevant (*e.g* spatially) to it.

Each container has an assigned set of pulsar topics, to which interested peers can subscribe to start receiving updates about the events happening in this particular region on the world.

### Functional partionning

Each peer has a dedicated pulsar topic that can be used to communicate information to this peer and only this peer.
Zones under the authority of a single server also have two dedicated topics,  which are dissociated from the topic of the server itself:
- on of these topics if for all peers connected to the server to receive the information (public channel, the server usually is the one writting to it)
- the other topic if for information relevant only to the server, but not to the peers connected to it.