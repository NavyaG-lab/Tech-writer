---
owner: "#data-infra"
---

# Metapod

## Metapod overview

* [Metapod](https://github.com/nubank/metapod) is a Clojure service with a Datomic database that stores metadata about our data, including when any given dataset was computed, where is was stored on S3 (and with which partitions), the schema, which grouping "transaction" it is part of, etc.
  * Metapod is a normal service deployed in sa-east-1 (Sao Paulo) in production in the `global` prototype (as opposed to in a specific shard, for example). That means that after a pull request is merged to master, it will build and then go to staging and then prod. You can check what version of metapod is deployed in production using `nu ser versions metapod`, and you can see whether the service is healthy via `nu ser curl GET global metapod /ops/health`.
  * Metapod also produces Kafka messages when a dataset is committed (via a proxy service called `veiga`), allowing downstream services to use them, e.g., [Monsoon](https://github.com/nubank/monsoon) subscribes to such events to load the Parquet datasets into Google Big Query.
  * To know how to retract portions of a Metapod transaction (for example, to recompute a dataset), [please consult the section on how to remove bad data from Metapod in the ops how to guide.](https://github.com/nubank/data-infra-docs/blob/master/ops_how_to.md#removing-bad-data-from-metapod)

## See also
  
* [What is a transaction?](../../glossary.md#transaction)
* [GraphQL Clients](../../tools/graphql_clients.md)
* [How to copy a transaction](../../how-tos/metapod.md)
