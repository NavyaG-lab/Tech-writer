# Data Infra Primer

## Big picture
* []Onboarding Berlin](https://docs.google.com/presentation/d/1GD-poZ9GpIVZypFKQ_g_evAgml0Pzio-jBJNgZ-D2MM/edit?ts=5a0566c5#slide=id.g2296c22905_0_0)
* [2017Q4](https://docs.google.com/document/d/1Mkl2EhJa6Zo3jAZBX5s_dWoEzMI9cd_yKIoQN9F48DY/edit?ts=5a0db010)

## Datomic Log overview

![Datomic Fact Structure](http://docs.datomic.com/entities-basics.png)

Documentation: http://docs.datomic.com/log.html

A Datomic log has EAVT Tx Added structure
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
  * Always-on log extractor (Clojure service)

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
  * aurora schedules mesos jobs
  * aurora-jobs stores our job definitions
  
## Airflow overview [UPDATE REQUIRED]
  * Scheduler (reads from aurora-jobs)

## Sabesp overview
  * Command line utility for interacting with data infra ([sample commands](cli_examples.md))

## Capivara-clj overview [UPDATE REQUIRED]
  * Redshift data-loader (from avro files to populated Redshift tables)
  * Runs during (reacting to finished datasets via SQS from Metapod) and after Itaipu (batch job to do the cutover once everything is ready)

## Deployment pipeline [UPDATE REQUIRED]
  * Environments (test, devel, prod)
  * Clusters (stable, test, dev, dev2, alpha) - only one DAG should be run per cluster at a time given naive resource management
  * Process for metapod (Cantareira Waves)
  * Process for aurora jobs, itaipu, etc (Dagao)
  * Dev workflow for go pipeline

## Monitoring run latency / cost [UPDATE REQUIRED]
  * https://prod-grafana.nubank.com.br/dashboard/db/etl
  
## Metabase [UPDATE REQUIRED]

## Monitoring and caring for DAG runs [UPDATE REQUIRED]
  * See: https://github.com/nubank/itaipu/wiki/Monitoring-the-Nightly-Run
  * Process for checking if a run failed and why (on test, on prod). When to use aurora vs. mesos
    * Splunk dashboard: https://nubank.splunkcloud.com/en-US/app/search/etl_monitoring
    * Test
      * Aurora: https://cantareira-test-mesos-master.nubank.com.br:8080/scheduler/jobs
      * Mesos: https://cantareira-test-mesos-master.nubank.com.br
    * Prod
      * Aurora: https://cantareira-stable-mesos-master.nubank.com.br:8080/scheduler/jobs/prod/dagao
      * Mesos: https://cantareira-stable-mesos-master.nubank.com.br
    * Dev
      * Dev 1
        * Aurora: https://cantareira-dev-mesos-master.nubank.com.br:8080/
        * Mesos: https://cantareira-dev-mesos-master.nubank.com.br
      * Dev 2
        * Aurora: https://cantareira-dev2-mesos-master.nubank.com.br:8080/
        * Mesos: https://cantareira-dev2-mesos-master.nubank.com.br
  * Process for who should restart what under what circumstances, and how
  * When to scale up / down
  * What to run only at night vs. what's ok during the day (e.g., redshift load on prod)
  * What's critical to run and deliver by when (e.g., goldman sachs report)
  * Debugging Redshift load failures
    * When you see an error on Splunk like `- ERROR #XX000 Load into table 'temp_savings_accounts__savings_accounts' failed. Check 'stl_load_errors' system table for details. (addr="10.130.30.176:5439")`
    * Use DataGrip to connect to Redshift
      * Your credentials are stored on S3: `aws s3 cp s3://nu-secrets/redshift/your.name/credentials.json .`
      * host: `cantareira-redshift.nubank.com.br`
      * db: `etl`
    * Run this query: `select * from stl_load_errors order by starttime desc limit 100;`
  * Filtered runs

## Permissions / accounts needed to contribute on data infra [UPDATE REQUIRED]
  * IAM permissions (TODO: which are needed to do common squad tasks)
  * Quay.io permissions needed, and when to do direct quay.io builds
  * Databricks access
  * Datagrip license (or some other SQL client)
  * Redshift user for etl@cantareira-redshift.nubank.com.br (or sao pedro superuser)
  * Metabase admin
  * CircleCI
  * metapod-admin scope (ask on #access-request channel on Slack)
