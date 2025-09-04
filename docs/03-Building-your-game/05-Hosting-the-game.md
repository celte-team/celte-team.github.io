# Hosting the game (development & production)

This page explains how to host a Celte-based game during development and in production. It uses artifacts and conventions from this repository: the provided Docker Compose for local/dev stacks, a Helm chart for Kubernetes deployment, and small helper services (lobby, master, Pulsar, Redis).

Sections
- Quick dev setup (Docker Compose)
- Running services individually during development (master, lobby, Godot nodes)
- Production deployment (Helm / Kubernetes)
- Configuration, secrets and recommended operational practices

Quick development setup (single-machine)

The repository contains a full developer-friendly stack in `docker-compose.yml` that starts Pulsar, BookKeeper, Redis, Prometheus/Grafana and helper services. The compose file is deliberately commented in some places (masters and lobby are optional) so you can enable only the parts you need.

Steps

1) Ensure you have Docker and docker-compose installed.
2) Create a local YAML config (example: `~/.celte.yaml`) following `docs/03-Building-your-game/02-YAML-config.md`.

Start the stack (background):

```bash
# from repo root
docker compose up -d
```

Notes
- The compose file exposes Redis (6379), Pulsar broker (6650) and Pulsar admin (8080), Prometheus (9090), Grafana (3000) and Pushgateway (9091).
- For development you can enable the `lobby-server` and one `master` instance in the compose file by uncommenting the relevant blocks. The compose file contains examples for mounting `~/.celte.yaml` into containers so services can read your config.

Running components individually (development)

Master server (C#)

- Build and run via the provided VS Code tasks or dotnet CLI. From the repo root:

```bash
# build
dotnet build master/master.csproj

# run
dotnet run --project master/master.csproj
```

- The master expects a YAML config path. By default it will read `~/.celte.yaml`. Override with `CELTE_CONFIG` env var or pass the path as first argument.

Lobby server (Go)

- The example lobby lives under `celte-godot/projects/lobby-server`.

```bash
cd celte-godot/projects/lobby-server
go build -o lobby-server .
./lobby-server            # reads ~/.celte.yaml by default (or CELTE_CONFIG)
```

Godot server nodes (development)

- The master can spawn local Godot server processes when `CELTE_GODOT_PATH` and `CELTE_GODOT_PROJECT_PATH` are configured. Set `CELTE_SERVER_GRAPHICAL_MODE` to `false` to run headless.

```bash
export CELTE_CONFIG=$HOME/.celte.yaml
export CELTE_MODE=server
dotnet run --project master/master.csproj
```

Production deployment (Kubernetes with Helm)

This repository includes a Helm chart in `helm/` for deploying the core components in Kubernetes. The chart contains values for `master` and `serverNode` images, resource requests/limits and autoscaling configuration.

Basic steps

1) Build/push container images for `master`, `server-node` and `lobby` to your registry (or use prebuilt images if available).
2) Customize `helm/values.yaml` to point to your image registry and set `PULSAR_BROKERS` and `REDIS_HOST` environment values.
3) Install the chart to your cluster:

```bash
# from repo root
helm install celte-stack ./helm -n celte --create-namespace -f ./helm/values.yaml
```

Operational notes
- Scale the `master` component to at least 2-3 replicas for resiliency (the chart defaults to 3 replicas).
- Use a managed Redis (or a highly available Redis cluster) and point `REDIS_HOST` to it; avoid single-node Redis in production.
- Pulsar must be deployed as a production-grade cluster (BookKeeper + Zookeeper + Brokers). The compose file is useful for testing but is not production-grade.
- Use Kubernetes Secrets for sensitive items (Pulsar admin token if required). Do not hardcode secrets in `values.yaml`.

High-availability and scaling

- Master: stateless HTTP frontends may be scaled horizontally; ensure they share the same Redis and Pulsar backends.
- Server nodes (game nodes): scale based on CPU/memory and autoscaling policies. The Helm chart supports resource requests/limits and HPA configuration.
- Lobby: scale lobbies separately from masters; they handle auth and matchmaking logic.

Configuration and secrets

- Central config: the master and lobby read configuration from a YAML file (default `~/.celte.yaml`) or environment variables. The master supports overriding the path with `CELTE_CONFIG`.
- Secrets: keep Pulsar admin tokens and any sensitive credentials in a secrets manager or Kubernetes Secret. The codebase reads `CELTE_PULSAR_ADMIN_TOKEN` when interacting with the Pulsar Admin API.

Graceful startup and shutdown

- On startup the lobby example calls `server/create_session` and schedules root nodes with `server/create`.
- On shutdown the lobby calls `redis/clear` and `server/cleanup_session` to remove session state and clean up Pulsar namespaces; ensure your deployment pipelines and restart policies respect graceful shutdown windows so cleanup can run.

Monitoring and observability

- The compose file includes Prometheus and Grafana. In production integrate with your Prometheus/Grafana stack and export metrics from master and lobby.
- Use the Pushgateway for ephemeral metrics when needed.

Backups and disaster recovery

- Back up Redis data regularly or use a managed Redis service with backups.
- For Pulsar, ensure BookKeeper persistence and topic retention policies are correctly configured, and snapshot/backup strategies are in place for metadata where necessary.

Security checklist

- Run services in private networks; expose only the lobby (or a secure ingress) to the internet.
- Protect Pulsar admin endpoints with authentication and restrict access to admin tokens.
- Use TLS for public endpoints and internal service-to-service communication when possible.

Example troubleshooting commands

```bash
# tail master logs (docker)
docker logs -f master1

# check Pulsar broker health
curl http://localhost:8080/admin/v2/brokers

# clear session keys during development
curl -X POST http://localhost:1908/redis/clear -H 'Content-Type: application/json' -d '{"SessionId":"session-123"}'
```

Further resources

- See `helm/values.yaml` for production defaults and autoscaling options.
- See `docker-compose.yml` for a full local dev stack (useful for integration testing).
- See `docs/03-Building-your-game/02-YAML-config.md` for the required YAML configuration file format and keys.
