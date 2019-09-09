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

### Finding out which dataset series should be compacted

Even though the problem is on having larger and fewer partition files, calculating how many of these exist requires running a databricks notebook, which takes some time.
A good proxy for finding out which dataset series are "too big" is looking how many datasets they have.

This light weight [mordor query](https://backoffice.nubank.com.br/eye-of-mauron/#/s0/mordor/5ccab752-2e3d-40c9-8a76-543ed5ed5ee2) get us the largest dataset series.

You can order by size by clicking in the title of the column `(count ?dataset)`.
An ok heuristic is to run compaction for all dataset series that have more than 30k datasets.

Another way is to run this notebook code:

```python
from metapod_client import helper
from metapod_client import metapod_factory
from metapod_client.client import Client
from mypy_extensions import TypedDict
from typing import List

DatasetsCountInSeries = TypedDict("DatasetsCountInSeries", {
                                  'series': str, 'datasets_count': int})


def get_client(env, country):
    return helper.get_metapod_client(env=env, country=country, service="airflow")


def get_local_client(env, country):
    system = metapod_factory.token_system(env, country, "metapod-client")
    return Client(system['config'], system['http'], system['auth'].service)


def get_num_requests_in_series(env, country="br") -> List[DatasetsCountInSeries]:
    query = """
    query GetDatasetSeries    {
        allDatasetSeries {
        edges {
            name
            numDatasets
        }
      }
    }
    """
    mc = get_local_client(env, country)
    response = mc._graphql_request(payload=query)

    return response


bla = get_num_requests_in_series("prod")['allDatasetSeries']['edges']
sortedd = sorted(bla, key=lambda item: item['numDatasets'] or 0)
top10_to_compact = list(reversed(sortedd))[:10]

[print(i['name']) for i in top10_to_compact]
```

And you can check the size directly via this metapod query:

```
{
    datasetSeries(datasetSeriesName: "<SERIES_NAME>") {
    name
    numDatasets
    datasets {
      id
    }
  }
}
```

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
And also the task page in aurora: https://cantareira-stable-mesos-master.nubank.com.br:8080/scheduler/jobs/prod/compaction-<SERIES_NAME_WITHOUT_SERIES_PREFIX>

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

[1]: ./dataset-series.md
[2]: https://github.com/nubank/riverbend
[3]: https://github.com/nubank/itaipu
[4]: https://github.com/nubank/metapod
[5]: ../glossary.md#transaction
