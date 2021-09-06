---
owner: "#data-infra"
---

# Serving layer

* Once a dataset is processed by itaipu, its metadata is committed to metapod.
* Every dataset that gets committed to metapod is sent to tapir, and tapir starts scheduling work in its queue, for the datasets that are configured to be served through the serving layer.
* Each dataset is composed of several files on S3 and each file is called a partition.
* Tapir schedules one job for each partition of each committed dataset that goes to the serving layer. These jobs for partitions are put into tapir's queue, which is a Kafka topic divided 64 ways, so there can be 64 partitions processed at the same time.
* Tapir itself does the work of processing those partitions, and we can have at maximum capacity 32 instances of tapir running at the same time (it auto-scales automatically according to CPU utilization, within certain limits).

Here is a detailed documentation on [Serving Layer](https://github.com/nubank/data-platform-docs/blob/master/infrastructure/data-infra/serving_layer.md).
