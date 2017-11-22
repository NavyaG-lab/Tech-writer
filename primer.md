# Data Infra Primer

## Big picture
* [Onboarding Berlin](https://docs.google.com/presentation/d/1GD-poZ9GpIVZypFKQ_g_evAgml0Pzio-jBJNgZ-D2MM/edit?ts=5a0566c5#slide=id.g2296c22905_0_0)
* [2017Q4](https://docs.google.com/document/d/1Mkl2EhJa6Zo3jAZBX5s_dWoEzMI9cd_yKIoQN9F48DY/edit?ts=5a0db010)

## Datomic Log overview

![Datomic Fact Structure](http://docs.datomic.com/entities-basics.png)

[Datomic Log Documentation](http://docs.datomic.com/log.html)

A Datomic log has an `EAVT Tx Added` structure, which stands for:
* E = entity (Alessandro)
* A = attribute (Age)
* V = value (27)
* T = time (logical time, t-value from Datomic, monotonically increasing)
* Tx = transaction - a collection of facts that were written atomically
* Added = added or retracted

We rely on the monotonically increasing t-value for the ETL.  We extract from the last t-value we already extracted (extracting via transactions, not datoms - we always keep transactions together) up until the current t-value.

Updates to historical facts (rendering them no longer true) are modeled as a pair of datoms, one that retracts the historically true fact, and one that asserts the fact that is now true, from this t-value forward.

We can traverse a t-value to get the transaction entity, and from the transaction entity we can get to the UTC timestamp and other metadata like `:audit/cid` or `:audit/user`.

In the raw Datomic storage format, attribute names (and enum values) are not stored as strings, but rather as entity ids (longs), and these entity ids can be traversed using `:db/ident` to get to the human readable name of the attribute.

## Correnteza overview [UPDATE REQUIRED]
  * Always-on Datomic log extractor (Clojure service).  Correnteza feeds the "data lake" with Datomic data extracted from lots of different Datomic databases across Nubank.
  * Correnteza has a blacklist of databases that it DOES NOT extract that is stored on DynamoDB.  If a database is not on the blacklist, then it will be automatically discovered and extracted.

## Itaipu overview
  * Basically a DAG within a DAG, where we compute everything from raw -> contract -> dataset -> dimension / fact, declaring the dependencies as inputs to each SparkOp (aka dataset).
  * Raw & contract - see: https://github.com/nubank/itaipu#structure
    * Converts from Datomic's data model to a tabular SQL data model (a subset of what Datomic is capable of)
    * Users generally access contracts as the lowest level of abstraction which already eliminates sharding-related fragmentation
  * Dataset (SparkOp)
    * We want people at Nubank to be able to create new tables as a function of existing tables
    * The contracts are the source for all downstream datasets (and the contract definitions are hardcoded and statically checked within Itaipu)
    * SparkOps are pure - they don't control how they are run, in what order, where their inputs are stored, or where their outputs will be stored.  Itaipu orchestrates this to ensure that dependencies are scheduled in the correct order (and optimized).  Itaipu also manages how many partitions to use when writing dataset output to metapod and S3.
  * Itaipu's mini-DAG
    * Because datasets depend on contracts and other datasets, this produces a directed acyclic dependency graph.  Confusingly, this is a mini-DAG.  The overall DAG is a superset of the Itaipu mini-DAG.
  * Dimensions & fact tables
    * [Kimball principles](dimensional_modeling/kimball.md)
  * Unit testing approach
    * [Unit tests in Itaipu](styleguide.md#unit-test-style) are designed to [test any non-trivial transformation step in isolation](styleguide.md#transform-test-granularity).  Generally we do not test the entire SparkOp on a unit basis.
  * Integration test
    * The Itaipu integration test is able to statically check the entire Itaipu mini-DAG and raise errors if there are any broken column references, incorrect type signatures, unconventional names, etc.  This allows us to catch errors sooner (which is important, because catching an error after the nightly run has been running for 5 hours is very high cost).
  * Workflow for building a new dataset
    * https://github.com/nubank/itaipu#creating-a-new-dataset

## Metapod overview [UPDATE REQUIRED]
  * Keeps track of a containing transaction-id and some other metadata, including the path on S3 and the schema
  * Where transaction id comes from, and multiple transaction ids?
  * How is target date used?

## Aurora jobs overview [UPDATE REQUIRED]
  * [Aurora](http://aurora.apache.org/) is a resource manager that schedules and runs jobs across a [Mesos](http://mesos.apache.org/) cluster.  Some of the jobs that Aurora schedules use Spark (which tends to consume all of the resources on the machine it is running on), but other jobs are written in Python or other languages.
  * [aurora-jobs](https://github.com/nubank/aurora-jobs) stores our job definitions

## Airflow overview [UPDATE REQUIRED]
  * Airflow is a platform to author, schedule, and monitor workflows.  We define our workflow (commonly referred to as  "the DAG" or "the Dagão").  Airflow configuration is done via Python code, and we keep our configuration code in [aurora-jobs](https://github.com/nubank/aurora-jobs/blob/master/airflow/main.py).  
  * When a job is changed on `aurora-jobs`, we need to be careful about how we update the workflow on Airflow because Airflow does not have isolation between runs, so a change to the workflow could affect the *currently running* DAG accidentally if we are not careful.
    1) `aurora-jobs` will build automatically on the Go Pipeline 
    2) We need to manually publish the new version on the [Go Pipeline](https://go.nubank.com.br/go/pipelines/dagao/894/release/1).  Don't do this during an active DAG run.  
    3) We need to click the "refresh" button on the `prod-dagao` DAG on Airflow in order to suck in the new configuration
  * TODO: We need to come up with a safety mechanism to avoid borking a running DAG 
  * [Airflow on Github](https://github.com/apache/incubator-airflow)
  * [Nubank's Airflow server](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao)

## Sabesp overview
  * Command line utility for interacting with data infra ([sample commands](cli_examples.md))

## Capivara-clj overview
  * [Capivara](https://github.com/nubank/capivara) is a Redshift data-loader written in Clojure.  The -clj suffix is there to disambiguate from an older SQL runner project.
  * We load Redshift from avro files that are computed by Itaipu.  While the default dataset storage format for Itaipu is Parquet, we use the "avroize" function to create a copy of the dataset in Avro format, because Redshift can load directly from Avro (and not from Parquet).
  * Capivara runs simultaneously with Itaipu (reacting to committed datasets via SQS messages published by Metapod) and after Itaipu (batch job to do the cutover once everything is ready).  We use SQS for this reactive flow because Metapod is on our production stack (in AWS São Paulo) and Capivara runs in AWS US East (where Redshift runs).

## GO deployment pipeline overview [UPDATE REQUIRED]
  * We use [GoCD](https://www.gocd.org/) for continuous delivery build pipelines
  * [Nubank's GoCD server](https://go.nubank.com.br/go/pipelines)
  * TODO: explain environments (test, devel, prod)
  * TODO: explain build and deploy process for:
    * metapod
    * aurora-jobs
    * capivara
    * itaipu
    * sabesp
    * correnteza
  * TODO: dev workflow overview

## Monitoring run latency / cost [UPDATE REQUIRED]
  * We currently store metrics on how much total CPU time it costs to compute each dataset in the DAG using InfluxDB, and we use Grafana to visualize the data stored there. 
  * [Our ETL-focused Grafana dashboard](https://prod-grafana.nubank.com.br/dashboard/db/etl)

## Metabase [UPDATE REQUIRED]
  * Metabase is an open source frontend for storing and visualizing data warehouse queries
  * [Nubank's Metabase server](https://metabase.nubank.com.br/)
  * Metabase has a broad user base within Nubank and it is fairly easy for non-technical users to write queries and create charts.  Metabase is backed by a PostgreSQL database that stores questions (SQL) and other metadata about the schema of the data warehouse.  Metabase queries Redshift, our data warehouse.  All queries initiated from the Metabase UI have the `metabase` user.  

## Monitoring and caring for DAG runs
  * See: [Monitoring the Nightly Run](monitoring_nightly_run.md)

## Permissions / accounts needed to contribute on data infra [UPDATE REQUIRED]
  * IAM permissions (TODO: which are needed to do common squad tasks)
  * Quay.io permissions needed, and when to do direct quay.io builds
  * Databricks access
  * Datagrip license (or some other SQL client)
  * Redshift user for etl@cantareira-redshift.nubank.com.br (or sao pedro superuser)
  * Metabase admin
  * CircleCI
  * metapod-admin scope (ask on #access-request channel on Slack)
