---
owner: "#data-infra"
---

<!-- markdownlint-disable-file MD024 -->
<!-- markdownlint-disable-file MD001 -->

# Optimizing your SparkOp

This document aims to provide a simple and easy way to troubleshoot heavy SparkOps. This was based on the experience gathered optimizing datasets, explaining common cases found in our ETL.

Each item contains *__Problem__*, *__How to solve it__* and *__Wait, but why?__* sections. If you are just troubleshooting your SparkOp, you can totally skip the last section. If you are curious, this section contains a more _complete_ explanation about the problem

If you can't get around with just this guide, please reach #data-help or #guild-spark and ask for help!

### 1. Joining with skewed Partitions

#### - Problem

Skewed partitions happen when you try to join two tables and there is an unbalance in values on a join key. The most common situation is when you try to join by join key that can contain null values

#### - How to solve it

```scala
keyIntegrity.join(myDF, Seq("account__id"))
```

Imagine that in the "keyIntegrity" table, a lot of rows have a `null` account__id. In that case, we will have a skewed partition leading to an expensive join operation. In order to solve it, the common technique usually is to separate your query into small dataframes that can be unioned afterwards.

```scala
val dfWithoutNulls = keyIntegrity.where($"account__id".isNotNull)
val dfWithNulls    = keyIntegrity.where($"account__id".isNull)

dfWithoutNulls
  .join(myDF, Seq("account__id"))
  .unionByName(dfWithNulls)

  // you will probably have extra steps to have the same columns both in dfWithoutNulls and dfWithNulls
  // but that's the general idea

```

We have an implementation of this strategy on
[Efficiency Utils](https://github.com/nubank/itaipu/blob/dc34cd6b6900f634c8332e422af00590a5f7a3b3/src/main/scala/etl/common_utils/EfficiencyUtils.scala#L28)

This is one of the common situations, but skew can happen in other ways as well.
Check
[Optimizing Skewed SparkOps](optimizing_skew.md)
if you want to know more

#### - Wait, but why

Spark is a distributed system, meaning that the data you are manipulating is shared (or _partitioned_) among a cluster of machines. That means that, everytime you need to do a transformation that involves "the whole data" at once, machines need to share data between themselves in order to give you a result.

Consider this: When you are joining two tables, Spark needs to match keys from one table with keys from another table. In order to do that, it usually repartitions your data so groups of keys with the same value can live on the same machine, making it easy to join it afterwards. Spark is always trying to balance the size of each partition so they can be roughly the same, but if one of your key values is much more common than other ones one partition will have much more data then the others, leading to what we call **skewed partition**. This kind of behavior can happen with all wide transformations, but is most commonly seen with joins.

Solutions using `union` are good because unions are far cheaper than joins because they don't require shuffle between partitions (we say that union is a `narrow` transformation, instead of a `wide` transformation, see more [here](https://data-flair.training/blogs/spark-rdd-operations-transformations-actions/)

### 2. Inequality Joins

#### - Problem

Joins that have an "inequality" condition (i.e., joins that use `OR`, `AND`, `<`, `>` conditions) are usually expensive to compute.

#### - How to solve it

A lot of approaches can be used here, but the general idea is to replace the inequality join by cheaper joins or other functions that achieve the same result. One common approach is to divide your dataset in smaller pieces where you apply specific logic and then union them at the end. Check this [pull request](https://github.com/nubank/itaipu/pull/10456) for a practical example.

#### - Wait, but why

When working with performance in Spark, one of the things to keep an eye on is shuffling. Shuffle tends to be the reason why performance is bad for calculations. Being a distributed system, a lot of machines work together in order to perform a transformation. If a specific machine has all the data it needs to do the transformation, it tends to be faster since it doesn't need to share anything with other machines in the cluster (these transformations are called `narrow transformations`, see item 1 - Skewed Partitions for more information). If it can't do the transformation by itself, it needs to _shuffle_ data between machines, which leads to worse performance.

In general, we want to avoid shuffles as much as we can, but they are most of the times inevitable (specially on join operations). In the proposed solution we would still have some shuffling going on, but since we are basing our joins in equality conditions, the shuffle would be smaller, thus the performance will be better.

If you want to read more about inequality joins, check [here](https://medium.com/@suj1th/prefer-unions-over-or-in-spark-joins-9d1ca5e88021)

### 3. Self Joins

#### Problem

Self joins (joining a table on itself) are innefficient in Spark, because contrary to the common sense, Spark ends up applying all transformations defined before the self join twice (redundant calculation).

#### How to solve it

Some considered approaches would be:

- Replacing self join logic with window functions, when possible
- Make sure that the steps before the self-join are executed and the result is cached. In other words, do a separate SparkOp for all steps before the self join. In that case, when you do the self join, Spark would be joining two "physical" tables, which would avoid redundant calculations.

#### Wait, but why

Imagine the scenario:

```scala

val myTransformation = df.groupBy($"something", $"date_a", $"date_b").agg(avg($"value"))

myTransformation.as("b").join(myTransformation.as("a"), $"a.date_a" === $"b.date_b")

```

Usually, what we expect is for myTransformation to be calculated and with the calculated table, perform the self-join, but unfortunately this is not what happens. In that case, Spark will do the transformation twice! This is not a problem if the transformation is lightweight, but if we are doing this after a ton of calculation steps, this could be a major performance problem.

When we are running the steps of our transformation code, Spark is not _really_ manipulating data. It is only building a "query" that, in the end, will be applied to the data. That means that putting transformation code into a `val` doesn't lead to a _materialized_ table. Everything is _lazily evaluated_, meaning that transformations are only planned, not executed, until we really "execute" our code (doing a _display_ on Databricks, for example).

The usual way to solve this is to put everything before the self-join into its own SparkOp, so it gets calculated beforehand and saved as a materialized table. We then use this SparkOp as an input to the SparkOp that will do the self-join. Then, spark will be dealing not with lazily evaluated code, but with a real table that is already materialized.

### 4. UDFs

#### Problem

UDFs are not optimize-able by the Spark engine, and, if heavy, can lead to degradation on performance.

#### Solution

Use Spark standard functions (functions that live on `org.apache.spark.sql.functions._`) as much as possible. Spend some time rethinking your logic: could it be done without your UDF? Your SparkOp will certainly benefit from that.

#### Wait, but why

Spark has a lot of stuff built-in that helps it to do things as efficiently as possible. When we are using "default" functions, such as `join`, `where`, `avg`, everything that lives in `org.apache.spark.sql.functions`, we are leveraging Spark built-in optimization. When we define our own UDFs though, Spark doesn't really know how to deal with it. For Spark, our UDFs are black boxes (read more [here](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-udfs-blackbox.html)). If the UDF is lightweight it could be a non issue, but the general rule is to avoid it as much as possible.

### 5. Spark Actions

#### Problem

This is tightly connected not to spark but to the way we run SparkOps on our ETL. One of the principles we follow is that SparkOps need to be lazily evaluated, meaning that from the beggining to the end of the code, no evaluation needs to be done (i. e., no references to the real data that is represented by a DataFrame). Some of the common Spark Actions are:

- `.count` In order to get the number of rows of a DataFrame, you need to access the "real data"
  - Be aware that `DataFrame.count` is different from the `count()` function on `spark.sql.functions`. The first cannot be used because it needs to access the real data in order to retrieve a row count, the second one can be used and and behaves as any other `COUNT` statement on SQL
- `.collect` The method itself get's the "real data" to the spark driver
- `.pivot(...)` without passing a list of columns to be pivotted. If you don't pass this argument, Spark will try to access the "real data" in order to do the pivotting

#### Solution

This needs a case-by-case approach, because you need to understand why exactly you are relying on the real data to do whatever you are trying to do. In most of the cases this is avoidable, but you can always ask #data-help for guidance on how to achieve your objectives without violating this constraint

#### Wait, but why

Having lazily evaluated SparkOps reduces complexity on the ETL and increases reliability. By having this guarantee, the infrastructure can have total control on when the SparkOp is actually evaluated, guaranteeing that the whole environment is ready and correctly configured at the right time.
