## Running in client vs server mode

- The demo checks an environment variable to decide server mode: `CELTE_MODE=server` makes nodes run as server nodes. The helper `CelteSingleton.gd` exposes `server_mode` (true when `CELTE_MODE` == `server`).
- Server-mode nodes typically run headless and register spawners/containers; client-mode nodes connect as players and request a server node via the lobby.

Server nodes should be started with the correct env vars and can be run in a container or Kubernetes pod with `CELTE_MODE=server`.
