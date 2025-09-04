## Deploying Apache Pulsar for Celte (Helm + Kubernetes)

This guide shows how to deploy a production-ready Apache Pulsar cluster for Celte using Helm with the following values. It **e**nables all core components and sets resource requests/limits and storage.

### Prerequisites

- A Kubernetes cluster (3+ worker nodes recommended)
- kubectl and Helm installed
- A default StorageClass or `local-path` provisioner installed (for `storage.className: local-path`)
- Cluster nodes reachable on the advertised broker IP if you set a public `advertisedAddress`

### Namespace and chart repo

```bash
kubectl create namespace pulsar
helm repo add apache https://pulsar.apache.org/charts
helm repo update
```

### Save values file

Create `pulsar-values.yaml` with the content below.

```yaml
# Enable core components
components:
  zookeeper: true
  bookkeeper: true
  broker: true
  proxy: true
  functions: true
  pulsar_manager: true

# Anti-affinity helper template
global:
  podAntiAffinity:
    enabled: true
    topologyKey: kubernetes.io/hostname  # spread across VMs

zookeeper:
  replicaCount: 3
  resources:
    requests:
      cpu: "200m"
      memory: "1Gi"
    limits:
      cpu: "500m"
      memory: "2Gi"
  persistence:
    enabled: true
    size: 10Gi
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: pulsar-zookeeper
        topologyKey: kubernetes.io/hostname

bookkeeper:
  replicaCount: 3
  resources:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "3Gi"
  persistence:
    enabled: true
    size: 30Gi
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: pulsar-bookkeeper
        topologyKey: kubernetes.io/hostname

broker:
  replicaCount: 3
  resources:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "3Gi"
  configuration:
    advertisedAddress: "57.128.60.39"
    brokerServicePort: 6650
    brokerServicePortTls: 6651
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: pulsar-broker
        topologyKey: kubernetes.io/hostname

proxy:
  replicaCount: 1
  service:
    type: NodePort
    ports:
      http: 8080
    configuration:
      brokerServiceURL: pulsar://pulsar-proxy.pulsar.svc.cluster.local:6650
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1"
      memory: "2Gi"

functions:
  replicaCount: 1
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1"
      memory: "2Gi"

pulsar_manager:
  enabled: true
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"

# Storage backend
storage:
  className: local-path
```

### Install

```bash
helm install pulsar apache/pulsar \
  --namespace pulsar \
  -f pulsar-values.yaml
```

### Verify

```bash
kubectl -n pulsar get pods
kubectl -n pulsar get svc
```

- Brokers should be 3/3 ready, Zookeeper 3/3, BookKeeper 3/3.
- The proxy service is NodePort exposing HTTP 8080 and broker service URL internally.

### Notes for Celte

- Clients connect to the broker via the proxy or directly to brokers on port 6650. Ensure firewall/NAT allows access to the `advertisedAddress` (57.128.60.39) if clients are outside the cluster.
- Storage class `local-path` requires a `local-path-provisioner`. Replace `storage.className` with your cloud provider’s storage class in managed clusters.
- For TLS or external load balancers, set appropriate `brokerServicePortTls` and configure proxy/broker ingress accordingly.
