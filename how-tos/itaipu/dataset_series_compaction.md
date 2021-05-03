---
owner: "#data-infra"
---

# Dataset Series Compaction

Dataset series compaction is a mechanism developed to optimize the
processing of dataset series in [Itaipu][3].  It essentially consists
of code which groups pieces of data in a dataset series into bigger
partition files in S3, making it more efficient for the entire dataset
series to be processed by Itaipu using Spark. For more information on
dataset series, see [here][1].

## Problem statement

Due to the nature of batching incoming data into smaller pieces,
encoded in [Alph][2], each batch of data ends up in a dataset with one
single partition (an Avro file in S3), and [Alph][2] appends it to
dataset series, via [Ouroboros][4].

Each file (called a 'partition') is rather small, and as time went by,
and more data was appended to dataset series, it became very
inefficient to:

- fetch all this meta data from Ouroboros via HTTP (we bumped into timeouts when executing the HTTP requests due to too much data)
- read and process the data, because Spark performs better when there are fewer and larger files, to be distributed across executors.

## Solution

The solution we implemented was to write a batch job which reads all
data from a dataset series, and re-partitions the resulting data frame
to create larger and fewer partition files in S3. The batch job
updates the metadata of the dataset series in [Ouroboros][4], so it
can hand out the paths to the compacted files, instead of the
un-compacted ones. The compacted files are written in the Parquet
format, which improves the performance of Spark jobs reading
them. This is a high level description of the process. For more
details on how compaction works in Ouroboros, take a look at the
[record series compaction
ADR](https://github.com/nubank/ouroboros/blob/master/doc/adr/0003_record_series_compaction.md).

## Compaction DAGs

The compaction of dataset series is an automated process which runs
daily at 15h ATC (Aurora Time Zone) scheduled by Airflow. We run
compaction on all dataset series types (archived, events and manual)
and have a DAG for each country. The following table links to the DAGs
on Airflow and to the Aurora scheduler being used for each country:

| Airflow Production      | Aurora Production       | Airflow Staging         | Aurora Staging          |
|-------------------------|-------------------------|-------------------------|-------------------------|
| [Brazil][AIR-BR-PROD]   | [Brazil][AUR-BR-PROD]   | Brazil n/a              | [Brazil][AUR-BR-STAG]   |
| [Colombia][AIR-CO-PROD] | [Colombia][AUR-CO-PROD] | [Colombia][AIR-CO-STAG] | [Colombia][AUR-CO-STAG] |
| [Data][AIR-DATA-PROD]   | [Data][AUR-DATA-PROD]   | [Data][AIR-DATA-STAG]   | [Data][AUR-DATA-STAG]   |
| [Mexico][AIR-MX-PROD]   | [Mexico][AUR-MX-PROD]   | [Mexico][AIR-MX-STAG]   | [Mexico][AUR-MX-STAG]   |

[AIR-BR-PROD]: https://airflow.nubank.com.br/admin/airflow/graph?dag_id=dataset-series-compaction-br

[AIR-CO-PROD]: https://airflow.nubank.world/admin/airflow/graph?dag_id=dataset-series-compaction-co
[AIR-CO-STAG]: https://staging-airflow.nubank.world/admin/airflow/graph?dag_id=dataset-series-compaction-co

[AIR-DATA-PROD]: https://airflow.nubank.world/admin/airflow/graph?dag_id=dataset-series-compaction-data
[AIR-DATA-STAG]: https://staging-airflow.nubank.world/admin/airflow/graph?dag_id=dataset-series-compaction-data

[AIR-MX-PROD]: https://airflow.nubank.world/admin/airflow/graph?dag_id=dataset-series-compaction-mx
[AIR-MX-STAG]: https://staging-airflow.nubank.world/admin/airflow/graph?dag_id=dataset-series-compaction-mx

[AUR-BR-PROD]: https://cantareira-stable-mesos-master.nubank.com.br:8080/scheduler/jobs/prod/dataset-series-compaction-br
[AUR-BR-STAG]: https://cantareira-dev-mesos-master.nubank.com.br:8080/scheduler/jobs/staging/dataset-series-compaction-br

[AUR-CO-PROD]: https://prod-foz-aurora-scheduler.nubank.world/scheduler/jobs/prod/dataset-series-compaction-co
[AUR-CO-STAG]: https://staging-foz-aurora-scheduler.nubank.world/scheduler/jobs/staging/dataset-series-compaction-co

[AUR-DATA-PROD]: https://prod-foz-aurora-scheduler.nubank.world/scheduler/jobs/prod/dataset-series-compaction-data
[AUR-DATA-STAG]: https://staging-foz-aurora-scheduler.nubank.world/scheduler/jobs/staging/dataset-series-compaction-data

[AUR-MX-PROD]: https://prod-foz-aurora-scheduler.nubank.world/scheduler/jobs/prod/dataset-series-compaction-mx
[AUR-MX-STAG]: https://staging-foz-aurora-scheduler.nubank.world/scheduler/jobs/staging/dataset-series-compaction-mx

The DAG for Brazil should be disabled on the Airflow installation in
the Data account, and the DAGs for Colombia, Data and Mexico should be
disabled on the Brazilian Airflow installation. The compaction job
will fail on startup, if you try to run compaction on an invalid
infrastructure and country combination (compacting Brazilian event
dataset series in the Data account for example).

## AWS accounts

At Data Infra we run Airflow, Aurora and the Spark clusters in 2
different AWS accounts, the Brazilian AWS account and the Data AWS
account. This is due to historical reasons and also the fact that we
have a lot more data in Brasil than in the other countries. The
following table gives an overview for which series are computed in
which account.

| Source   | Archived Series | Event Series | Manual Series |
|----------|-----------------|--------------|---------------|
| Brasil   | AWS Data        | AWS Brazil   | AWS Brazil    |
| Colombia | AWS Data        | AWS Data     | AWS Data      |
| Data     | AWS Data        | AWS Data     | AWS Data      |
| Mexico   | AWS Data        | AWS Data     | AWS Data      |

## Rolling back a compaction

A compaction of a dataset series can be rolled back. This can be
useful in case something went wrong during the compaction process (a
bug in the compaction code for example, or if we accepted a faulty
deletion request and we need to restore the original data). The
rollback of a compaction changes the metadata of a dataset series to
the state it has been in before applying the compaction. More details
about this process can be found in the [compaction rollback
ADR](https://github.com/nubank/ouroboros/blob/master/doc/adr/0004_compaction_rollback.md). In
order to rollback a compaction the following requirements have to be
met:

- You have a compaction id at hand (you can find it in the logs of the compaction job on Aurora)
- The compaction to rollback is the most recent one
- The compaction hasn't been rolled back already
- The inputs of the compaction have not been deleted

If those requirements are met, the following command should rollback
the compaction with the given id:

```shell
export COMPACTION_ID="11111111-1111-1111-1111-111111111111"
nu ser curl DELETE global ouroboros /api/compactions/$COMPACTION_ID \
   --cid COMPACTION.ROLLBACK \
   --country br \
   --env staging
```

If the compaction you want to roll back is not the most recent one,
you need to rollback all compactions that have been applied after it,
in reverse order. First the most recent compaction, then the one
before, etc.

**Important**: If you rollback a compaction that has applied deletions
from Lethe (you can find this out by searching for `Deletion groups
without failures` in the Aurora job logs of the compaction), please
follow the [Rollback Deletion Group
guide](https://github.com/nubank/lethe/blob/master/doc/adr/0004_rollback_deletion_group.md)
instead. Deletions are rolled back together with the compaction that
applied them and need eventually be re-applied again.

## Manually running compaction

Compaction can be run manually via sabesp. The sabesp command scales
the cluster up, runs the compaction job and scales the cluster down
again. The command supports running compaction on all series at once,
on a list of provided series names, or on a list of series types.

- The `--dry-run` runs compaction, but doesn't re-write the meta data in Ouroboros. Useful for testing.
- The `--enable-deletion` option applies deletions from Lethe while running compaction.
- The `--series-to-compact` option can be used to run compaction on the given list of dataset series.
- The `--series-types` option can be used to run compaction on the dataset series of the given types.

#### Examples

##### Manually running compaction in staging

Compact the dataset series with the name `series/example` for Brazil
in staging on the Brazilian AWS account.

```shell
nu-br datainfra sabesp -- --aurora-stack=cantareira-dev \
        jobs dataset-series-compaction \
        --itaipu=ITAIPU_VERSION \
        --scale=$SCALE_VERSION \
        --series-to-compact=series/example \
        staging BR s3a://nu-spark-metapod-permanent-1 s3a://nu-spark-metapod-ephemeral-1 1
```

Compact the dataset series with the name `series/example` for
Colombia, Data and Mexico in staging on the Data AWS account.

```shell
nu-data datainfra sabesp -- --aurora-stack=staging-foz \
        jobs dataset-series-compaction \
        --itaipu=ITAIPU_VERSION \
        --scale=$SCALE_VERSION \
        --series-to-compact=series/example \
        staging CO,MX,DATA s3a://nu-spark-metapod-permanent s3a://nu-spark-metapod-ephemeral 1
```

##### Manually running compaction in production

Compact the dataset series with the name `series/example` for Brazil
in production on the Brazilian AWS account.

```shell
nu-br datainfra sabesp -- --aurora-stack=cantareira-stable \
        jobs dataset-series-compaction \
        --itaipu=ITAIPU_VERSION \
        --scale=$SCALE_VERSION \
        --series-to-compact=series/example \
        prod BR s3a://nu-spark-metapod-permanent-1 s3a://nu-spark-metapod-ephemeral-1 1
```

Compact the dataset series with the name `series/example` for
Colombia, Data and Mexico in production on the Data AWS account.

```shell
nu-data datainfra sabesp -- --aurora-stack=prod-foz \
        jobs dataset-series-compaction \
        --itaipu=ITAIPU_VERSION \
        --scale=$SCALE_VERSION \
        --series-to-compact=series/example \
        prod CO,MX,DATA s3a://nu-spark-metapod-permanent s3a://nu-spark-metapod-ephemeral 1
```

[1]: ../../data-users/etl_users/dataset_series.md
[2]: https://github.com/nubank/alph
[3]: https://github.com/nubank/itaipu
[4]: https://github.com/nubank/ouroboros
[5]: ../../glossary.md#transaction
