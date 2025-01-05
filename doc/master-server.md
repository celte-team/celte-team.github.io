# Master

The **Master** is a stateless service written in C# that is responsible for linking the **client** to the appropriate **Server Node (SN)** during a spawn event, as the client cannot determine its spawn position or the IP address of the SN.

The Master stores the list of active SNs and connected clients in **Redis**.

It depends on **Pulsar** for communication with SNs and clients, and **Redis** to store the SN and client lists, ensuring the service remains stateless. All predefined "grapes" are stored in a configuration file named `master-config.yaml`:

```yaml
grapes:
    - LeChateauDuMechant
    - LeChateauDuGentil
    ...
```

### How It Works

1. **When a New SN Spawns**
   - The new SN sends a message to the Pulsar topic `master.hello.sn`.
   - The Master adds the new SN to the Redis list of active SNs.

2. **When a New Client Spawns**
   - The client sends a message to the Pulsar topic `master.hello.client`.
   - The Master requests one of the SNs to compute the client’s spawn position and assign a chunk using the RPC `master.rpc`.
   - Based on the response, the Master redirects the client to the appropriate SN.