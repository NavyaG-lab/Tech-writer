---
owner: "#data-infra"
---

# Alph

**(a sharded service)**

The Alph service is responsible for producing dataset series. It does so by consuming the EVENT-TO-ETL Kafka topic on the shard it deployed on. It serializes its messages and batches them up as .avro files on S3 to make the data suitable for ingestion by Itaipu. The Alph then sends a commit message to the NEW-SERIES-PARTITIONS topic. The dataset-name should be in the format series/dataset-name.

Alph substituted the service Riverbend. Riverbend solved the same problem as Alph, however due to its faulty implementation it used to frequently lose events that it was processing.

## See also

* [Code repo](https://github.com/nubank/alph)
