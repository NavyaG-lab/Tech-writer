---
owner: "#analytics-chapter-engineering"
title: "How to Fix Non-Performant Datasets"
---

Is your dataset showing up in [Dataset Performance Rating dashboard](https://datastudio.google.com/reporting/eb3ec818-9bcc-478d-bf95-d707a8440d44/page/p_qwuxgef1oc) as Non Performant?

In this guide we’ll go through the most common cases of datasets being non performant and how to optimize them.

## Most Common Non Performant causes

If you need help fixing a dataset, please reach out at https://nubank.slack.com/archives/C06F04CH1

### Join

Join operations are often the biggest source of performance problems, how well the join operation will perform depends on a lot of variables, like size of the datasets being joined, the keys and even the type of join. Spark (the framework we use to process our data) do a lot internally to optimize join operations, but we also need to cooperate with it, with some best practices!  

### Self Joins

Self joins (joining a dataset to itself) are commonly used in SQL, but unfortunately, this practice should be avoided when using Spark.

In 100% of the usages of self joins can be replaced to window functions or other approaches

**Problem**

Self joins are inefficient in Spark because, contrary to the common sense, it ends up applying all transformations defined before the self join twice (redundant calculation).

**How to solve**

Some considered approaches would be:

Replacing self join logic with window functions

Make sure that the steps before the self-join are executed and the result is cached. In other words, create a separate dataset for all steps before the self join. In that case, when you do the self join, Spark would be joining two "physical" tables, which would avoid redundant calculations. If you don’t want to create another dataset, the approach #1 will most certainly solve your problem :)

??? optional-class "Detailed explanation"

    Imagine the scenario:

    val myTransformation = df.groupBy($"something", $"date_a", $"date_b").agg(avg($"value"))

    myTransformation.as("b").join(myTransformation.as("a"), $"a.date_a" === $"b.date_b")

    Usually, what we expect is for myTransformation to be calculated and with the calculated table, perform the self-join, but unfortunately this is not what happens. In that case, Spark will do the transformation twice! This is not a problem if the transformation is lightweight, but if we are doing this after a ton of calculation steps, this could be a major performance problem.

    When we are running the steps of our transformation code, Spark is not really manipulating data. It is only building a "query" that, in the end, will be applied to the data. That means that putting transformation code into a val doesn't lead to a materialized table. Everything is lazily evaluated, meaning that transformations are only planned, not executed, until we really "execute" our code (doing a display on Databricks, for example).

    Window functions will most certainly solve what you need, but if you don’t want to use them, another way to solve this is to put everything before the self-join into its own dataset, so it gets calculated beforehand and saved as a materialized table. We then use this dataset as an input to the dataset that will do the self-join. Then, spark will be dealing not with lazily evaluated code, but with a real table that is already materialized.
???

### Inequality Joins

**Problem**

Joins that have an "inequality" condition (i.e., joins that use OR, AND, <, > conditions) are usually expensive to compute.

**How to solve**

A lot of approaches can be used here, but the general idea is to replace the inequality join by cheaper joins or other functions that achieve the same result. One common approach is to divide your dataset in smaller pieces where you apply specific logic and then union them at the end. Check this pull request for a practical example.

??? optional-class "Detailed summary"

    When working with performance in Spark, one of the things to keep an eye on is shuffling. Shuffle tends to be the reason why performance is bad for calculations. Being a distributed system, a lot of machines work together in order to perform a transformation. If a specific machine has all the data it needs to do the transformation, it tends to be faster since it doesn't need to share anything with other machines in the cluster (these transformations are called narrow transformations, see item 1 - Skewed Partitions for more information). If it can't do the transformation by itself, it needs to shuffle data between machines, which leads to worse performance.

    In general, we want to avoid shuffles as much as we can, but they are most of the times inevitable (specially on join operations). In the proposed solution we would still have some shuffling going on, but since we are basing our joins in equality conditions, the shuffle would be smaller, thus the performance will be better.

    If you want to read more about inequality joins, check [Prefer Unions over Or in Spark Joins](https://medium.com/@suj1th/prefer-unions-over-or-in-spark-joins-9d1ca5e88021) article.

???

### Joining with skewed Partitions

**Problem**

Skewed partitions happen when you try to join two tables and there is an unbalance in values on a join key. The most common situation is when you try to join by keys that can contain null values

**How to solve**

`keyIntegrity.join(myDF, Seq("account__id"))`

Imagine that in the "keyIntegrity" table, a lot of rows have a null account__id. In that case, we will have a skewed partition leading to an expensive join operation. In order to solve it, the common technique usually is to separate your query into small dataframes that can be unioned afterwards.

<pre>
val dfWithoutNulls = keyIntegrity.where($"account__id".isNotNull)
val dfWithNulls    = keyIntegrity.where($"account__id".isNull)

dfWithoutNulls
.join(myDF, Seq("account__id"))
.unionByName(dfWithNulls)

// you will probably have extra steps to have the same columns both in dfWithoutNulls and dfWithNulls
// but that's the general idea
</pre>


We have an implementation of this strategy on [Efficiency Utils](https://github.com/nubank/itaipu/blob/dc34cd6b6900f634c8332e422af00590a5f7a3b3/src/main/scala/etl/common_utils/EfficiencyUtils.scala#L28)

This is one of the common situations, but skew can happen in other ways as well. Check [Optimizing Skewed SparkOps](https://github.com/nubank/data-platform-docs/blob/master/data-users/etl_users/optimizing_skew.md) if you want to know more.

??? optional-class "Detailed explanation"

    Spark is a distributed system, meaning that the data you are manipulating is shared (or partitioned) among a cluster of machines. That means that, everytime you need to do a transformation that involves "the whole data" at once, machines need to share data between themselves in order to give you a result.

    Consider this: When you are joining two tables, Spark needs to match keys from one table with keys from another table. In order to do that, it usually repartitions your data so groups of keys with the same value can live on the same machine, making it easy to join it afterwards. Spark is always trying to balance the size of each partition so they can be roughly the same, but if one of your key values is much more common than other ones one partition will have much more data then the others, leading to what we call skewed partition. This kind of behavior can happen with all wide transformations, but is most commonly seen with joins.

    Solutions using union are good because unions are far cheaper than joins because they don't require shuffle between partitions (we say that union is a narrow transformation, instead of a wide transformation, see more here

???

### UDFs

**Problem**

UDFs are not optimize-able by the Spark engine and can lead to degradation on performance.

**How to solve**

==It is always suggested to avoid UDFs as long as it is inevitable. When we use UDFs we end up losing all the optimization Spark does on our Dataframe/Dataset.==

Use Spark standard functions (functions that live on org.apache.spark.sql.functions._) as much as possible.

Spend some time rethinking your logic: could it be done without your UDF? Your dataset will certainly benefit from that.

If you don’t know how to replace your UDF logic, please reach out for help at https://nubank.slack.com/archives/C06F04CH1.

Spark has a lot of stuff built-in that helps it to do things as efficiently as possible. When we are using "default" functions, such as join, where, avg, everything that lives in org.apache.spark.sql.functions, we are leveraging Spark built-in optimization. When we define our own UDFs though, Spark doesn't really know how to deal with it. For Spark, our UDFs are black boxes (read more here). If the UDF is lightweight it could be a non issue, but the general rule is to avoid it as much as possible.
