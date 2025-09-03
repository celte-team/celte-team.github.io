# CELTE YAML configuration (~/.celte.yaml)

The Celte server reads configuration from a YAML file by default located at `~/.celte.yaml`. All processes in the Celte ecosystem (master, clock server, automation scripts) can use this file to load common configuration values such as Redis host/port, Pulsar broker address, Godot executable path, and other settings. Only the game client does not require it (or rather, it is left to the game developer to decide how to configure the client. Our example client code uses this config but it is bad design to have clients read from `~/.celte.yaml`).

If you prefer a different path you can set the `CELTE_CONFIG` environment variable to point to another file, or pass the path as the first command-line argument to the master binary. If the file is missing the master will fail to start with a clear error.

Format

The YAML file must contain a top-level `celte` key whose value is a sequence of mapping nodes. Each mapping entry is a single key/value config entry. The loader collects these into a string->string dictionary and all values are treated as strings by the code.

Example minimal file

```yaml
celte:
- CELTE_MASTER_HOST: 192.168.1.41
- CELTE_MASTER_PORT: 1908
- CELTE_REDIS_HOST: 192.168.1.41
- CELTE_REDIS_PORT: 6379
```

Notes about the format
- Keys are expected to be plain scalars (no nested objects). The loader accepts a sequence of YAML maps, e.g. `- KEY: value` entries as shown above.
- All values are parsed as plain strings. If you need to express booleans use string values `"true"` or `"false"` (single or double quotes are fine). The code compares string values (for example `Utils.GetConfigOption("CELTE_SERVER_GRAPHICAL_MODE", "false") != "true"`).
- Because values are strings you should be careful with paths that contain `:` characters on Windows — quoting them in YAML is recommended.

Where the file is loaded
- Default location: `~/.celte.yaml` (the master falls back to this when `CELTE_CONFIG` is not set and no path argument is provided).
- Override by setting `CELTE_CONFIG` environment variable to a full path.
- Or provide the path as the first CLI argument to the master process.

Common configuration keys

Below are the configuration keys used across the codebase, their purpose, where they are consumed, and sensible defaults when the key is not present.

- CELTE_MASTER_HOST
	- Purpose: Hostname/IP used by local tooling and examples. Not strictly required by the master to run, but used by automation and helper scripts.
	- Used in: automation scripts and docs.
	- Example: `192.168.1.41`

- CELTE_MASTER_PORT
	- Purpose: Port used by the master HTTP API (the master default listens on port `1908`).
	- Used in: documentation and local tooling.
	- Default: `1908` (master server binds to this port in `Program.cs` unless changed at runtime)

- CELTE_REDIS_HOST
	- Purpose: Hostname or IP of the Redis server the master connects to.
	- Used in: `master/Redis/RedisDb.cs`.
	- Default: `localhost` when not set.
	- Example: `192.168.1.41`

- CELTE_REDIS_PORT
	- Purpose: Redis TCP port.
	- Used in: `master/Redis/RedisDb.cs`.
	- Default: `6379` when not set.

- CELTE_REDIS_KEY
	- Purpose: Example key name used by tooling or conventions in the project (for example logs key name). Not strictly required by core Redis code, but present in example configs and automation mapping.
	- Used in: automations and examples. Treat as a project convention.
	- Example: `logs`

- CELTE_GODOT_PATH
	- Purpose: Absolute path to the Godot executable used to spawn server node processes (when running nodes locally).
	- Used in: `master/Kube/Up.cs` (required by the node spawn logic).
	- Default: none — the code throws an exception if this is empty. You must set this value when using local node spawning.
	- Example macOS path: `/Applications/Godot.app/Contents/MacOS/Godot`

- CELTE_GODOT_PROJECT_PATH
	- Purpose: Path to the Godot project used by server nodes; used as the working directory when launching Godot in server mode.
	- Used in: `master/Kube/Up.cs`.
	- Default: none — required when spawning local Godot server processes.
	- Example: `/Users/you/projects/celte-godot/projects/demo-tek`

- CELTE_PULSAR_HOST
	- Purpose: Pulsar broker hostname (DotPulsar client). The code builds a service URL like `pulsar://{CELTE_PULSAR_HOST}:{CELTE_PULSAR_PORT}`.
	- Used in: `master/ApachePulsar/ApachePulsar.cs`, `clock-server/clock.py` and other helpers.
	- Default: empty string (the Pulsar client initialization requires a non-empty value and will throw if not configured).
	- Example: `192.168.1.41`

- CELTE_PULSAR_PORT
	- Purpose: Pulsar broker port used to build the `pulsar://` service URL.
	- Used in: `master/ApachePulsar/ApachePulsar.cs`.
	- Default: `6650`.

- CELTE_PULSAR_ADMIN_PORT
	- Purpose: The port for the Pulsar Admin REST API. Used together with `CELTE_PULSAR_HOST` to construct a default `CELTE_PULSAR_ADMIN_URL`.
	- Used in: `master/ApachePulsar/ApachePulsar.cs` (default admin API port `30080` is used when not set in some code paths, but example configs often set `8080` or `30080` depending on deployment).
	- Default: `30080` when not set programmatically; examples often set `8080` for local setups.



- PUSHGATEWAY_HOST / PUSHGATEWAY_PORT
	- Purpose: Host and port for a Prometheus Pushgateway used by metrics upload or CI tooling.
	- Used in: automation and metrics code paths and examples.
	- Example: `PUSHGATEWAY_HOST: 192.168.1.41`, `PUSHGATEWAY_PORT: 9091`.

- METRICS_UPLOAD_INTERVAL
	- Purpose: Interval (seconds) used by metrics upload tasks.
	- Used in: metrics-related automation; value parsed as string (e.g. `5`).

- REPLICATION_INTERVAL
	- Purpose: Milliseconds or ms-like interval used by replication loops (project conventions vary). Set as string; code that uses it should parse it to integer.

- CELTE_SERVER_GRAPHICAL_MODE
	- Purpose: When launching Godot server processes, controls whether Godot is run in graphical mode or headless. Expected values are the strings `"true"` or `"false"`.
	- Used in: `master/Kube/Up.cs` (compares string to "true").
	- Default: `"false"` in examples.

- CELTE_LOBBY_HOST
	- Purpose: Host of a lobby service (project-specific). Used by automation and example configs.

Tips, secrets and environment overrides

- Environment overrides: Code frequently falls back to environment variables in other helpers (for example `clock-server/clock.py` prefers environment variables if set). For master startup the YAML file is the primary source; environment overrides for the master config are not universally implemented, so use `CELTE_CONFIG` to point to an alternative YAML when needed.

Validation and common errors

- The loader will throw if `~/.celte.yaml` does not exist or if it lacks the top-level `celte:` sequence. Ensure your YAML follows the `celte:` -> sequence-of-maps structure.
- Many keys are required by specific features; for example spawning local Godot nodes requires `CELTE_GODOT_PATH` and `CELTE_GODOT_PROJECT_PATH` or the code will throw an `InvalidOperationException`.
- Pulsar client initialization will throw if `CELTE_PULSAR_HOST` is not provided.

Full example (development + commented production block)

```yaml
# Dev config below
celte:
- CELTE_MASTER_HOST: 192.168.1.41
- CELTE_MASTER_PORT: 1908
- CELTE_REDIS_PORT: 6379
- CELTE_REDIS_KEY: logs
- CELTE_REDIS_HOST: 192.168.1.41
- CELTE_GODOT_PATH: /Applications/Godot.app/Contents/MacOS/Godot
- CELTE_GODOT_PROJECT_PATH: /Users/eliotjanvier/Documents/eip/celte-system/celte-godot/projects/demo-tek
- CELTE_PULSAR_HOST: 192.168.1.41
- CELTE_PULSAR_PORT: 6650
- CELTE_PULSAR_ADMIN_PORT: 8080
- PUSHGATEWAY_HOST: 192.168.1.41
- PUSHGATEWAY_PORT: 9091
- METRICS_UPLOAD_INTERVAL: 5
- REPLICATION_INTERVAL: 1000
- CELTE_SERVER_GRAPHICAL_MODE: 'false'
- CELTE_LOBBY_HOST: 192.168.1.41
```

Quick troubleshooting checklist

- "Missing 'celte' section" error: Verify the top-level `celte:` entry exists and is followed by `- KEY: value` entries.
- Pulsar errors: Ensure `CELTE_PULSAR_HOST` (and optionally `CELTE_PULSAR_PORT`) are set and reachable.
- Godot spawn errors: Ensure `CELTE_GODOT_PATH` and `CELTE_GODOT_PROJECT_PATH` are set and point to valid filesystem locations.
- Redis connection problems: Verify `CELTE_REDIS_HOST`/`CELTE_REDIS_PORT` are correct and that Redis is reachable from the master process.
