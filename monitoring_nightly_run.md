# Monitoring the nightly run

We currently recompute all data sets (from scratch) every night at midnight UTC.  The nightly run consists of a directed acyclic graph (DAG) that starts with "contracts", then datasets that depend on contracts, then datasets that depend on other datasets, etc.  You can visualize the DAG using [Airflow](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao):

![image](https://user-images.githubusercontent.com/726169/33067668-2786662a-ceaf-11e7-89bb-14d787268c4b.png)

The goal of monitoring the nightly run is to make sure that data is loaded into DataBricks and Redshift every day before the work day begins in Nubank's Sao Paulo HQ (before 08:30).  It is important to have the load finished before 08:30 in order to provide fresh data, but also because query performance is degraded while a load is happening on Redshift, so a late load hurts user experience even for querying stale data because most of the cluster CPU is spent on the data load will have bad query performance.  It is also important for finance related datasets to be computed every day, as the numbers in these reports have real implications for Nubank cashflow (especially related to the "FIDC" securitization vehicle).

When checking on the progress of the run, first check [Sonar](https://backoffice.nubank.com.br/sonar-js/). Sonar gives visibility into the percent completion of the current run and the datasets that comprise it.

![image](https://user-images.githubusercontent.com/726169/33069627-6b289992-ceb5-11e7-88ad-00cb29697356.png)

## Finding the transaction id

To check Sonar, first get the Transaction ID for the run. The Transaction ID is an UUID that gets generated for every run, in order to logically group together datasets produced in a given run. A nice shortcut for opening the transaction on Sonar is to click at the transaction id link posted by Airflow at 00:00 UTC on the `guild-data-eng` channel on slack.

One way to get the Transaction ID is from the daily Slack notification posted in #guild-data-eng when the nightly run begins (see the Metapod transaction line):

![image](https://user-images.githubusercontent.com/726169/33165581-a8d1169c-d037-11e7-9062-40d678b9800d.png)

Alternatively, you can get the Transaction ID from the Airflow UI:

1. In the DAG Graph view in Airflow, click on any task in the graph:

![](https://user-images.githubusercontent.com/1674699/33117653-8510651a-cf69-11e7-9874-828feb890fe2.jpg)

2. Choose "Rendered" to get the rendered view of the template that got applied to that task:

![](https://user-images.githubusercontent.com/1674699/33117685-a7d94b0c-cf69-11e7-8926-673045e680b8.jpg)

3. See `metapod_transaction` for the Transaction ID:

![](https://user-images.githubusercontent.com/1674699/33117710-c440d8d2-cf69-11e7-9279-79d3030c5062.jpg)

You can use it to get S3 paths (and DataBricks links to mount historical datasets based on Metapod data).

## Airflow and accessing exceptions

You should also check [Airflow](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao) to get an overview of how the nightly run is proceeding.

![image](https://user-images.githubusercontent.com/726169/33066455-9a8e8020-ceab-11e7-9853-eb755881fe27.png)

If you see any node with a red (failed) or yellow (retrying), you can dive deeper by digging deeper into [Mesos logs](https://cantareira-stable-mesos-master.nubank.com.br:8080/scheduler/jobs):

![image](https://user-images.githubusercontent.com/726169/33066845-b10242e6-ceac-11e7-946d-2bc15441a828.png)

![image](https://user-images.githubusercontent.com/726169/33066848-b1f21c1c-ceac-11e7-8505-ca3176b138ca.png)

For Spark jobs (e.g., normal SparkOps / datasets), the relevant logs to investigate are written to `stderr`.  For Clojure services (e.g., capivara-clj), the logs go to `stdout` instead.

![image](https://user-images.githubusercontent.com/726169/33066851-b3f5f8f8-ceac-11e7-9e68-b4dd8d5ca463.png)

Next steps depend on the error that you see.

The following is a common SQL data load error from `capivara-clj`:

![image](https://user-images.githubusercontent.com/726169/33066853-b5f2ba2e-ceac-11e7-94d4-d47fa6459adf.png)

We can see that the error is with the `temporary_fact_payment`, which is associated with the [payment fact table](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/dataset/fact/PaymentFact.scala).  For "dimensional modeling" loads, we first load a temporary version of each table, hence the `temporary_` prefix.

For Redshift load errors in general, we can use an SQL client (such as DataGrip) connected to `etl@cantareira-redshift.nubank.com.br` (see #access-request on Slack for credentials) to view what went wrong via the `stl_load_errors` table:

```sql
select *
from stl_load_errors
order by starttime desc
limit 100;
```

![image](https://user-images.githubusercontent.com/726169/33068823-c5bba744-ceb2-11e7-8757-6ba2b44c3a4c.png)

After understanding the error that occurred when loading (often a NULL value in a NON NULL column), you can dig deeper to understand how a NULL value could arise.  In this case, the next thing to check might be the source dataset where the problematic column came from to see if it is was also NULL upstream (for the rows with the data load).

You can use DataBricks to check on the source dataset:

https://nubank.cloud.databricks.com/#notebook/131424/command/131441

A given nightly run is identified via the Metapod transaction id.  You can load data from a historical Metapod transaction using the link in Sonar, with the following DataBricks syntax:

`val x = spark.read.parquet("dbfs:/mnt/nu-spark-metapod/10b090f0-fda6-4ef3-b091-9b8fec7c45fc")`

Things that went wrong:
- Itaipu can not complete because (early)
- Redshift load failed (late)

## Dealing with DAG errors

[see the ops how to guide](ops_how_to.md#basic-steps-to-handling-airflow-dag-errors)

## Commonly run commands
[common sabesp CLI commands](cli_examples.md)

## Schedule
https://docs.google.com/a/nubank.com.br/spreadsheets/d/1Gmi2oyxzlMc-a4sgwx_r8W5S-708MmXmr1yLRN8BoLo/edit
