- [Topic naming conventions](#topic-naming-conventions)
- [Notation in this document](#notation-in-this-document)
- [Kafka topics list](#kafka-topics-list)
  - [master](#master)
  - [client.{UUID}](#clientuuid)
  - [sn.{UUID}](#snuuid)
  - [{CHUNK\_ID}.\*](#chunk_id)
  - [\*.rpc](#rpc)
    - [Headers](#headers)
    - [Value](#value)
  - [global.clock](#globalclock)
    - [Headers](#headers-1)
    - [Value](#value-1)


# Topic naming conventions

The naming is relatively free, but should still follow some simple guidelines.
- the topic name should indicate which entity is consuming from it.
- the topic name must contain a clear indication of the topic's function.
- each part of the topic name is separated by a dot.

# Notation in this document

In this document, `*` can be replaced by any string of ASCII characters.
Any name between curly brackets (like `{UUID}` represents a variable that can be changed to create more equivalent topics.)

# Kafka topics list

## master

## client.{UUID}

Topics that begin by `client.{UUID}` are diffusion channels meant for a specific client, identified by its UUID.

The topic client.{UUID} should only be written to by the master server, and contains status messages and logs.

Derived topics (client.{UUID}.*) can fill in multiple functions but will always concern this client and only this client.

## sn.{UUID}

Topics that begin by `sn.{UUID}` are diffusion channels meant for a specific server node, identified by its UUID.

The topic server node.{UUID} should only be written to by the master server, and contains status messages and logs.

Derived topics (server node.{UUID}.*) can fill in multiple functions but will always concern this server node and only this server node.

## {CHUNK_ID}.*

Topics with a name that begin with the id of a chunk should be read by any peers interested in the events happening in the 3D space contained by this chunk.

## *.rpc

Any topic whose name ends in `.rpc` is meant to be a channel for calling remote procedures on all instances of the logical entity
represented by the chunk.

For example, one may call a procedure `foo` on `{CHUNK_ID}.rpc`, and all peers having this chunk loaded will execute `foo`.

### Headers

| Key   | Value |
|-------|-------|
| peer.uuid  | Unique string identifier of the peer producing the message to the topic |
| rpcUuid | Unique string identifier for this method call, used to identify a specific call and return a value for it |
| rpName  | String name of the remote procedure to be executed. *Optional* and can be replaced with `answer` (see below)|
| answer | The string uuid (rpcUuid) of the rpc this message is responding to. *Optional*, replaces `rpName` when the published message is not a call but a return value. |

### Value

The values in this topic are the serialized arguments for the method call or its return value.
Arguments are serialized using Message Pack, one after the other without any other formatting.


## global.clock

The global clock will publish the number of ticks since the start of the game to this topic.
All peers are exected to listen to this topic in order to ensure synchronization of all operations.

### Headers

| Key   | Value |
|-------|-------|
| deltaMs | The time in milliseconds (integer) between ticks |

### Value

Four bytes representing the value of the current tick as an integer.