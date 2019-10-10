# Operations HOWTO

* [Restart aurora](#restart-aurora)
* [Hot-deploying rollbacks](#hot-deploying-rollbacks)
* [Re-deploying the DAG during a run](#re-deploying-the-dag-during-a-run)
* [Deploying a service in Aurora](#deploying-a-service-in-aurora)
* [Controlling aurora jobs via the CLI](#controlling-aurora-jobs-via-the-cli)
* [Basic steps to handling Airflow DAG errors](#basic-steps-to-handling-airflow-dag-errors)
* [Recover from non-critical model build failures](#recover-from-non-critical-datasetmodel-build-failures)
  * [Determining if a dataset or model is business critical or can be fixed without time-pressure](#determining-if-a-dataset-or-model-is-business-critical-or-can-be-fixed-without-time-pressure)
  * [Determining if it was the dataset or model that failed](#determining-if-it-was-the-dataset-or-model-that-failed)
  * [Dealing with dataset failures](#dealing-with-dataset-failures)
  * [Dealing with model failures](#dealing-with-model-failures)
  * [Making downstream jobs run when an upstream job fails](#making-downstream-jobs-run-when-an-upstream-job-fails)
  * [Determining downstream datasets to a failed dataset](#determining-downstream-datasets-to-a-failed-dataset)
* [Keep machines up after a model fails](#keep-machines-up-after-a-model-fails)
* [Manually commit a dataset to metapod](#manually-commit-a-dataset-to-metapod)
* [Checking a dataset loaded](#checking-a-dataset-loaded)
* [Removing bad data from Metapod](#removing-bad-data-from-metapod)
  * [Retracting datasets in bulk](#retracting-datasets-in-bulk)
* [Dealing with Datomic self-destructs](#dealing-with-datomic-self-destructs)
* [Load a run dataset in Databricks](#load-a-run-dataset-in-databricks)
* [Restart the backup-restore cluster](#restart-the-backup-restore-cluster)
* [Checking status of cluster up/down scales](#checking-status-of-cluster-up-and-down-scales)
* [Run an itaipu job with a longer healthcheck](#run-an-itaipu-job-with-a-longer-timeout-healthcheck)
* [Deploy a hot-fix to itaipu](#deploy-a-hot-fix-to-itaipu)
* [Serve a dataset again](#serve-a-dataset-again)
* [Checks before old Prod stack teardown](#checks-before-old-prod-stack-teardown)
* [Retracting Manual Appends to Dataset Series](#retracting-manual-appends-to-dataset-series)


## Restart Aurora

Every once in a while, Aurora goes down. `sabesp` commands, such as ones involved in running the DAG, won't work in this case .

**Symptoms of a non-responsive Aurora**

- The [aurora web UI](https://cantareira-stable-mesos-master.nubank.com.br:8080) does not load, but the [mesos web UI](https://cantareira-stable-mesos-master.nubank.com.br) does.
- A lot of pending jobs in the [aurora web UI](https://cantareira-stable-mesos-master.nubank.com.br:8080)

Try to look into the issue, potentially by ssh'ing into `mesos-master`, via `nu ser ssh mesos-master --suffix dev --env cantareira --region us-east-1` and looking at the aurora logs via `journalctl -u aurora-scheduler`.

To restart Aurora, you could do either of the following:

- cycle `mesos-master`: `nu ser cycle mesos-master --env cantareira --suffix stable --region us-east-1`
- restart `aurora-scheduler` alone:
  - Check current status: `sudo systemctl status aurora-scheduler`
  - Start the service: `sudo systemctl restart aurora-scheduler`
  - Verify that the service restarted: `journalctl -f -u aurora-scheduler`

Most likely you will need to [restart Airflow](airflow.md#restarting-the-airflow-process) after this happens.

Another result of restarting aurora is an orphaned mesos framework. To check this, look for entries under `Inactive Frameworks` [here](https://cantareira-stable-mesos-master.nubank.com.br/#/frameworks).

```shell
# Use the direct IP to the mesos instance (due to DNS issues) - it's on Leader on the left side of https://cantareira-stable-mesos-master.nubank.com.br/
# Get the frameworkId is the ID for the inactive (orphaned) framework obtained on the framework web UI

curl -XPOST 10.130.1.61:5050/master/teardown -d 'frameworkId=67386329-1fe2-48f4-9457-0d45d924db5d-0000'
```

## Hot-deploying rollbacks

If a buggy version gets deployed of a service that lives in the non-data-infra production space (like `metapod`, `correnteza`, etc.), you can rollback to a stable version using [these deploy console instructions](https://wiki.nubank.com.br/index.php/Hot_deploying_a_service).
You can also do this directly from `CloudFormation`:

* __Make sure there isn't a `to-prod` running and no stacks are being spun!__ The reasoning for this is [explained here](https://wiki.nubank.com.br/index.php/Hot_deploying_a_service)
* Access `CloudFormation` and search for your service (say `metapod`)
* Select the entry that looks something like `prod-global-k-metapod`. If your service doesn't live in `global` you will need to repeat the following steps for every shard it operates on.
* Click `Update Stack` in the top right
* On the `Select Template` page leave the default setting as `Use current template` and select `Next`
* On the `Specify Details` page under parameters, find the prod environment with 0 instances (either `Blue` or `Green`), and update the version to the short SHA of the last non-buggy git commit that was built via Go. You can get this version by looking at the [service's build history on Go](https://go.nubank.com.br/go/tab/pipeline/history/metapod); each build should be the `build-number:full-commit-SHA`. This SHA can be cross-referenced with pull requests to find the desired point to go back to. The shortened SHA can be obtained via `git rev-parse --short 6c957ed851d82103e2b151b04aa8a5ede042c3c5`.
* Click through the following pages confirming your stack changes.
* After a few minutes check that the new version has spun up and is healthy. The hacky way to do this is to hit `nu ser curl GET global metapod --suffix k /api/version` several times (due to the load balancer) and see if you eventually get the right SHA.
* Now you need to take down the buggy version. You can do this by going through the `Update Stack` process and setting the instance size for the buggy versions to 0. This will result in no down-time. If you don't care about having downtime (like if you are data-infra and everything is already gone to shit), you can can do an in-place update of version of the running stack. This will result in the running instances spinning down and a new ones being spun up with the new version, causing ~5min downtime.

## Re-deploying the DAG during a run

If the DAG is using a buggy version of a program and you want to deploy a fix, in certain cases you can deploy the fix to the running DAG.

Make sure you aren't pulling in non-fix related changes since the last DAG deployment.

In some cases, you will want to retract datasets before re-running jobs with the newly deployed version. For example, if `itaipu-contracts` is broken (the first job in the DAG) and you need to deploy a fix for it, kill the job and retract all the committed datasets before restarting with the new `itaipu` version ([see here](ops_how_to.md#retracting-datasets-in-bulk)).

1. Push the fix through the pipeline as described [here](airflow.md#deploying-job-changes-to-airflow)

2. You can't simply clear the running DAG nodes to restart jobs, because this will pull in the old configurations. Instead, you should kill the job via sabesp:

```shell
sabesp --aurora-stack cantareira-stable jobs kill jobs prod itaipu-contracts
```

3. Once the jobs have been killed manually, you should clear them and let airflow start them anew.

## Deploying a service in Aurora

To manually deploy (first check if you can't just use GOCD for doing this automatically) a new version of a service in Aurora you should run the following command in staging and in prod with the git sha of the commit you wish to deploy
```shell
sabesp --aurora-stack=cantareira-stable services upsert staging capivara-clj --sha c0596f1
```

## Controlling aurora jobs via the CLI

[see sabesp cli examples](cli_examples.md)

## Basic steps to handling Airflow DAG errors

The dagão run failed. What can you do?

- Check out for errors on the failed aurora tasks
- Check out for recent commits and deploy on go, to check if they are related to that
- If nothing seems obvious and you get lots of generic errors (reading non-existent files, network errors, etc), you should:
 1. Cycle all machines (eg `nu ser cycle mesos-on-demand --env cantareira --suffix stable --region us-east-1`)
 2. Get the transaction id from [#etl-updates](https://nubank.slack.com/archives/CCYJHJHR9/p1538438447000100)
 3. Retry rerunning the dagão with the same transaction (eg `sabesp --verbose --aurora-stack=cantareira-stable jobs create prod dagao --filename dagao "profile.metapod_transaction=$metapod_tx"`)
 4. If that fails, increase the cluster size (eg `sabesp --aurora-stack=cantareira-stable jobs create prod scale  --job-version "scale_cluster=4945885" MODE=on-demand N_NODES=$nodes SCALE_TIMEOUT=0`)
 5. Retry dagão
 6. If it still doesn't work, rollback to a version that worked and retry dagão.

## Recover from non-critical dataset/model build failures

Datasets and models, especially newer ones, may have bugs that lead to build failures on Airflow that block downstream jobs.
There are two things to do to recover from these failures:
 * Prevent the failure in subsequent runs
 * Retrigger downstream jobs if they can be successfully run in the presence of upstream failures. For example, in the case of a single model failing and causing all of `itaipu-rest` from not running.

There are two types of jobs that can fail, datasets, which are then used to generate downstream models, or the models themselves. Each have different but similar ways to recovery.

### Determining if a dataset or model is business critical or can be fixed without time-pressure

If the model is a [`policy model`](https://github.com/nubank/aurora-jobs/blob/000ba9f8b8ac4b06408bf3783971351d7916e912/airflow/main.py#L256), then it is important to fix the root issue immediately. Otherwise, you can comment it out using the instructions below and let the owner fix it when they get a chance.

### Determining if it was the dataset or model that failed

Get the transaction id for the run ([here is how](https://github.com/nubank/data-infra-docs/blob/master/monitoring_nightly_run.md#finding-the-transaction-id)).
Then find uncommitted "`datasets`" for that transaction by using [sonar](https://backoffice.nubank.com.br/sonar-js/#/sonar-js/graphiql) run this GraphQL query:

```
{
  transaction(transactionId: "f7832a01-001b-56f7-a4fe-b3a417f8f654") {
    datasets(committed: ONLY_UNCOMMITTED) {
      name
    }
  }
}
```

Which will output something like this:

```
{
  "data": {
    "transaction": {
      "datasets": [
        ...
        if the run is still going there will be lots of other entries here
        ...
        {
          "name": "model/fx-model-avro"
        },
        {
          "name": "dataset/fx-model"
        },
        {
          "name": "model/fx-model"
        },
        {
          "name": "dataset/fx-model-csv-gz"
        }
      ]
    }
  }
}
```

Given this output, the dataset failed, also causing the dependent model to fail, so we need to address both using the following steps.

### Dealing with dataset failures

If a dataset is erroring and causing an job node to fail on airflow, we should check to see if it is a critical dataset (current best way is to ask somebody).
If the dataset is non-critical, we can comment out the dataset from `itaipu` to stop it from failing in subsequent runs. Here is an [example PR that does this](https://github.com/nubank/itaipu/pull/1603). You will also want to clear downstream jobs that were marked as failures to allow them to run (see [Making downstream jobs run when an upstream job fails](#making-downstream-jobs-run-when-an-upstream-job-fails)).

### Dealing with model failures

Non-critical models (models that don't feed into policies) can be removed from the DAG definition ([example PR here](https://github.com/nubank/aurora-jobs/pull/483)) so that it doesn't block future runs. The owner of the model can then fix it without blocking other models. It's a good idea to have a look at what happened by querying the model logs in splunk and dropping relevant information directly to the model owners (usually main github contributors to the model):

```
index=cantareira job=aurora/prod/jobs/sorting-hat error
```

(the lines are in the reverse order, so use the `>` on the left and select 'show source` to read the stacktraces more easily)

Removing model will only take affect tomorrow, when in the next run is triggered.

Hence, there are two things you can do to get things building today:

- To get downstream jobs to build today, we can do some Airflow manipulations. Note that the failing model will show up as empty in those downstream jobs.
- If there are no downstream dependencies for a dataset, you can [manually commit an empty dataset for a specific dataset id](#manually-commit-a-dataset-to-metapod).

Lastly, be sure to [deploy job changes to airflow](airflow.md#deploying-job-changes-to-airflow) once the current run finishes.

### Making downstream jobs run when an upstream job fails

Say `itaipu-fx-model` causing the downstream [`fx-model`](https://github.com/nubank/aurora-jobs/blob/000ba9f8b8ac4b06408bf3783971351d7916e912/airflow/main.py#L254) and `itaipu-rest` to fail.

![fx_model failing](images/failed_dag.png)

In this case you can select `fx-model` and mark it as successful:

![mark fx model as success](images/mark_model_success.png)

Then select the downstream nodes that have failed due to the upstream `fx-model` failure and clear them so that when other running dependencies finish, they will run these nodes. In this case, clear both `databricks_load-models` and `scale-ec2-rest`. The resulting DAG should look like this:

![resulting dag](images/recovered_dag.png)

### Determining downstream datasets to a failed dataset

There are two ways to determine downstream datasets/models to a given dataset.
#### Using either `sbt console` or `ammonite repl`
```
cd $NU_HOME/itaipu

git checkout release

export NU_COUNTRY=br && ./amm-repl

val params = common_etl.RunParams(common_etl.Environment.devel("itaipu", common_etl.InfrastructureCountry.BR), java.time.LocalDate.now(), java.time.LocalDate.now(), "18ce1d9", java.util.UUID.randomUUID())

val ops = etl.itaipu.Itaipu.opsToRun(params)

import common_etl.operator.GraphOps
val graph = GraphOps.createGraphFromOps(ops).get

/*The particular dataset you want to compute the successors of*/
import etl.dataset_series.archived.Contextual
val op = Contextual

val node = graph.get(op)
val successors = node.withSubgraph().toSet - op
```

#### Using `spark_ops.json`
`spark_ops.json` is generated as part of the integration tests which run on CircleCI. You will have to navigate to the integration tests run against the specific version of `release` branch. Download `spark_ops.json` by clicking on the link, as shown below.

![spark_ops_json](images/spark_ops_json.png)

```cat Downloads/spark_ops.json | jq '[.[] | select(.name == "series-contract/scr-operacao") | {name: .name, inputs: .inputs, downstream: .successors}] '```

## Keep machines up after a model fails

Usually when a model job fails, you will want to look at the mesos logs for the machine that ran the model job. Unfortunately, those machines are scaled down, which means access to the logs are lost.

You can get around this by disabling the scale-down logic on Airflow for a job.

 - Restart the job.
 - Find the downscale node

![downscale job](images/downscale_node.png)

 - Mark the downscale node as success

![mark downscale as success](images/mark_success.png)

 - After the job fails and you get the logs, clear the downscale node so that airflow will re-run the downscale and machines will be taken offline

Note: this tactic mostly applies to models. For Spark, most of the interesting logs live in the driver, which runs on a fixed instance. In the rare cases where you want the Spark executor logs, you can also apply this downscale delay strategy.

## Checking a dataset loaded

When datasets are loaded into redshift the load is logged in the `Loads` table.
To check if a dataset has been loaded, look it up in `Belo Monte - Meta - Loads` on metabase, filtering by `Table Name`.
For a dataset called `policy/fraud-report-policy` the table name will be `fraud_report_policy`.

![dataset load info](images/metabase_loads.png)

## Manually commit a dataset to metapod

In specific cases, when a dataset that doesn't have downstream dependencies fails, you can commit an empty parquet file to the dataset.
This allows buggy datasets to be skipped so that they don't affect the stability of ETL runs.

- Get the `metapod-transaction-id` from `[#etl-updates](https://nubank.slack.com/messages/CCYJHJHR9/)`.
- Find the name of the failing dataset (`dataset-name`) from the SparkUI page.
- Get the `dataset-id` from sonar with the following GraphQL query:

```
{
  transaction(transactionId: "<metapod-transaction-id>") {
    datasets(
      datasetNames: [
      "<dataset-name>"]) {
      id
      name
      committed
    }
  }
}
```

- Run the following `sabesb` command to commit a blank dataset for a specific dataset in a given run:

```shell
sabesp metapod --token --env prod dataset commit <metapod-transaction-id> <dataset-id> PARQUET s3://nu-spark-us-east-1/non-datomic/static-datasets/empty-materialized/empty.gz.parquet
```

## Removing bad data from Metapod

If bad data has been committed to Metapod, there are some migrations that can be run to *retract* (the Datomic version of *deleting*) certain parts of a transaction, like the committed information about a dataset, attributes and more. The way they work is similar: send a `POST` request with an empty body to an endpoint that starts `api/migrations/retract/:kind-of-stuff-you-want-to-retract/:id`. The currently available things to be retracted are:

* Attributes: via `api/migrations/retract/attribute/:attribute-id`, where `:attribute-id` is the `:attribute/id` of the attribute you want to remove.
* Indexed attributes: via `api/migrations/retract/indexed-attribute/:indexed-attribute-id`, where `:indexed-attribute-id` is the `:indexed-attribute/id` of the indexed attribute you want to remove.
* Committed information of a dataset: via `api/migrations/retract/committed-dataset/:dataset-id`, where `:dataset-id` is the `:dataset/id` of the dataset you want to remove. Note that this does not remove the dataset from the transaction, only the information committed about this dataset (path, format, partitions, etc).

_For example_:

Say you suspect there is an issue with the schema associated with the `archive/policy-proactive-limit-v3` dataset.
You can query the schema on [sonar](https://backoffice.nubank.com.br/sonar-js/#/sonar-js/graphiql) via this query:

```
{
  transaction(transactionId: "319703ce-b90d-5a07-8195-33df0de911c8") {
    datasets(
      datasetNames: [
      "archive/policy-proactive-limit-v3"]) {
      id
      name
      committed
      schema {
        attributes {
          name
        }
      }
    }
  }
}
```

This query shows duplicate attributes in the schema, which is invalid, so the dataset should be retracted.
Run the following, where `5a5d411b-e41a-4a30-ab34-bac476b95761` is the dataset id returned in the query:

```
nu ser curl POST global metapod /api/migrations/retract/committed-dataset/5a5d411b-e41a-4a30-ab34-bac476b95761
```

(if this fails, with a dns resolution issue, try `nu cache bust stack`)

If you then re-run the query you will see that the `schema` is now `null`.

### Retracting datasets in bulk

If you are retracting all datasets, use the following query
```
{
  transaction(transactionId: "f7832a01-001b-56f7-a4fe-b3a417f8f654") {
    datasets(committed: ONLY_COMMITTED) {
      id
      name
    }
  }
}
```

Save the results in a file called `result.json` then run the retraction in parallel for every dataset id (make sure the `jq` command is correct for your query)

```shell
cat result.json | jq -r ".data.transaction.datasets | .[].id  " | xargs -P 10 -I {} nu ser curl POST global metapod /api/migrations/retract/committed-dataset/{}
```

You can track the number of committed datasets with the following query

```
{
  transaction(transactionId: "713a86b9-4459-5167-8573-ca1ad17746c0") {
    datasetConnection {
            numCommittedDatasets
        }
  }
}
```


## Dealing with Datomic self-destructs

If you see frequent Datomic self-destructs alarms, a common cause is lack of provisioned capacity in the DynamoDB table which contains the Datomic database. In order to check if this is happening:
* Open the AWS DynamoDB console
* Search for the table for the service (the naming scheme is `$env-$prototype-$service-datomic`, although `$prototype` is ommitted for most tables in S0 and Global), e.g. `prod-s3-analytics-datomic`, and click on it.
* Go to the Metrics tab and see if there are any throttled write requests or throttled read requests.
* If there are, go to the Capacity tab and increase the Read capacity units and the Write capacity units.

## Load a run dataset in Databricks

### Find the path to the dataset

Datasets are associated with Metapod transaction ids for (nightly) DAG runs ([see here on how to find the transaction id](monitoring_nightly_run.md#finding-the-transaction-id)).
To find a dataset, load the metapod transaction on Sonar.

On Sonar click the `Datasets` tab and:

 - Locate the dataset you want, if you want the avro version look for `{your dataset name}-avro` and for parquet it is just `{your dataset name}`
 - There are two paths, the `S3 Path` corresponds to the direct file path on S3, and the `Databricks Path` to the mounted version on databricks. In this case, we want the `Databricks Path`

![finding a dataset on Sonar](images/find_dataset.png)

### Load it in databricks
Now that you have the path, open up a databricks notebook ([here is a nice example](https://nubank.cloud.databricks.com/#notebook/131424/command/131441))

#### parquet

```scala
val x = spark.read.parquet("dbfs:/mnt/nu-spark-metapod/10b090f0-fda6-4ef3-b091-9b8fec7c45fc")
```

#### avro

```scala
import com.databricks.spark.avro._
val x = spark.read.avro("dbfs:/mnt/nu-spark-metapod/UIeeQn58Qi6_6OLQH6li2w")
```

## Restart the backup-restore cluster
If you see bunch of messages like the one below on #squad-di-alarms one of the two problems is happening: splunk is down or the bakcup-restore cluster is unhealthy

```
No successfull backup for prod-s2-double-entry-t0-datomic-double-entry-t0 in the last 96 hours! Please take a look.
```

If you can query splunk normally than take a look at the backup-restore cluster.

On AWS UI open the ECS service in us-east-1. On the cluster tab search and open the `backup-restore` cluster.
 - In the `Metrics` tab the CPU and Memory utilization should be more than 50%, if it's lower than that it means that something is wrong with the cluster.
 - Go to the `Tasks` tab and click on `Stop all`. After all the tasks are stopped they will come back to a healthy life.

## Checking status of cluster up and down scales

Sometimes we run a job and forget to downscale the cluster. Or the up scale for a job fails.
You can check this by looking at the number of instances tagged with your job on EC2 ([this link](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:search=dimensional-modeling;sort=desc:launchTime)) or mesos agents ([this link](https://cantareira-stable-mesos-master.nubank.com.br/#/agents))

## Run an itaipu job with a longer timeout healthcheck

If a dataset has large skew it might not make enough progress before the healtcheck kills it. Aside from having the dataset not run, this can block downstream datasets.

One solution is to do a custom run of the dataset with the timeout healthcheck set to a higher value.

Up the [`initial_interval_secs`](https://github.com/nubank/aurora-jobs/blob/83ff733d40c5cfd6ec6bfcaa55f69c764a6f03ff/jobs/templates/spark.aurora#L84) in `aurora-jobs/jobs/templates/spark.aurora` to the appropriate amount, for instance, bump from `20` minutes to maybe `50` minutes. `sabesp` uses your local version of `aurora-jobs` when running commands from your computer, so this change will be used when running the `itaipu` job.

Do a custom run of the skewed dataset

```bash
sabesp --aurora-stack cantareira-stable jobs itaipu prod <CLUSTER_NAME> s3a://nu-spark-metapod-permanent-1 s3a://nu-spark-metapod-ephemeral-1 <NODE_COUNT> --filter <DATASET_NAME> --itaipu <QUAY_DOCKER_IMAGE> --transaction <TODAYS_METAPOD_TRANSACTION>
```

for instance:
```
sabesp --aurora-stack cantareira-stable jobs itaipu prod phillip s3a://nu-spark-metapod-permanent-1 s3a://nu-spark-metapod-ephemeral-1 40 --filter dataset/prospect-key-integrity --itaipu c8574a9 --transaction 0235e606-4cbb-5cf4-a9c2-7986a1f462f1
```

The `QUAY_DOCKER_IMAGE` can be the version of `itaipu` listed on `#etl-updates` or chosen from images listed [on quay.io](https://quay.io/repository/nubank/nu-itaipu?tab=tags)

## Run an itaipu job with more executor memory

In some cases, datasets with large skews will cause executors to run out of memory and cause a chain reaction of executor failures, leading to severe slowdown of the node, or even its crash. A usual symptom is repeated log lines like:

```
org.apache.spark.shuffle.FetchFailedException: failed to allocate 16777216 byte(s) of direct memory (used: 23857201152, max: 23861395456)
```

When this happens you will need to run the impacted datasets with more executor memory to allow the run to proceed (as well as fix the underlying issue). In order to do so, you can:

- First, check [the node's configuration in aurora](https://github.com/nubank/aurora-jobs/blob/master/airflow/dagao.py) to know which instance was used
- Using sabesp, run the job using the same parameters as the node, but passing in the extra parameter `--instance-type=<instance_type>`, where `<instance_type>` should be replaced by the instance you're looking to use. You can view available instances and their memory allocations in [Sabesp's `common` file](https://github.com/nubank/sabesp/blob/13a5e1dc8fd560ad61b41107553d5259d423de8c/src/sabesp/utils/common.py#L18-L87)

NB: one thing to be aware of is that, given an instance type with N cores and M GBs of memory, the actual memory of each executor will be M / N. This means you should be careful to pick your new instance type in a way that the ratio will go _up_ (this means sometimes you might want to pick an instance with fewer cores).

## Deploy a hot-fix to itaipu

- Merge a PR into the `release` branch of `itaipu`. Aside from hotfixes, the `release` branch should only be updated once a day right before the `dagao` is automatically deployed ([see here for details](/itaipu/workflow.md#how-itaipu-is-deployed-to-the-dagao)).
- This triggers a build of [`itaipu-stable`](https://go.nubank.com.br/go/tab/pipeline/history/itaipu-stable) on GoCD.
- When this build finishes, and the downstream `dagao` pipeline is built, run the `publish` stage of of that task.

Note that when `itaipu-release-refresh` runs at `23h20 UTC`, any changes merged into `release` will be wiped and replaced by `master`.
If you have a fix that needs to persisted past today, you will need to open another PR targeting `master` with the fix.

Note:
- If `itaipu-stable` fails to build, due to flaky dependency downloads and such, it might be the case that nobody is able to fix it before the dag is deployed

## Checks before old prod-stack teardown

Before the old stack is killed, the engineer will announce to #chapter-engineering so every squad can make sure it is good to continue. Since a big part of the ETL is fed by Kafka messages, we need to make sure that there are no messages left behind.

* Check if there's any apparent Kafka lags for our services on [Thanos](https://prod-thanos.nubank.com.br/graph?g0.range_input=1h&g0.expr=sort_desc(sum(kafka_burrow_partition_lag%7Bstack_id%3D%22%3Cstack_id_to_tear_down%3E%22%2Cgroup!~%22.*RANDOM.*%22%2C%20squad%3D%22data-infra%22%7D)%20by%20(group%2Cprototype%2Ctopic)%20%3E%200)&g0.tab=0). The stack-id should be mentioned by the message above posted by the engineer.
* If any service has a huge lag (huge = 1k+), check if it's healthy and consuming.
* `riverbend` has some peculiarities for its Kafka consumption
  * First, the topic `EVENT-TO-ETL` consumed by `riverbend` depends on other services to stop producing to be drained. The other services will only stop producing after two conditions are met: the DNS is all pointed to the new stack, and there're no [wendy](https://www.github.com/nubank/wendy) instances anymore in the old stack. Currently `wendy` instances can be checked on [EC2 Console](https://sa-east-1.console.aws.amazon.com/ec2/v2/home?region=sa-east-1#Instances:search=wendy;sort=instanceState). Make sure those conditions are true before continuing.
  * In the Thanos graph above, the topic `EVENT-TO-ETL` may never be fully empty because there are heartbeats sent by producers too, we don't care about those. To check if they are real messages, refer to [these Splunk logs](https://nubank.splunkcloud.com/en-US/app/search/search?q=search%20source%3Driverbend%20stack_id%3Ds%20index%3Dmain%20%3Ain-message%20OR%20log_type%3D%3Aout-message&display.page.search.mode=smart&dispatch.sample_ratio=1&earliest=-24h%40h&latest=now&sid=1548336434.1406409) (remember to switch the stack_id). There should be no in/out-message logs.
  * Another issue is that `riverbend` has a "internal lag", because it uses Kafka Stream to batch up the messages before precessing them. To check this "internal lag", we can refer to [this Splunk graph](https://nubank.splunkcloud.com/en-US/app/search/search?q=search%20source%3Driverbend%20stack_id%3Ds%20log_type%3D%22%3Askipping-commit-conditions-not-met%22%20%20%7C%20rex%20%22%3Anumber-of-messages%20(%3F%3Cincoming_message_count%3E%5Cd%2B)%22%7C%20timechart%20max(incoming_message_count)&earliest=-24h%40h&latest=now&display.page.search.mode=smart&dispatch.sample_ratio=1&display.general.type=visualizations&display.visualizations.charting.chart=line&display.page.search.tab=visualizations&sid=1548336013.1404860) (remember to switch the stack_id)
    * Incoming messages count should be zero in the last hours to represent that the "internal lag" is clear.

## Serve a dataset again

If a dataset is served with bad data, and you need to quickly revert to yesterday's data while the issues are fixed, the following course of action is recommended:

1. Query Metapod for the dataset id (for example, `dataset/lusa-scores`:

   ```graphql
   query GetTransaction {
     transaction(transactionId:"<yesterdayTransactionId>") {
       datasets(datasetNames: ["<dataset/name>"]) {
         id
       }
     }
   }
   ```



2. Retract the dataset:

   ```bash
   nu ser curl POST global metapod /api/migrations/retract/committed-dataset/dataset/<datasetId>
   ```



3. Recompute the dataset using yesterday's transaction details (you can get those from yesterday's dag node info)

   ```bash
   nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs itaipu prod <dataset-name>-reserve s3a://nu-spark-metapod-permanent-1/ s3a://nu-spark-metapod-ephemeral-1/ 20 \
   --itaipu <yesterday's itaipu version> \
   --transaction <yesterday's transaction> \
   --target-date <yesterday's target date> \
   --reference-date <yesterday's reference date> \
   --filter <dataset/name>  \
   --use-cache \
   --include-placeholder-ops
   ```
   
   ## Retracting Manual Appends to Dataset Series
   You will occassionally receive requests from users to retract datasets which were manually appended to a dataset-series. This usually happens in the #manual-dataset-series channel.
   
- Use `insomnia`/ `sonar` to get the id of the dataset you want to retract. For eg., `5d94b837-c31e-4109-ac73-b904bbc7bf17`.
- Retract using this end-point on metapod:
  `nu ser curl POST global metapod /api/migrations/retract/dataset-series/dataset/5d94b837-c31e-4109-ac73-b904bbc7bf17`
