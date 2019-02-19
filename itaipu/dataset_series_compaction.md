# Dataset Series Compaction

Dataset Series Compaction is a mechanism developed to optimize the processing of Dataset Series in [Itaipu][3].
It essentially consists of code which groups pieces of data in a Dataset Series into bigger partition files in S3, making it more efficient for the entire Dataset Series to be processed by Itaipu using Spark.

For more information on Dataset Series, see [here][1].

## Problem statement

Due to the nature of batching incoming data into smaller pieces, encoded in [riverbend][2], each batch of data ends up in a dataset with one single partition (an Avro file in S3), and [riverbend][2] appends it to Dataset Series, via [metapod][4].

Each file (called a 'partition') is rather small, and as time went by, and more data was appended to Dataset Series, it became very inefficient to:

 - fetch all this data from metapod via HTTP (we bumped into timeouts when executing the HTTP requests due to too much data)
 - read and process the data, because Spark performs better when there are fewer and larger files, to be distributed across executors.

## Solution

The solution we implemented was to write a batch job which reads all data from a Dataset Series, and re-partitions the resulting DataFrame to create larger and fewer partition files in S3. It then commits those partitions into a new dataset in a new [metapod transaction][5], and replaces the original datasets in the Dataset Series with this new aggregated dataset, which has larger partition files. These files are also written in Parquet format, further improving performance of Spark jobs which will read them (namely `itaipu-dataset-series`).

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

Then, use the following command (connected to the VPN), replacing `DATASET_SERIES_NAME`:

```
curl https://airflow.nubank.com.br/api/experimental/dags/dataset-series-compaction/dag_runs \
  -d '{"conf":"{\"compact_dataset_series\":\"DATASET_SERIES_NAME\"}"}'
```

You can check the progress in the DAG page: https://airflow.nubank.com.br/admin/airflow/graph?dag_id=dataset-series-compaction
And also the task page in aurora: https://cantareira-stable-mesos-master.nubank.com.br:8080/scheduler/jobs/prod/dataset-series-compaction

#### Unapply compactions

In case something goes wrong when reading the data back from its compacted state, we can always "unapply" the compactions, restoring the original datasets back into the Dataset Series. To do that, use the `UnapplyCompaction` mutation, available through the GraphQL interface in [metapod][4].

1. Get the compaction ID

**Note:** to perform those queries, you can use Sonar-js: https://backoffice.nubank.com.br/sonar-js/#/sonar-js/graphiql

You will need the compaction ID that resulted in the compacted dataset, in order to unapply it.
To get it, you can include a `compaction` attribute when querying for datasets in a Dataset Series.

Replace `DATASET_SERIES_NAME` in the query below:

```
query GetDatasetSeries($datasetSeriesName: String) {
  datasetSeries(datasetSeriesName: $datasetSeriesName) {
    name
    datasets(compactedStatus: COMPACTED) {
      name
      compaction {
        id
        appliedAt
        status
      }
    }
  }
}
```
```
{
  "datasetSeriesName": "DATASET_SERIES_NAME"
}
```

2. Unapply the compaction, replacing `COMPACTION_UUID`:

```
mutation UnapplyCompaction($input: UnapplyCompactionInput!) {
  unapplyCompaction(input: $input) {
    id
    appliedAt
    datasetSeriesName
    status
  }
}
```
```
{
  "input": {
    "compactionId": "COMPACTION_UUID"
  }
}
```

[1]: ./dataset-series.md
[2]: https://github.com/nubank/riverbend
[3]: https://github.com/nubank/itaipu
[4]: https://github.com/nubank/metapod
[5]: ../glossary.md#transaction