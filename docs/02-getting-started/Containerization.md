# Containerization

As a dynamic and distributed system, Celte can be run in a containerized environment. This allows for easy deployment and scaling of the system.
Kubernetes is our first choice to deploy Celte in a production environment.
However, for development purposes, we use docker-compose to run Celte in a containerized environment.

This is an overview of how Celte is designed to run in a dockerized environment.

## Docker Pulsar

Celte uses pulsar as a communication protocol. To run pulsar in a docker container, you can use the following command:

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
docker run -v $(pwd):/workdir -it [NAME_OF_YOUR_IMAGE] /bin/bash
```

then you can run the SDK with the following command:

```bash
cd /workdir
cmake --preset default ..
make -j
```


## Kubernetes

Deployment of Celte depends on your technical constraints, whether on Kubernetes or another orchestrator. Celte includes a testing environment that uses Docker Compose and can be executed with the command:

```./automations/run --all```

Celte can also be deployed with Kubernetes (K8s). The local Kubernetes deployment requires the following tools:
  • `Minikube`: To create a local Kubernetes cluster.
  • `kubectl`: To manage Kubernetes resources from the command line.
  • `k9s`: For an enhanced terminal-based UI to interact with Kubernetes clusters.

Right now the K8S configuration is present inside the `devops` folder.
Inside, you will find the following files:
```
├── devops
│   ├── master.deployment.yaml
│   ├── master.hpa.yaml
│   ├── server-node.deployment.yaml
│   ├── server-node.hpa.yaml

```
This is a basic configuration to deploy Celte on Kubernetes. You can modify it to fit your needs.

This is a configuration example for the master deployment:
```
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: master
  minReplicas: 1
  maxReplicas: 4
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 60
```


The important part is the `spec` section. You can modify the
` minReplicas ` and `maxReplicas` to fit your needs.

And the `minReplicas` and `maxReplicas` to control the autoscaling of the master.

The current image of the Celte master is `clmt/celte-master:latest`.

