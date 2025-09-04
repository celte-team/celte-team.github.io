# The Master API

The Master API (master server) exposes HTTP routes to control game sessions, create and accept server nodes, connect clients, and manage session-scoped Redis data. One or more master servers can run for fault resilience; they provide a small JSON-over-HTTP API on port 1908 by default.

This document describes each route, the expected request payloads (JSON), query parameters, typical responses, error cases, and examples you can copy-paste.

Overview of available routes

- POST /server/create — create a child server node (schedule creation)
- POST /server/connect — accept a node that attempts to join the cluster
- POST /client/link — connect a game client to the appropriate server node
- POST /redis/clear — clear Redis keys for a given session
- POST /server/create_session — create Pulsar/namespace resources for a session
- POST /server/cleanup_session — cleanup processes and resources for a session

Common notes

- All endpoints accept or return JSON and set the Content-Type header to `application/json`.
- The master listens on port 1908 by default (configured in the server startup). Adjust the host/port in your deployment if needed.
- Most endpoints require a `SessionId` value to scope actions to a particular game session.
- Error responses have the shape `{ "error": "..." }` and use appropriate HTTP status codes (400 for client errors, 500 for server errors).

## 1) POST /server/create

Purpose: Schedule the creation of a new child node in the cluster under a given parent node.

Request JSON body (application/json)

```json
{
  "parentId": "<parent node id>",
  "payload": "<string payload>",
  "SessionId": "<session id>"
}
```

Notes on fields:
- parentId: Identifier of the parent node. If it already starts with `sn-` it will be used to generate a deterministic child id (using a Redis counter). If it does not start with `sn-`, the system will create a node id prefixed with `<SessionId>-sn-<parentId>`.
- payload: Arbitrary string stored with the node (used by your node process).
- SessionId: Required. Scopes the created node to a session.

Successful response (200)

```json
{
  "message": "Child node scheduled for creation."
}
```

Client errors (400)

- Missing or empty `SessionId` in the request -> `{"error": "SessionId is required"}`
- Malformed JSON -> `{"error": "<json parse error>"}` (400)

Server errors (500)

- Errors during node process scheduling -> `{"error": "<exception message>"}`

Example curl

```bash
curl -X POST http://localhost:1908/server/create \
  -H 'Content-Type: application/json' \
  -d '{"parentId":"sn-Root","payload":"{}","SessionId":"session-123"}'
```

## 2) POST /server/connect

Purpose: Accept a node which attempts to join the cluster. This is called by the node runtime when it reports as ready.


Request JSON body (application/json)

```json
{
  "Id": "<node id>",
  "Pid": "<parent id>",
  "SessionId": "<session id>",
  "Ready": true
}
```

Notes on fields:
- Id: Node identifier (must already exist in Redis - creation must have been scheduled before connecting).
- Pid: Parent node id.
- SessionId: Required. The session this node belongs to.
- Ready: Boolean. If false the master will reject the connection with a 400.


Successful response (200)

```json
{
  "message": "Node accepted",
  "node": {
    "id": "<id>",
    "pid": "<pid>",
    "ready": "true|false",
    "payload": "<payload string>",
    "sessionId": "<session id>"
  }
}
```

Client errors (400)

- Missing or empty `SessionId` -> `{ "error": "SessionId is required" }`
- Node not ready -> `{ "error": "Node is not ready" }`
- Node does not exist in Redis (unauthorized) -> `{ "error": "Unauthorized connection to the Celte cluster" }`

Server errors (500)

- Unexpected exceptions -> `{ "error": "<exception message>" }`

Example curl

```bash
curl -X POST http://localhost:1908/server/connect \
	-H 'Content-Type: application/json' \
	-d '{"Id":"session-123-sn-Root-1","Pid":"sn-Root","SessionId":"session-123","Ready":true}'
```

## 3) POST /client/link

Purpose: Connect a client (game runtime) to the correct server node for a given spawner.


Request JSON body (application/json)

```json
{
  "clientId": "<client runtime id>",
  "spawnerId": "<spawner runtime id>",
  "SessionId": "<session id>"
}
```

Notes on fields:
- clientId: Client runtime UUID.
- spawnerId: Spawner runtime UUID. The master looks up which server node is responsible for this spawner, then issues RPCs to connect the client to that node.
- SessionId: Required.


Successful response (200)

```json
{
  "message": "Ok, await further instructions from the assigned node.",
  "SessionId": "<session id>"
}
```

Client and server errors

- If lookup of node from spawner fails a 500 is returned with `{ "message": "Failed to get nodeId from spawnerId." }`.
- If the RPC that connects the client to the node fails, a 500 is returned with `{ "message": "Failed to connect client to the server node." }`.

Example curl

```bash
curl -X POST http://localhost:1908/client/link \
	-H 'Content-Type: application/json' \
	-d '{"clientId":"client-uuid","spawnerId":"spawner-uuid","SessionId":"session-123"}'
```

## 4) POST /redis/clear

Purpose: Remove Redis keys associated with a session. Useful for tests or teardown.

Parameters and body

- The API accepts the session id via query parameter `?SessionId=<id>` or by JSON body containing `SessionId` (or `sessionId`). If neither is provided a 400 is returned.

Example query parameter usage

```
POST /redis/clear?SessionId=session-123
```


Example JSON body usage

```json
{
  "SessionId": "session-123"
}
```


Successful response (200)

```json
{
  "message": "Redis keys for session 'session-123' cleared successfully."
}
```

Client error (400)

- Missing session id -> `{ "error": "Missing required query parameter 'sessionId'" }`

Server errors (500)

- Any exceptions while clearing -> `{ "error": "<exception message>" }`

Example curl (query param)

```bash
curl -X POST "http://localhost:1908/redis/clear?SessionId=session-123"
```

Example curl (JSON body)

```bash
curl -X POST http://localhost:1908/redis/clear \
  -H 'Content-Type: application/json' \
  -d '{"SessionId":"session-123"}'
```

## 5) POST /server/create_session

Purpose: Create resources required for a new session. Concretely it creates a Pulsar namespace for the session.


Request JSON body (application/json)

```json
{
  "SessionId": "<session id>"
}
```


Successful response (200)

```json
{
  "sessionId": "<session id>"
}
```

Client errors (400)

- Missing `SessionId` -> `{ "error": "SessionId is required" }`

Server errors (500)

- Any exception during namespace creation -> `{ "error": "<exception message>" }`

Example curl

```bash
curl -X POST http://localhost:1908/server/create_session \
	-H 'Content-Type: application/json' \
	-d '{"SessionId":"session-123"}'
```

## 6) POST /server/cleanup_session

Purpose: Cleanup all processes and resources for a session. This stops processes that were spawned for the session and deletes the Pulsar namespace.


Request JSON body (application/json)

```json
{
  "SessionId": "<session id>"
}
```

Successful response (200)

```json
{
  "sessionId": "<session id>"
}
```

Client errors (400)

- Missing `SessionId` -> `{ "error": "SessionId is required" }`

Server errors (500)

- Any exception during cleanup -> `{ "error": "<exception message>" }`

Example curl

```bash
curl -X POST http://localhost:1908/server/cleanup_session \
	-H 'Content-Type: application/json' \
	-d '{"SessionId":"session-123"}'
```

## Troubleshooting and tips

- Always set `SessionId` for session-scoped operations. Missing session ids are the most common cause of 400 errors.
- Use `/redis/clear` during automated tests to ensure a clean Redis state between runs.
- Node creation is asynchronous: `/server/create` schedules creation and returns immediately. The created node will later call `/server/connect` when ready.
- Check master logs and Redis keys (the project exposes helpers in `RedisDb`) when debugging node authorization/acceptance issues.
