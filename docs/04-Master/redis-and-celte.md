### Redis in CELTE

The use of Redis was motivated by the need for a stateless Master. We decided not to use Pulsar for this purpose because it would have interfered with the overall system's performance. Redis is also stateless and uses ***Redis Sentinel*** to ensure high availability of the service (see [Redis Sentinel vs Redis Cluster](https://medium.com/@chaewonkong/redis-sentinel-vs-redis-cluster-a-comparative-overview-8c2561d3168f)).

Redis communications are based on the [Redis JSON protocol](https://redis.io/docs/latest/develop/data-types/json/), which utilizes the `JSON.SET` and `JSON.GET` commands to store and retrieve data from the database.

---

### Notes:
- Redis PORT is `6379`.
- The Redis stack also includes visualization tools like `RedisInsight`, which can be used to monitor the database on port `5540`.
- The use of [Redis for VS Code](https://marketplace.visualstudio.com/items?itemName=Redis.redis-for-vscode) is also recommended to visualize the database content.