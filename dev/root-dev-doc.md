# Developer resources

Here you will find resources documenting the inner workings of Celte Server Meshing, sorted by topics.

This is still a work in progress, but you can expect to find diagrams and explainations about the various procedures performed by Celte, both from an algorithmic and from a network point of view.

## Fundamental concepts

### Kafka

Apache Kafka is the communication protocol used by Celte. You may want to check out both the [official kafka documentation](https://kafka.apache.org/documentation/), the [repository](https://github.com/morganstanley/modern-cpp-kafka/tree/main) of the c++ kafka encapsulation used by Celte, as well as [how to use kafka in Celte](Kafka.md).

#### Topics

At the heart of kafka (and thus, Celte), topics create diffusion lists for the information of the game. Each topic has its own rules
when it comes to which data to pass, and how this data gets formatted. Click [here](topics.md) to see the list of all available topics and
learn how to format data to produce it to kafka.

### RPCs

RPCs (Remote Procedure Calls) are methods that can be invoked on another machine and are at the very heart of Celte. See [this documentation](RPC.md).

### Hooks

Hooks are customizable lambda expressions that are called by Celte at key moments of the execution, to implement specialized behaviors for the user. Such behavior may include spawning the player... See [here](Hooks.md).

### Docker overview

Celte is designed to run in a dockerized environment. This is a brief overview of how Celte is designed to run in a dockerized environment. See [here](Docker.md).