---
owner: "#data-infra"
---

# Dataset Series Compaction

Dataset Series Compaction is a mechanism developed to optimize the processing of Dataset Series in [Itaipu][3].
It essentially consists of code which groups pieces of data in a Dataset Series into bigger partition files in S3, making it more efficient for the entire Dataset Series to be processed by Itaipu using Spark.

For more information on Dataset Series, see [here][1].

## Problem statement

Due to the nature of batching incoming data into smaller pieces, encoded in [alph][2], each batch of data ends up in a dataset with one single partition (an Avro file in S3), and [alph][2] appends it to Dataset Series, via [metapod][4].

Each file (called a 'partition') is rather small, and as time went by, and more data was appended to Dataset Series, it became very inefficient to:

- fetch all this data from metapod via HTTP (we bumped into timeouts when executing the HTTP requests due to too much data)
- read and process the data, because Spark performs better when there are fewer and larger files, to be distributed across executors.

## Solution

The solution we implemented was to write a batch job which reads all data from a Dataset Series, and re-partitions the resulting DataFrame to create larger and fewer partition files in S3. It then commits those partitions into a new dataset in a new [metapod transaction][5], and replaces the original datasets in the Dataset Series with this new aggregated dataset, which has larger partition files. These files are also written in Parquet format, further improving performance of Spark jobs which will read them (namely `itaipu-dataset-series`).

### Finding out which dataset series should be compacted

The candidate dataset-series' for compaction are the ones with large number of partition files. However, it is time-consuming to calculate how many partitions exist for a series, and it requires running a Databricks notebook. Instead, a good proxy for the size of a dataset-series is the number of datasets they contain.

This light-weight [Mordor query](https://backoffice.nubank.com.br/eye-of-mauron/#/s0/mordor/5ccab752-2e3d-40c9-8a76-543ed5ed5ee2) lists the size of dataset-series by number of datasets. You can order by the number of datasets by clicking on the column header `(count ?dataset)`.

An alternative to using the Mordor query is to using this `nu` command:

```
nu datainfra series-to-compact --cutoff 10000 |sort
```

*A heuristic is to run compaction for all dataset-series' that have more than 10k datasets.*



### Starting a compaction run

Currently, there is an airflow DAG which will:

- scale up the necessary EC2 machines
- run the compaction code in Itaipu, which will:
  - read data from the Dataset Series
  - re-partition data into larger files
  - commit a new dataset in a new [metapod transaction][5]
  - detach original datasets and append the new one to the Dataset Series (atomically, implemented in [metapod][4])
- terminate the EC2 machines

This DAG is parameterized, which means it requires extra parameters to be passed in to its execution. Currently, that's only supported via a cURL call to its API (clicking the 'Play' button in the airflow UI will not pass the correct parameters). To execute it, first get the name of the desired Dataset Series to compact (e.g. `series/dataset-partitions`).

Then, use the following command, replacing `DATASET_SERIES_NAME`:

```
nu datainfra compaction --itaipu-version <ITAIPU_VERSION> DATASET_SERIES_NAME
```

You can check the progress in the [compaction DAG page](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=dataset-series-compaction)
And also the task page in aurora: https://cantareira-stable-aurora-scheduler.nubank.com.br:8080/scheduler/jobs/prod/compaction-<SERIES_NAME_WITHOUT_SERIES_PREFIX>

#### Running a compaction during a run

One of the more common reasons for wishing to compact a series is when this series is failing to compute in the daily run due to metapod timing out when requesting the series ids.

When running a compaction in this context, extra care should be taken to avoid inconsistent state of the series raws. This is because series raws are not committed all at once, but rather per schema/format; meaning that if a compaction is run while a node is querying the data, the final state of the raws may contain both the original avros and the compacted parquets.

The recommended approach for compacting a series that's midway through being computed is:

- Ensure the relevant dataset-series job is not running (beware that dowstream nodes can also compute this series)
- Start the compaction:

```
nu datainfra compaction --itaipu-version <ITAIPU_VERSION> DATASET_SERIES_NAME
```

- Query for the committed series-raws ( by querying for committed datasets in the transaction and searching the output for your series' name)

```
{
  transaction(transactionId: "<transaction-id>") {
    datasets(committed: ONLY_COMMITTED) {
      id
      name
    }
  }
}
```

* retract them using:

```
nu ser curl POST global metapod /api/migrations/retract/committed-dataset/<dataset-id>
```

* Wait for the compaction to be fully applied:
  * Wait for the compaction job to be finished (you can check in aurora, it will be under `compaction-<series-name>`)
  * Waiting for all lag on Metapod's`APPLY-COMPACTION`topic to be resolved, for example using [this grafana dashboard](https://prod-grafana.nubank.com.br/d/000000222/kafka-lags-topic-view?orgId=1&refresh=1m&var-PROMETHEUS=prod-thanos&var-GROUP_ID=METAPOD-COMPACTION&var-TOPIC=APPLY-COMPACTION&var-PROTOTYPE=All&var-STACK_ID=v)
* start the node again

#### Unapply compactions

In case something goes wrong when reading the data back from its compacted state, we can always "unapply" the compactions, restoring the original datasets back into the Dataset Series. To do that, use the admin endpoint in [metapod][4].

1. Get the transaction ID generated from the compaction run you wish to revert. To get this info, you can for example query Metapod with:

   ```graphQL
   query GetDatasetSeries {
     datasetSeries(datasetSeriesName: "series/customer-tracking") {
       name
       datasets(compactedStatus: COMPACTED) {
         id
         compaction {
           id
           transaction {
             id
             startedAt
           }
         }
       }
     }
   }
   ```


2. Call the admin endpoint:

```
nu ser curl PUT global metapod /api/migrations/transaction/TRANSACTION_ID/unapply-compactions
```

[1]: /data-users/etl_users/dataset_series.md
[2]: https://github.com/nubank/alph
[3]: https://github.com/nubank/itaipu
[4]: https://github.com/nubank/metapod
[5]: ../glossary.md#transaction
