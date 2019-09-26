# Rationale

There is no document so far that details out the flow of control that makes
itaipu run. Understanding this by traversing the code is hard as many pieces of
the code reference several other pieces and it is easy to get lost in this
complexity. So this document provides a thread of Ariadne through the main
control flow of itaipu/common-etl. It provides a base from which one can dive
into certain aspects more deeply while keeping a sense of where you are in the
grand scheme of things.

# The flow of control

### Glossary

* **itaipu-path**: `github.com/nubank/itaipu/src/main/scala/etl`
* **common-etl-path**: `github.com/nubank/itaipu/common-etl/src/main/scala/common_etl/`

## The outside world

TO BE DONE

* airflow (aurora-jobs repo)
* sabesp

## itaipu

1. `[itaipu-path]/itaipu/Itaipu.scala`: `main` is the entry-point and it calls
   `Runner.main`. It also provides functionality to build the `opsToRun` (see
   details [here](#how-the-`opsToRun`-are-created).
2. `[itaipu-path]/runner/Runner.scala`: `main` uses `CLI` to parse the config
   that is sent from the outside world. It then creates all of the services
   around itaipu that it has to interact with:
   1. httpClient - used by everything that follows to take care of the http
      communication.
   2. curvaDeRio - http service to ingest non-datomic data into our ETL data
      lake. (Works via `EVENT-TO-ETL` kafka topic).
   3. metapod - service that keeps metadata about transactions and committed
      datasets.
   4. ouroboros - metadatastore like metapod but for dataset series
   5. correnteza - our datomic log extractor.
   6. spark - spark session (driver context + cluster) to run the data
      transformations
   Subsequently, the runner creates transaction information and finally an
   `ETLExecutor`, injected with the transaction information and all the created
   services to the executor. It then lets the executor run and raises if the
   results are not all successes.

## common-etl: Executing the sparkops

3. `[common-etl-path]/operator/ETLExecutor.scala`:
   1. Calls `SparkPipelineEvaluator.[defaultStepsBuilder/evaluator]` to create
      all the steps that need to be done for each SparkOp. See details of steps
      [here](#evaluator-steps).
   2. Grabs the transaction, commits a few empty `RootOps` datasets.
   3. Creates an `OpRunner` and runs it on the `opsToRun`.
4. `[common-etl-path]/operator/OpRunner.scala`:
   1. Does a topological sort on the `opsToRun` (see details [here](#graphops). Parallelizes execution into
      futures (dependencies are futures within futures and so forth).
   2. Runs them all using the `SparkPipelineEvaluator.evaluator` function.

## How the `opsToRun` are created

Starts in the beginning of the Runner (step 2 in [itaipu](#itaipu)).

1. `[itaipu-path]/itaipu/CLI.scala`: Basically there are many ways to filter
   the entire set of ops down to those one wants:
   1. `filter`: Give a whitelist of ops to run
   2. `filter-by-prefix`: Filter by prefix in the name (e.g. `series-contract`)
   3. `filter-by-series-types`: Types are: `Manual, Archived, Events`
   4. `filter-by-modes`: Filter based on OpModes: `ServingLayer, Archive,
      Warehouse`
   5. `filter-out`: A blacklist of ops not to run
   6. `filter-out-prefix`: Remove ops by prefix in the name
2. If these options are set, they are used by the runner. During the creation
   of the transaction, `opsForTransactionCreation` function from the `config`
   object in `CLI` is used to call `itaipu/Itaipu.opsToRun`. This, in turn,
   calls `[common-etl-path]/DAG.scala` which is used to create a `Seq` of all
   sparkOps. This ensures that the created transaction object knows about all
   the datasets that should be committed in the end.
3. This transaction object is passed to the `ETLExecutor` along with
   `config.opsToRun`, which builds a list of all ops once again and then uses
   the filters passed to it to filter the list down to what should run. We run
   multiple sub-dags (see airflow for definition of those) in order to
   parallelize or split the entire huge dag sensibly.

## Evaluator steps

Starts in the beginning of the Executor (step 1 in
[common-etl](#common-etl:-executing-the-sparkops)).

The `SparkPipelineEvaluator` defines a series of steps that are run in sequence
to process a sparkOp. They each have a `shoudRun` condition to see if they are
necessary and a `run` method which calls a `sparkRun` method to tell spark what
to do. The steps are as follows:

01. Configure - configures spark
02. MergeParquetSchema - Sets sparks sql context MergeParquetSchema to `true`
    for certain dataset series.
03. ReadInputs - Reads inputs from s3 after asking metapod where they are
04. SetShufflePartitions - Finds out how many partitions to use based on
    preconfigured values or heuristics. Partitions set here are for shuffling.
    So only for joins and aggregations, this partitioning is really taking
    effect.
05. CoerceInputs - Cast the correct datatypes based on the logical types
    defined in the schema. If no schema is defined, this does the same as step
    8 does for sparkOps with declared schema: Coerces precision/scale for
    floating point numbers.
06. PrepareExecution - Runs the transformations defined in the sparkOps.
07. PrepareSchema - Generate a Schema if the SparkOp declares one. Validates
    the schema as well.
08. CoerceDecimalScale - Coerce floating point values to a specific
    precision/scale.
09. CoalesceOrRepartition - Repartitions the _output_ (this step always
    executes for real datasets containing data)
10. EstimateIdealPartitionNumber - Repartitions again. Only runs if config is
    set to run this. Has some heuristics to get the ideal number of partitions
    to write output to s3.
11. Persist - Save to a random place in s3. (And remember where, of course)
12. CheckIntegrity - If defined in config, run integrity checks (such as
    Uniquiness, NonNull,...)
13. VerifyPartitions - Verify that data were written in the correct amount of
    partitions.
14. CheckIfEmpty - Check if the data are empty. If so, sets partitions to
    `None`.
15. Commit - Commit in metapod. Schema info, storage location, transaction
    id...

## GraphOps

Step 4.1 in [common-etl](#common-etl:-executing-the-sparkops).

Uses the `scalax.collection.Graph` library to construct a DAG from all SparkOps
and run a topological sorting (As a side-effect perk, this also checks that the
graph is indeed acyclic) and flattening the result to a list where nodes within
a layer are sorted alphabetically in order to render reproducible results.
