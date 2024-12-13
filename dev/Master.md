# Master StateLess Schema

Redis will be use to store and share data between each services,

the data backup system will be base on AOF (Append Only File):
https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/

The data will be store in a JSON format, and will be store in a key-value format.

Cluster will be manage by the Redis Sentinel system:
https://redis.io/topics/sentinel

We decided to use Redis Sentinel instead of Redis Cluster because Redis sentinel is more stable and reliable than Redis Cluster, and it is easier to manage:

https://medium.com/@chaewonkong/redis-sentinel-vs-redis-cluster-a-comparative-overview-8c2561d3168f
