---
owner: "#data-infra"
---

# Optimizing Skews on SparkOps

## What is a skewed Spark job?
In simple terms,
a skewed job means that one task is taking a lot longer than its "neighbours" in the stage.
This is bad because Spark relies heavily on **parallelization**.

Its greatest power is being able to do a lot of processing simultaneously,
but when we have a skewed task,
it means that it finishes most of the work and keeps waiting until this task is finally done.
We should avoid skews because they hurt the performance of our spark jobs.

## How do we monitor it?
We have a dataset called `dataset/spark-op-skew-monitoring`
that basically looks into the spark metrics collected from the run
and flag SparkOps that have any stage where
the `task_max_time` is 50 times greater than the `task_median_time`
(meaning that a task took 50 times more time than the median of all other tasks on the stage).

Also, a message with the 20 heaviest datasets with skew is sent every monday on #etl-updates

## What causes a skewed job?
There are a lot of reasons why a Spark Job can be skewed,
but we mainly encounter 2 cases when dealing with SparkOps on Itaipu:

1. Joining/grouping with `nulls`
2. Skewed Data

## 1. Joining/grouping with `nulls`

This is a common case where we are doing a join/groupBy and there are lots of `null` values on the join/group key.

Skew happens here because Spark will try to group the data with the same key in the same partition,
in order to execute the operation.
Since there's an unbalance on the key values
(nulls representing too much of the overall data),
we get a partition that needs to work a lot more than the other ones to get the job done.

In most cases solving this issue is pretty simple,
you just need to "isolate" the nulls before the join,
and union them with the results afterwards.

```scala
keyIntegrity.join(myDF, Seq("account__id"))

// Imagine that in the "keyIntegrity" table, a lot of rows have a `null` account__id.
// In that case, we will have a skewed partition leading to an expensive join operation.
// In order to solve it, the common technique usually is to separate your query into small dataframes that can be unioned afterwards.

```scala
val dfWithoutNulls = keyIntegrity.where($"account__id".isNotNull)
val dfWithNulls    = keyIntegrity.where($"account__id".isNull)

dfWithoutNulls
  .join(myDF, Seq("account__id"))
  .unionByName(dfWithNulls)

  // you will probably have extra steps to have the same columns both in dfWithoutNulls and dfWithNulls
  // but that's the general idea

```

Good news is that we already have an implementation of an efficient left join
for this cases of skew, you can find it on
[Efficiency Utils](https://github.com/nubank/itaipu/blob/dc34cd6b6900f634c8332e422af00590a5f7a3b3/src/main/scala/etl/common_utils/EfficiencyUtils.scala#L28).
Using this function is enough for most cases.

## 2. Skewed Data
What if I have an unbalance on my join/grouping keys, but it comes from the data itself?
Imagine a dataset that you are joining where a single value represents 30% of all values?
This will also cause the same kind of skew we saw before, but it's harder to solve
(specially because most times you can't filter this specific value and treat it differently).

For cases where the data itself is skewed,
you can check
[this presentation](https://docs.google.com/presentation/d/1uEOnJoPrQ16rmafG0tZt9l92j7kohpcL2oNfEB7cORg)
about `key salting`, one of the techniques used to overcome skew problems.

## Resources
Handling Skewed Data in Spark SQL using key salting (by @joao.risso)
- [Presentation](https://docs.google.com/presentation/d/1uEOnJoPrQ16rmafG0tZt9l92j7kohpcL2oNfEB7cORg)
- [Recording](https://honey.is/home/#post/883257)

Articles
- [Tamming data skew](https://coxautomotivedatasolutions.github.io/datadriven/spark/data%20skew/joins/data_skew/)
- [Handling data skew in Apache Spark](https://itnext.io/handling-data-skew-in-apache-spark-9f56343e58e8)
