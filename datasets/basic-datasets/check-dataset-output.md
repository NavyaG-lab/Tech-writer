---
owner: "#data-infra"
---

<!-- markdownlint-disable-file -->

# How do check if the dataset run on ETL?

You have created a PR with your dataset and now check if your desired dataset has run on ETL and available in Google BigQuery or Databricks.

Before you try accessing, check if your dataset is included in the day's ETL run (Itaipu run). The first step is to ensure that your PR is merged into Itaipu `master` branch before `23h00 UTC`.

### Check the ETL run status

You can look at [#etl-updates](https://nubank.slack.com/archives/CCYJHJHR9) to see which itaipu version was deployed and ETL run status.

The next step is to run the following command to check if your dataset is included in today's run:

` nu etl info dataset/<dataset-name> --n`

The `--n` parameter is for checking the run's history. Also, note that the dataset name should contain `-`

If you just run the command without any parameters it shows the status of the current ETL run.
` nu etl info dataset/<dataset-name>`, (for eg, `nu etl info dataset/xguide-xgalaxy-grades`).

The message can mean:
- The dataset is running
- The dataset hasn’t started running
- The dataset was removed from the run

The most likely scenario is that it still needs to run.

_*Tip: An easy way is to navigate to the file you modified and check if it contains your changes. If yes, then it ran on the ETL.*_

_*Note that the version of Itaipu running for a given day is the one running on the release branch*_

### Check Airflow node where your SparkOp runs

If you would like to go a step furthur, you can see which node on Airflow your SparkOp runs looking at the grouping_label column. Here is an excerpt:

```
spark.table("br__series_contract.itaipu_spark_stage_metrics")
  .where($"run_reference_date" === "2020-08-31")
  .where($"sparkop_name" === "dataset/nuconta-customers")
  .select($"sparkop_name", $"run_reference_date", $"grouping_label", $"step", $"stage_start", $"stage_end")
```
## How do I Check yesterday's run?

If you want to check if your dataset is committed in yesterday's run, append the parameter `--n`. To check yesterday's run, the value for the `--n` parameter should be 2.

`nu etl info dataset/xguide-xgalaxy-grades --n=2`

Running this command will give you the times when the dataset got committed for the last n daily transactions, as well as the S3 paths of the dataset. If the dataset didn't get computed, you'll get a "Dataset was not committed yet..." and if it got aborted you'll get "Dataset was aborted..."

A dataset can get aborted either if there's an issue with it and it's failing to compute or if one of its inputs already got aborted. A dataset not being committed could simply mean that the daily ETL job didn't get to it yet (in which case it will get committed later in the day), but could also have several other causes, e.g. a job that was supposed to compute it failed non-gracefully, the dataset didn't make it into the version of Itaipu being run for that day etc.

**Note that your dataset will be affected by not only changes on the direct predecessors and also changes in the whole lineage, that could be inputs of your inputs and so on.**

The starting point to investigate this is by checking the commit times for all of those datasets and see if there’s something wrong there. `dataset.spark_ops` have the information on all predecessors (on the predecessors column) and contract.`metapod__datasets` contain commit times (but you will have to adapt a little bit of the names in order to be able to join those tables).

 You can get the predecessor that took the longest to commit daily using the query below. The following is an example that shows how to get the predecessor taking long time to commit:

```
    val predecessors = spark.table("series.contract__dataset_spark_ops")
    .filter($"name" === "dataset/nuconta-debit-engagement")
    .withColumn("predecessors", explode($"predecessors"))
    .withColumn("dataset__name", regexp_replace(regexp_replace($"predecessors", "/", "__"), "-", "_"))
    .select($"dataset__name", $"archive_date".as("transaction__target_date"))

    val transactions = spark.table("contract.metapod__transactions")
    .filter($"transaction__type" === "daily")
    .filter($"transaction__target_date" >= "2020-08-01")
    .select("transaction__id", "transaction__target_date")

    val metapod = spark.table("contract.metapod__datasets")
    .join(transactions, Seq("transaction__id"))
    .join(predecessors, Seq("dataset__name", "transaction__target_date"))
    .withColumn("last_predecessor", row_number().over(Window.partitionBy($"transaction__target_date").orderBy($"dataset__committed_at".desc)))
    .filter($"last_predecessor" === 1)
    .select("dataset__name", "transaction__target_date", "dataset__committed_at")
    .orderBy("transaction__target_date")
    metapod
    .d
```
