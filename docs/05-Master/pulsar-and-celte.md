# Apache pulsar

Apache pulsar is the messaging system at the heart of celte. It is a `pub / sub` system, where messages are *produced* on *topics* and *consumers* can *subscribe* to those topics in order to receive the data published to it.

## Topics

Data published on pulsar topic is mainly [Remote procedure calls](./RPCS.md) but some other data streams exist such as [Inputs](./procedure-inputs.md) or [replication data](./procedure-property-replication.md).

Celte data is divided on various topics to segment the data and group relevant information together.

- Each peer gets a `{peer uuid}.rpc` topic where RPCs that concern this peer and only this peer can be called
- Grapes have:
  - a `{grape uuid}.rpc` topic where RPCS concerning all peers who have this grape instantiated are called
  - a `{grape uuid}` topic, which is only red on by the server node owning the grape. RPCs published on this topic are not meant for all to execute, only by the rightful owner of the grape
- Entity containers have:
  - an `{entity container uuid}.rpc` topic for listening to method calls that concern all entities replicated by this container
  - an `{entity container uuid}.repl` topic for server nodes to broadcast the replication data of the entities owned by the container
  - an `{entity container uuid}.input` topic for clients to send their inputs to the network. Peers replicating the container can use these inputs to simulate the game until the server node sends the associated replication data.
- The master server gets:
  - `master.hello.sn` where server nodes send their uuid when they are ready to start serving
  - `master.hello.client` where clients send their uuid to connect to the cluster and get assigned to a server node
  - `master.rpc` where any remote call to run on the master can be sent.

## Encapsulation

For the user who wants to learn more about pulsar, the official documentation is available [here](https://pulsar.apache.org/docs/4.0.x/).
Celte encapsulates the pulsar `consumer` and `producer` to achieve the following goals:
- streamlining the creation of a message to send by serializing request `structs`. Structs make it easy for the caller / callee to manipulate the data in the requests while celte handles packaging the data into json (which might change to a more optimized format in the future).
    ```c++
    struct SpawnPositionRequest
        : public celte::net::CelteRequest<SpawnPositionRequest> {
    std::string clientId;
    std::string grapeId;
    float x;
    float y;
    float z;

    void to_json(nlohmann::json &j) const {
        j = nlohmann::json{{"clientId", clientId},
                        {"grapeId", grapeId},
                        {"x", x},
                        {"y", y},
                        {"z", z}};
    }

    void from_json(const nlohmann::json &j) {
        j.at("clientId").get_to(clientId);
        j.at("grapeId").get_to(grapeId);
        j.at("x").get_to(x);
        j.at("y").get_to(y);
        j.at("z").get_to(z);
    }
    };
    ```
- making it easy to decide in which context the callbacks on message reception should be executed (i.e completely async or in celte's main thread).
- increase dynamism by automatically creating new producers for new topics while deleting usused producers.

To achieve this, Celte has three main classes dedicated to sending / receiving messages over pulsar.

### ReaderStream

The `ReaderStream` class lets the user subscribe to a topic and register message handlers.
The options when creating a `ReaderStream` are the following:

```c++
  template <typename Req> struct Options {
    std::string thisPeerUuid;
    // subscribe to multiple topics if needed
    std::vector<std::string> topics;
    // subscription name for pulsar partionning and source tracking
    std::string subscriptionName;
    // if true, only this stream can read from this topic on the whole network
    bool exclusive = false;
    // message handler that runs in celte's main thread
    std::function<void(const pulsar::Consumer, Req)> messageHandlerSync =
        nullptr;
    // message handler than runs asyncronously
    std::function<void(const pulsar::Consumer, Req)> messageHandler = nullptr;
    // callback called in celte's main thread when the reader is ready to be used
    std::function<void()> onReadySync = nullptr;
    // callback called in celte's main thread when the reader encounters a connection error
    std::function<void()> onConnectErrorSync = nullptr;
    // callback called asyncronously when the reader is ready to be used.
    std::function<void()> onReady = nullptr;
    // callback called asyncronously when the reader encounters a connection error.
    std::function<void()> onConnectError = nullptr;
  };
```

`ReaderStreams` are templated and only expect one type of request.

```c++
   auto rs = std::make_shared<ReaderStream>();
    _readerStreams.push_back(rs);
    rs->Open<Req>(options); // subscribes to pulsar topics
    return rs;
```

### WriterStream

The `WriterStream` class lets the user send messages asyncronously, and execute a callback when the message has been delivered successfully.

The options work in the same fashion as those for the `ReaderStream` class.

```c++
  struct Options {
    std::string topic;
    bool exclusive = false;
    std::function<void(WriterStream &)> onReadySync = nullptr;
    std::function<void()> onConnectErrorSync = nullptr;
    std::function<void(WriterStream &)> onReady = nullptr;
    std::function<void()> onConnectError = nullptr;
  };

    auto ws = std::make_shared<WriterStream>(options);
    _writerStreams[options.topic] = ws;
    ws->Open<Req>();
    return ws;
```

### WriterStreamPool

Sometimes, the destination topic for the messages changes often. In that case, having a single writer stream is not efficient. Using the `WriterStreamPool` creates producers to the desired topic and destroys it when it stops being used.

```c++

  _writerStreamPool.emplace(
      net::WriterStreamPool::Options{
          .idleTimeout = std::chrono::milliseconds(1000),
      },
      RUNTIME.IO());

  std::string topic = "test_topic";
  req::BinaryDataPacket packet{.binaryData = msg,
                               .peerUuid = RUNTIME.GetUUID()}; // any type inheriting from CelteRequest can be used
  _writerStreamPool->Write(topic, packet, []() {
    std::cout << "message delivered!" << std::endl;
  });
```