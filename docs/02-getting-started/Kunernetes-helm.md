


# Helm and Kubernetes Documentation

## Project Architecture

The CELTE project consists of two main components deployed in Kubernetes:

1. **Master**: The main component that manages server node orchestration
2. **Server Node (SN)**: Server nodes that are dynamically managed

### Namespace

All components are deployed in the `celte` namespace. This namespace is dedicated to the application and isolates resources from the rest of the cluster.

## Kubernetes Components

### Master

The master is deployed with the following characteristics:

- **Deployment**: `master`
  - Replicas: 3 (high availability)
  - Image: `clmt/celte-master:latest`
  - Port: 8080
  - Resources: (can be adjusted)
    - Requests: CPU 200m, Memory 256Mi
    - Limits: CPU 1000m, Memory 1Gi

#### Master RBAC Permissions

The master uses a ServiceAccount with specific permissions:

```yaml
ServiceAccount: master-sa
Role: master-role
Permissions:
- Deployments: get, list, watch, update, patch, delete (server-node only)
- Pods: get, list, watch, delete
- Services: get, list, watch
```

RBAC is used to restrict access to resources and ensure secure communication between components.

### Server Node

The server node is dynamically managed with the following characteristics:

- **Deployment**: `server-node`
  - Replicas: Variable (managed by master)
  - Image: `clmt/celte-sn:latest`
  - Port: 8080
  - Resources: (can be adjusted)
    - Requests: CPU 100m, Memory 128Mi
    - Limits: CPU 1000m, Memory 1024Mi

## Helm Configuration

The project uses Helm to manage deployments. The chart structure is as follows:

```
helm/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── master-deployment.yaml
    ├── master-rbac.yaml
    └── server-node-deployment.yaml
```

### Values

⚠️You must update the `values.yaml` file with the correct information before deploying the chart. (ip, port, etc.)

The main configurable values are defined in `values.yaml`:

```yaml
master:
  replicaCount: 3
  image:
    repository: clmt/celte-master
    tag: latest
  resources: ...

serverNode:
  image:
    repository: clmt/celte-sn
    tag: latest
  resources: ...
```

This is where the developer can adjust the deployment configuration.

## Operation

### Automatic Scaling

The master monitors and automatically manages server node scaling:

1. **Scale Up**:

   - Function `SnIncrease()`
   - Increases the number of replicas up to MaxReplicas (100)
2. **Scale Down**:

   - Function `SnDecrease(string snId)`
   - Removes a specific pod and reduces replica count
   - Always maintains at least 1 active SN

## Deployment

### Prerequisites

1. Operational Kubernetes cluster
2. Helm 3.x installed
3. `kubectl` configured for the cluster
4. [minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fbinary+download) or [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) for local development
5. [k9s](https://k9scli.io/) for monitoring is your best friend (k9s -n celte)
6. Create `celte` namespace:

```bash
kubectl create namespace celte
```

### Installation

```bash
# if you are using minikube
minikube start

# Load images into minikube
minikube image load clmt/celte-master:latest
minikube image load clmt/celte-sn:latest

# Initial installation
helm install celte-stack ./helm

# Update
helm upgrade celte-stack ./helm
```

### Deployment Verification

```bash
# Check deployments
kubectl get deployments -n celte

# Check pods
kubectl get pods -n celte

# Check services
kubectl get services -n celte

# Check RBAC
kubectl get serviceaccount,role,rolebinding -n celte
```

## Troubleshooting

### Common Issues

1. **"Forbidden" Error**:

   - Verify ServiceAccount is properly configured
   - Check RBAC is in the correct namespace
   - Ensure pod is using the correct ServiceAccount
2. **Pods in "Pending" State**:

   - Check available cluster resources
   - Verify pod requests/limits
3. **Communication Errors**:

   - Ensure services are in the correct namespace
   - Check connection environment variables

## Maintenance

### Updating Images

```bash
# Update tag in values.yaml
helm upgrade celte-stack ./helm
```

### Manual Scaling

```bash
kubectl scale deployment server-node -n celte --replicas=<number>
```

### Logs

```bash
# Master logs
kubectl logs -l app=master -n celte

# Specific server node logs
kubectl logs <pod-name> -n celte
```

## Development Guide

### Building Images

```bash
# Build master image
docker build -t clmt/celte-master:latest ./master

# Build server node image
docker build -t clmt/celte-sn:latest ./system
```