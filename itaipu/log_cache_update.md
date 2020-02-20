# Updating the Log Cache on Itaipu

## Background

The log cache is a statically cached Parquet of the logs up to a certain Datomic `t` value.
Thus we only need to fetch the newer datoms from DynamoDB/S3, which speeds up log processing and also DynamoDB query times.

The `LogOp` will now union the cached log parquet with the newer log segments in Avro.

## How to update the cache

Every few months it is important to update the log cache with the latest logs.
This can drastically speed up contract generation.

To do so
 - get the metapod transaction for the last successful nightly run ([see here](monitoring_nightly_run.md#finding-the-transaction-id))
 - run [this databricks notebook](https://nubank.cloud.databricks.com/#notebook/231312) with that transaction (should take ~2-3 hours). This notebook opens all the logs and materialized entities for the specified transaction and looks up the `T` value. This is used to properly populate the LogCache map. At the end of the notebook there is a command to download a json map with all the updated T info (we'll call it `2019-09-30-log-cache.json`).
 - copy all the parquets from the `ephemeral` bucket (which will eventually be deleted) into a permanent bucket. You can do some scripting like this:

```
grep "s3:\/\/nu-spark-metapod-ephemeral-1-raw\/\K([^\"]*)" -oP 2019-09-30-log-cache.json | xargs -P 10 -I {} aws s3 sync s3://nu-spark-metapod-ephemeral-1-raw/{} s3://nu-spark-datomic-logs/cache/{}
```

 - open a PR updating the log cache entries in `common-etl`, [similar to this one](https://github.com/nubank/itaipu/pull/6756), using the output of:

```bash
$ cp ~/2019-09-30-log-cache.json $NU_HOME/itaipu/common-etl/src/main/resources/log_cache_map.json

$ sed -i 's/nu-spark-metapod-ephemeral-1-raw/nu-spark-datomic-logs\/cache/g' $NU_HOME/itaipu/common-etl/src/main/resources/log_cache_map.json
```

and also make sure all the T values are numbers not strings.

 - build and push an image of `itaipu` using these changes to quay.io

 - do a log validation run using the quay.io image, a fresh metapod tx you invent by hand (to get around a limitation setting it dynamically via airflow), and the log-validation dag via the nucli command:

 ```
 nu datainfra log-validation <QUAY-IMAGE-HASH> <METAPOD_TX_YOU_INVENT>
 ```

 - open the `dataset/cache-validations` in databricks and validate that all the rows have `is_valid` set to `true`. For invalid rows, remove the updates from the json. You can do this using the python script detailed in [this itaipu pr](https://github.com/nubank/itaipu/pull/9129).

 - Make sure you have the `castor-admin` scope. Ask for it at [#access-request](https://nubank.slack.com/archives/C0D3XC9Q8).

 - Upload the new cache to [Castor](https://github.com/nubank/castor/) by running the following command:
 ```nu ser curl --env prod POST global castor /api/static-cache --data "@log_cache_map.json"```

 - merge the `itaipu` PR! Uploading it to `castor` will cause it to be used, but it is good to have the static fallback in itaipu up to date as well

## Adapting to do a partial update

Sometimes you don't want to validate all datasets, but just the heaviest ones.

- run the databricks notebook, but use a [whitelist](https://nubank.cloud.databricks.com/#notebook/231312/command/1689228) to only get the databases in question

```scala
// if you want to only run it for a few dbs (see also https://github.com/nubank/itaipu/pull/7031)
val dbWhitelist = Seq("bleach", "insulator", "feed", "notification")
val whitelistPairs = pairs.filter(x => dbWhitelist.map(x._1.name.contains(_)).foldLeft(false)(_ || _))
whitelistPairs.foreach(x => println(x._1.name, x._2.name))
val result = whitelistPairs.map { case (l, m) => prepareStuff(l, m) }.toSeq
```

- download the json to `2019-10-17-log-cache.json`
- generate a partial change to the json in itaipu based on the notebook results

```python
import json, copy

def open_json(name):
     with open(name) as json_file:
             return json.load(json_file)

def write_json(name, data):
    with open(name, 'w') as outfile:
        json.dump(data, outfile)

old = open_json("$NU_HOME/itaipu/common-etl/src/main/resources/log_cache_map.json")
new = open_json("2019-10-17-log-cache.json")

def merge(old, new):
    up = copy.deepcopy(old)
    for proto in new:
        if proto not in up:
            up[proto] = {}
        for db in new[proto]:
            print("updating " + proto + " " + db)
            v = new[proto][db]
            v["last_t"] = int(v["last_t"])
            up[proto][db] = v
    return up

result = merge(old, new)
write_json("log_cache_map.json_unsorted", result)
```

- do some post processing and put it in place
```bash
# sort the json
cat log_cache_map.json_unsorted | jq -S . > log_cache_map.json

# put it in place
cp log_cache_map.json $NU_HOME/itaipu/common-etl/src/main/resources/log_cache_map.json

# make sure the paths are correct
sed -i 's/nu-spark-metapod-ephemeral-1-raw/nu-spark-datomic-logs\/cache/g' $NU_HOME/itaipu/common-etl/src/main/resources/log_cache_map.json
```

- do a validation run by hand:
```bash
VERSION=6983f18
DS=raw-bleach-s0/log-validation,raw-bleach-s0/materialized-entities-validation
i=0
TX=00000000-6f53-58ad-aed1-8b9d1f436335
# implementation detail to create the tx using `only-create-transaction` flag. It won't run any ops.
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs create prod log-validator-$i --filename log-validator-cli --job-version "itaipu=$VERSION" DRIVER_MEMORY_JAVA=20G ITAIPU_NAME=log-validator-$i DRIVER_MEMORY=23622320128 EXECUTOR_MEMORY=26843545600 CORES=1000 METAPOD_ENVIRONMENT=prod ARGS=s3a://nu-spark-metapod-ephemeral-1___--filter-by-name___${DS}___--version___${VERSION}___--transaction=${TX}___--only-create-transaction___true COUNTRY=br ZK_MASTER=zk://cantareira-zookeeper.nubank.com.br:2181/cantareira-stable
# actually run the ops
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs create prod log-validator-$i --filename log-validator-cli --job-version "itaipu=$VERSION" DRIVER_MEMORY_JAVA=20G ITAIPU_NAME=log-validator-$i DRIVER_MEMORY=23622320128 EXECUTOR_MEMORY=26843545600 CORES=1000 METAPOD_ENVIRONMENT=prod ARGS=s3a://nu-spark-metapod-ephemeral-1___--filter-by-name___${DS}___--version___${VERSION}___--transaction=${TX}___--include-aggregate___true COUNTRY=br ZK_MASTER=zk://cantareira-zookeeper.nubank.com.br:2181/cantareira-stable
# scaleup
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs create prod scale-ec2-log-validator-$i NODE_COUNT=150 SLAVE_TYPE=log-validator-$i INSTANCE_TYPE=r4.xlarge --filename scale-ec2 --job-version="scale_cluster=308ce8e"
# downscale
 nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs create prod downscale-ec2-log-validator-$i SLAVE_TYPE=log-validator-$i --filename scale-ec2 --job-version="scale_cluster=308ce8e"
```

## Debugging
### Failed copies
If a file wasn't properly copied you will see something like the following when running the jobs. If you see this, just run the copy for that directory

```
org.apache.spark.sql.AnalysisException: Path does not exist: s3a://nu-spark-datomic-logs/cache/4FUNeUsqSRqxORFm0aJ-jA;
```
