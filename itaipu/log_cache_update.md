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
 - run [this databricks notebook](https://nubank.cloud.databricks.com/#notebook/231312/command/231314) with that transaction (should take ~2-3 hours). This notebook opens all the logs and materialized entities for the specified transaction and looks up the `T` value. This is used to properly populate the LogCache map.
 - copy all the parquets from the `ephemeral` bucket (which will eventually be deleted) into a permanent bucket. You can do some scripting like this:

```
grep "s3:\/\/nu-spark-metapod-ephemeral-1\/\K([^\"]*)" -oP 2019-03-20-log-cache.csv | xargs -P 10 -I {} aws s3 cp --recursive s3://nu-spark-metapod-ephemeral-1/{} s3://nu-spark-datomic-logs/cache/{}
```

 - open a PR updating the log cache entries in `common-etl`, [similar to this one](https://github.com/nubank/itaipu/pull/6426), using the output of:

```
cat 2019-03-20-log-cache.csv | sort | sed -e 's/s\"/\"/g' | sed -e 's/\"\"/\"/g' | sed -e s'/.$//' | sed -e s'/^.//'
```

 - build and push an image of `itaipu` using these changes to quay.io

 - do a log validation run using quay.io image using the following scripts:

### starting jobs
The job starter that creates 10 validation jobs that all take a portion of the logs and materialized entities to validate

```
#!/bin/bash
INSTANCES=10
LAST_INSTANCE=$(expr $INSTANCES - 1)
VERSION=a8334c1
TX=<define an unclaimed tx>
for i in {0..$LAST_INSTANCE}
do
  nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs create prod log-validator-$i --filename log-validator-cli --job-version "itaipu=$VERSION" DRIVER_MEMORY_JAVA=20G ITAIPU_NAME=log-validator-$i DRIVER_MEMORY=23622320128 EXECUTOR_MEMORY=28991029248 CORES=2560000 METAPOD_ENVIRONMENT=prod COUNTRY=br ZK_MASTER=zk://cantareira-zookeeper.nubank.com.br:2181/cantareira-stable ARGS=s3a://nu-spark-metapod-ephemeral-1___--parcel-count___${INSTANCES}___--parcel-id___0___--version___${VERSION}___--transaction___${TX}
done
```

Once the jobs have started, you'll need to feed them with machines:

```
#!/bin/bash
INSTANCES=10
LAST_INSTANCE=$(expr $INSTANCES - 1)
for i in {0..$LAST_INSTANCE}
do
  nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs create prod scale-ec2-log-validator-$i NODE_COUNT=40 SLAVE_TYPE=log-validator-$i INSTANCE_TYPE=m4.2xlarge --filename scale-ec2 --job-version="scale_cluster=308ce8e"
done
```



### things to watch out for

#### heavy databases
Jobs are divided up into databases by alphabetical order. Some parcels have larger databases, like `double-entry` and `feed`. Those parcels will eventually get stuck and you'll need to manually split them up.
This can be done with something like:

```
DS=raw-double-entry-t7-s0/materialized-entities-validation,raw-double-entry-s5/log-validation,raw-double-entry-s3/log-validation,raw-double-entry-t2-s0/log-validation,raw-feed-s0/materialized-entities-validation,raw-double-entry-t5b-s0/log-validation
i=manual
nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs create prod log-validator-$i --filename log-validator-cli --job-version "itaipu=$VERSION" DRIVER_MEMORY_JAVA=20G ITAIPU_NAME=log-validator-$i DRIVER_MEMORY=23622320128 EXECUTOR_MEMORY=28991029248 CORES=2560000 METAPOD_ENVIRONMENT=prod COUNTRY=br ZK_MASTER=zk://cantareira-zookeeper.nubank.com.br:2181/cantareira-stable ARGS=s3a://nu-spark-metapod-ephemeral-1___--filter-by-name___${DS}___--version___${VERSION}___--transaction___${TX}
```

#### failed coppies
If a file wasn't properly copied you will see something like the following when running the jobs. If you see this, just run the copy for that directory

```
org.apache.spark.sql.AnalysisException: Path does not exist: s3a://nu-spark-datomic-logs/cache/4FUNeUsqSRqxORFm0aJ-jA;
```


### wrap-up

When each job finishes, run the downsacle:

```
i=0
nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs create prod downscale-ec2-log-validator-$i SLAVE_TYPE=log-validator-$i --filename scale-ec2 --job-version="scale_cluster=308ce8e"
```

then trigger the computation of the validation aggregate op `dataset/cache-validations` that will join all the results into one dataset:

```
#!/bin/bash
VERSION=a8334c1
TX=<define an unclaimed tx>
i=final
nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs create prod log-validator-$i --filename log-validator-cli --job-version "itaipu=$VERSION" DRIVER_MEMORY_JAVA=20G ITAIPU_NAME=log-validator-$i DRIVER_MEMORY=23622320128 EXECUTOR_MEMORY=28991029248 CORES=2560000 METAPOD_ENVIRONMENT=prod COUNTRY=br ZK_MASTER=zk://cantareira-zookeeper.nubank.com.br:2181/cantareira-stable ARGS=s3a://nu-spark-metapod-ephemeral-1___--version___${VERSION}___--transaction___${TX}___--include-aggregate___true___

nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs create prod scale-ec2-log-validator-$i NODE_COUNT=1 SLAVE_TYPE=log-validator-$i INSTANCE_TYPE=m4.2xlarge --filename scale-ec2 --job-version="scale_cluster=308ce8e"
```

 - open the `dataset/cache-validations` in databricks and validate that all the rows have `is_valid` set to `true`

 - merge the `itaipu` PR!
