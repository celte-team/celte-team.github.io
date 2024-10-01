# Kafka encapsulation

Kafka is a vast library with many settings. Celte tries to abstract them so that the developer does not have to think too much about how kafka works. Many options of kafka can still be defined manually so be sure to read the documentation of kafka to get a good hold of the options available, and how kafka works, before continuing to read this document.

## Why Kafka

Celte must be able to send many messages to a great number of peers, with a high throughput. Kafka's topics make it easy to create subscription lists that peers can poll from, and is designed to handle very fast data transfer.

## Celte's kafka cluster

Celte deploys a kafka cluster using docker compose. By default 3 kafka nodes are created but one may regenerate the docker compose for any number `n` of nodes using the [autogen.py](https://github.com/celte-team/celte-system/blob/main/kafka/autogen.py) script.

After using `docker compose up` to create the cluster, the configuration looks like this:
- `n` kafka brokers ready to handle incoming requests and replicate the data over the cluster
- a proxy (`haproxy`) running on port 80 by default, serving as a unique entry point to communicate to the cluster and loadbalances the requests between the brokers
- zookeeper instance(s) that manage the replication of the data in the cluster
- telemetry using `haproxy`'s prometheus services on port 8405 (download prometheus binaries and run it with [this](https://github.com/celte-team/celte-system/blob/main/kafka/prometheus.yml) configuration.)
- insight on the messages published to kafka and consumers subscribed to the topics using kafdrop (open localhost:9000 in your browser when the cluster is running to see it)

## Kafka in Celte Systems

### Subscribing : Async vs sync

All actions related to kafka are done by the [KafkaPool](https://github.com/celte-team/celte-system/blob/main/runtime/include/KafkaPool.hpp) class.
Polling for data being an IO operation, it is expected to take most of the processing time of the network layer. Thus, polling is by default done in a separate thread. Polled data is pushed on a queue, waiting to be processed all at once in a synchronous way using the `KafkaPool::CatchUp` method. (Users are free to make this async by launching a new thread to run the processing of data but by default Celte does not force the user to use multithread synchronization).

To subscribe to a topic, use the following method:

```c++
struct SubscribeOptions {
    std::string topic = ""; // What topic to subscribe to
    std::string groupId = ""; // Leave empty for automatic group assignment
    bool autoCreateTopic = true; // If set to false, subscribing will fail if the topic does not yet exist.
    std::map<std::string, std::string> extraProps = {}; // Add custom kafka properties as key value pairs here.
    bool autoPoll = true; // If set to false, polling will not be async and will require the user to manually call the Poll method.
    MessageCallback callback = nullptr; // The method that will be invoked by CatchUp on the data received.
};
void Subscribe(const SubscribeOptions &options); // Call this with the properties above to subscribe to the topic.
```

If `autoPoll` is set to `false`, polling for messages will need to be done manually for the group of the consumer.

### Sending

Sending a message is always done asynchronously. The main challenge is to avoid memory leaks when sending messages, where the data to send will be free'd before being sent resulting in garbage being passed to kafka.

Sending is done by creating a ProducerRecord that contains the data to send and headers. Doing so manually is possible but should be done carefully to avoid leaking memory. Many bugs related with sending data are related to the sent data being free'd early, resulting in garbage being delivered.

To avoid this issue, capture the relevant data and headers as a shared pointer in the capture clause of the delivery callback. This callback is only called when the message has been delivered, so the shared pointer will stay alive
until then. This behavior is encapsulated in an overload of the Send method, but it can still be done manually if needed.

```c++
// Example for manually sending a record
void foo() {
    std::shared_ptr<std::string> message = "hello world";
    auto record = kafka::clients::producer::ProducerRecord(
    "topicName", kafka::NullKey,
    kafka::Value(message->value.c_str(), message->value.size()));

    // capturing the message here to avoid memory leaks
    auto deliveryCallback = [message](const kafka::clients::producer::RecordMetadata &metadata,
             const kafka::Error &error) {
                // handle delivery errors
             }

    // See below
    Send(record, deliveryCallback);
}

// This overload lets the user create the record manually.
inline void Send(
      kafka::clients::producer::ProducerRecord &record,
      const std::function<void(const kafka::clients::producer::RecordMetadata &,
                               kafka::Error)> &onDelivered) {
    __send(record, onDelivered);
}

// This structure encapsulates all the necessary elements to send a message
struct SendOptions {
    std::string topic = "";
    std::map<std::string, std::string> headers = {};
    std::string value = "";
    std::function<void(const kafka::clients::producer::RecordMetadata &,
                        kafka::Error)>
        onDelivered = nullptr;
};

// This overload creates the record for the user, handling memory for the user.
void KafkaPool::Send(const KafkaPool::SendOptions &options) {
  // wrapping the options in a shared ptr to avoid copying or dangling
  // references
  auto opts = std::make_shared<SendOptions>(options);
  auto record = kafka::clients::producer::ProducerRecord(
      opts->topic, kafka::NullKey,
      kafka::Value(opts->value.c_str(), opts->value.size()));

  // wrapping the error callback to capture the shared ptr and keep it
  // alive
  auto deliveryCb =
      [opts](const kafka::clients::producer::RecordMetadata &metadata,
             const kafka::Error &error) {
        if (opts->onDelivered) {
          opts->onDelivered(metadata, error);
        }
      };

  // Set the headers of the record to hold the name of the remote
  // procedure
  std::vector<kafka::Header> headers;
  for (auto &header : opts->headers) {
    headers.push_back(kafka::Header{
        kafka::Header::Key{header.first},
        kafka::Header::Value{header.second.c_str(), header.second.size()}});
  }
  record.headers() = headers;

  __send(record, deliveryCb);
}

```