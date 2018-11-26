# Updating the Log Cache on Itaipu

## background

The log cache is a statically cached Parquet of the logs up to a certain Datomic `t` value.
Thus we only need to fetch the newer datoms from DynamoDB/S3, which speeds up log processing and also DynamoDB query times.

The `LogOp` will now union the cached log parquet with the newer log segments in Avro. 

## How to update the cache

Every few months it is important to update the log cache with the latest logs. 
This can drastically speed up contract generation.

To do so 
 - get the metapod transaction for the last successful nightly run ([see here](monitoring_nightly_run.md#finding-the-transaction-id)) 
  - run [this databricks notebook](https://nubank.cloud.databricks.com/#notebook/231312/command/231314) with that transaction
  - copy all the parquets from the `ephemeral` bucket (which will eventually be deleted) into a permanent bucket. You can do some scripting like this:

```
grep "s3:\/\/nu-spark-metapod-ephemeral-1\/\K([^\"]*)" -oP ~/Downloads/export\(2\).csv | xargs -P 10 -I {} aws s3 cp --recursive s3://nu-spark-metapod-ephemeral-1/{} s3://nu-spark-metapod/{}
```

  - do a itaipu test run

```
$ sabesp --aurora-stack=cantareira-dev jobs itaipu staging midea s3a://nu-spark-metapod-ephemeral-1/ s3a://nu-spark-metapod-ephemeral-1/ 192 --itaipu=33a485bc --filter-by-prefix contract-
```

which will have output like this

```
2018-05-28 14:20:23,944 Scaling up the cluster 192 m4.2xlarge nodes
2018-05-28 14:21:22,582 checking job aurora/jobs/staging/scale-ec2-itaipu-midea status.
2018-05-28 14:21:22,582 task scale-ec2-itaipu-midea id: jobs-staging-scale-ec2-itaipu-midea-0-13cabf01-5257-4cdb-ac50-36648c7a8158 finished with total_time: 0:00:10 status: FINISHED end_time: 2018-05-28 14:20:54 start_time: 2018-05-28 14:20:44
2018-05-28 14:21:22,583 Running Itaipu with the following args: s3a://nu-spark-metapod-ephemeral-1/ s3a://nu-spark-metapod-ephemeral-1/ --transaction 49ae32bb-c260-4622-ac10-753cfd8fa7b3 --version 33a485bc --filter-by-prefix contract- --skip-placeholder-ops
```

With the `--transaction` value, find the resulting datasets and check that the contracts generated fine. This means doing some sanity checks that values found in the newly computed contract dataset are also found in yesterday's dataset.

  - open a PR [like this one](https://github.com/nubank/itaipu/pull/2260)
