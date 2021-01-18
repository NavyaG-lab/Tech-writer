---
owner: "#data-infra"
---

# SparkOp State Machine

In order to describe possible states of a given SparkOp, we need to make explicit the possible types of SparkOps on Itaipu:
- Regular SparkOps
- CopyOps
- Model
- Root Dataset

Each one of those SparkOp types have different states, as `CopyOp`, `Model` and `Root Datasets` are
specializations of the `Regular SparkOp`. For the sake of simplicity, we describe here the states
and transitions of a `Regular SparkOp`, since it is the most common kind of entity used on our jobs.

Additionally, in this modelling, we define `state` as a point on a SparkOp execution were we can map
an action meaningful for those who have an understanding of Itaipu internals. We plan to project a
simplification of these states and its transitions for other Itaipu users.

## State machine diagram

![SparkOp State Machine](../../../images/DataInfraArchitecture.png)

## State description

**Created:** Op selected by CLI filter

**Waiting:** Op waiting to be executed => https://github.com/nubank/itaipu/blob/master/common-etl/src/main/scala/common_etl/operator/OpRunner.scala#L22

**Checking dependencies:** Verify upstream results => https://github.com/nubank/itaipu/blob/master/common-etl/src/main/scala/common_etl/operator/OpRunner.scala#L41

**Checking committed:** Verify if current op is already committed: https://github.com/nubank/itaipu/blob/master/common-etl/src/main/scala/common_etl/evaluator/MetapodSparkPipelineEvaluator.scala#L19

**Configuring pipeline:** All kinds of configuration that can be applied to the Op execution, its inputs, and outputs. Those steps are mapped on the pipeline as:

      - Configure,
      - MergeParquetSchema
      - ConfigureInputPartitionCoalescing
      - SetShufflePartitions
      - CoerceInputs
      - PrepareSchema
      - CoerceArchiveIntegerColumns
      - CoerceDecimalScale
      - CoalesceOrRepartition
      - EstimateIdealPartitionNumber
 
Some of these states produce actions and may fail, but we are considering it as one configuration state for the sake of simplification.
 
**Read Inputs:** Read upstream paths from metapod and transform it into dataframes => https://github.com/nubank/itaipu/blob/9ccbeaf32ed82ad803b19c128da652b774b631e9/common-etl/src/main/scala/common_etl/evaluator/steps/ReadInputs.scala#L11
 
**Running:** Compile dataframe (may execute actions if called on the Op definition) => https://github.com/nubank/itaipu/blob/9ccbeaf32ed82ad803b19c128da652b774b631e9/common-etl/src/main/scala/common_etl/evaluator/steps/PrepareExecution.scala#L10
 
**Persisting:** Compute compiled dataframe and write output on s3 => https://github.com/nubank/itaipu/blob/9ccbeaf32ed82ad803b19c128da652b774b631e9/common-etl/src/main/scala/common_etl/evaluator/steps/Persist.scala#L12

Validating: All kinds of verifications to be done on the written output of the Op. The correspondent steps on the pipeline are:

      - CheckIntegrity (can fail)
      - CheckIfEmpty (warning only)
      - CheckAnomaliesUsingMetricValues (can fail)
 
These steps contain different retry policies and on the state diagram we represented the lowest retry policy for those steps (`CheckAnomaliesUsingMetricValues`).
