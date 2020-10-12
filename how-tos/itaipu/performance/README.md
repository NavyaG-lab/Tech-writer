---
owner: "#data-infra"
---

# Suggested code for better performance in itaipu

## Apply multiple `LIKE` filters in a Spark DataFrame

The complete analysis is in this [Databricks notebook](https://nubank.cloud.databricks.com/#notebook/4265734/).

- **Goal:** Given a Spark DataFrame (`~10^6-10^9` rows) and a column in it, filter the values in
this column that satisfy the SQL syntax `WHERE <column> LIKE %<value>%`, for a list of ~10-100
values of `<value>`.
- **Method:** Try four proposed methods to see which one finishes and which one is faster.
- **Results:**
  1. Apply the `df.where` filter to each value in the list, then apply a union: it doesn't finish
  1. Create one filter for all elements: it takes from ~10 s (cached results) to ~30 s (first time
  running)
     - Alternative using `foldLeft` to create the filter: the physical plan is the same
  1. Filter using a regular expression: it takes ~40-60 s (running more than once doesn't seem to
  change the results much)
- **Conclusion:** The suggested approach is th create one filter for all elements.

Suggested code:

```scala
import org.apache.spark.sql.DataFrame
import org.apache.spark.sql.functions.col

// INPUT
val df: DataFrame = ...
val columnName: String = "<my_column>"
val myValues = List("<val1>", "<val2>", "...", "<valN>")

val myValuesLowerLike = myValues.map("%" + _.toLowerCase + "%")
val likeFilter = myValuesLowerLike.map(v => col(columnName) like(v)).reduce(_ || _)
val myDfFiltered = df.where(likeFilter) ```
