---
owner: "#Analytics-productivity"
---

# How to debug dataset issues using Databricks?

### If you are creating a new dataset

If you are creating a new dataset, the best way to validate your data is by consulting people who understand the business area or process you are modeling in your dataset. The reason behind that is to make sure your data reflects reality. Here are a few tips:

**Check row count**

When debugging, you should use `count()` on your Dataframe to see at what stage the error occurred. This is a useful tip not just for error but even for optimizing the erformance of your SparkOp (dataset).
`<dataframe>.count()` returns the number of rows in the Dataframe.
Check if the magnitude of the dataset you are generating is what you expected to be?

You can optimize your dataset by following the solutions provided in the *[Optimizing your SparkOp](../../data-users/etl_users/optimizing_your_sparkop.md)* guide.

**Check if primary keys are unique**

When performing joins, one of the most common challenges is duplicate data. Therefore, checking if primary key is unique for each field in your dataset is _*necessary*_.

Use the following code and make sure it doesn't return any rows.

`import org.apache.spark.sql.functions._
display(a.groupBy("pk1","pk2").agg(count("any_col").as("count")).where(col("count") > 1))`

If you find rows with the same primary key, change the primary key by following the solution in *[FAQ](https://github.com/nubank/data-platform-docs/blob/44273252d2539997db1366575dc8298b4bc91705/data-users/FAQs/dataset-series.md#how-can-i-change-the-primary-key)* guide.

_*Tip: Consult stakeholders, validate few rows against a few business cases, or with other datasets you trust to understand if your data reflects reality.*_

## If you are making changes to an existing dataset

If you have to make changes to an existing dataset and want to make sure you are only changing specific columns without affecting the others or the dataset granularity, [Difizinho](https://github.com/nubank/difizinho/blob/master/docs/GUIDE.md) can help in this process.

[Difizinho](https://github.com/nubank/difizinho/blob/master/docs/GUIDE.md) is a tool used for comparing datasets.

## If you want to check the performance of your dataset

Performance in spark can be challenging to tune since it is bound to both the code and the Spark clusters configuration. Besides, how busy the clusters are during your testing phase.

In general, datasets that run in Databricks can also run in the ETL (after going through the review and passing the tests).

If your notebook's execution goes out of memory or constantly has its job aborted after a few hours of running, this could be pointing to a performance issue. This issue calls for immediate action for optimizing your SparkOp. You can find necessary and useful tips on improving the performance of SparkOp in the _*[Optimizing SparkOp](../../data-users/etl_users/optimizing_your_sparkop.md)*_ guide.

If you have issues with Databricks

If you are having trouble using the Databricks tool, refer to this doc https://docs.google.com/document/d/1u25N1zjsxrffLN5-Ea21tNzpKy7GBg9O36lhImRwQ_4/edit#heading=h.hy1tecvonb9f.
