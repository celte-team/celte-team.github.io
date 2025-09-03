# How to build a game

CELTE works the following way:
- Kubernetes hosts your network backend (Apache pulsar and Redis).
- A Master server serves as an API to use CELTE features such as creating servers, connecting a client to the network, etc.
- Game servers using CELTE systems are created by the master server when needed.
- A lobby bridges clients and the master server.

For a fully funcional game, you will need to develop a game, but also to create a lobby server and make sure that the other services from CELTE are up and running. You need to code yourself `the game` and `the lobby`, while `the master` and `the network backend` are operational and only need to be hosted by your preferred host provider.
