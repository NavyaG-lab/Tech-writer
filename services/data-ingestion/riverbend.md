---
owner: "#data-infra"
---

# Riverbend

**(a sharded service)**

The Riverbend service is responsible for producing dataset series. It does so by consuming the EVENT-TO-ETL Kafka topic on the shard it deployed on. It serializes its messages and batches them up as .avro files on S3 to make the data suitable for ingestion by Itaipu. The Riverbend then sends a commit message to the NEW-SERIES-PARTITIONS topic. The dataset-name should be in the format series/dataset-name.

Riverbend was previously a shard-aware service on the global shard. This required it to scale according to our entire customer base. Now it is sharded, so we can tune it to work for the max shard size and not need to worry about how large nubank gets.

## See also

* [Code repo](https://github.com/nubank/riverbend)
* [Riverbend CLI](https://github.com/nubank/riverbend-cli)
