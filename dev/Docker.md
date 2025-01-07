# Docker : how to run Celte in a dockerized environment

Celte is designed to run in a dockerized environment. This is a brief overview of how Celte is designed to run in a dockerized environment.

## Docker Pulsar

Celte uses kafka as a communication protocol. To run kafka in a docker container, you can use the following command:

```bash
./automation/run --pulsar
```

## Docker Celte SDK

To run the Celte SDK in a docker container, you can use the following command from the root of the Celte repository:

### to build the container from a ARM64 machine

```bash
docker buildx build --platform linux/amd64 -t [NAME_OF_YOUR_IMAGE] . --output type=docker
```

### to build the container from a x86 machine

```bash
docker build -t [NAME_OF_YOUR_IMAGE] .
```

### to run the container

```bash
docker run -v $(pwd):/workdir -e CELTE_CLUSTER_HOST="[YOUR_LOCAL_IP]" -it [NAME_OF_YOUR_IMAGE] /bin/bash
```

note: `[YOUR_LOCAL_IP]` is the IP of your machine, you can get it by running `ifconfig` in a terminal. It is the same that you used to run the kafka container.

then you can run the SDK with the following command:

```bash
cd /workdir
cmake --preset default ..
make -j
```
