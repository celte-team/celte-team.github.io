# Containerization

As a dynamic and distributed system, Celte can be run in a containerized environment. This allows for easy deployment and scaling of the system.
Kubernetes is our first choice to deploy Celte in a production environment.
However, for development purposes, we use docker-compose to run Celte in a containerized environment.

This is an overview of how Celte is designed to run in a dockerized environment.

## Docker Pulsar

Celte uses pulsar as a communication protocol. To run pulsar in a docker container, you can use the following command:

```bash
./automation/run --pulsar (or use --all to run all the services)
```

## Docker Celte SDK

To run the Celte SDK in a docker container, you can use the following command from the root of the Celte repository:

### to build the container from a ARM64 machine to run on a x86 machine

```bash
docker buildx build --platform linux/amd64 -t [NAME_OF_YOUR_IMAGE] . --output type=docker
```

If you want to build for a local machine, you can use the following command:
```bash
docker build -t [NAME_OF_YOUR_IMAGE] .
```

### to run the container

```bash
docker run -it [NAME_OF_YOUR_IMAGE]
```