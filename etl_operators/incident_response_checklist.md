# Incident response checklist

How this checklist works:

* Your first step should always be to determine potential impact. If in doubt, make sure to get input from your team mates.
* With that in hand, make your way down the checklist and action any point which matches the impact areas you have identified.
* Each checklist item has a corresponding entry in the playbook section further below. This section describes the *why* and the *how* of this item.
* The checklist only focuses on purely operational aspects. At all points, you should follow the crash guidelines and ensure relevant stakeholders are kept up to date on the progress of the crash.
* Finally, this checklist is only useful if it's up-to-date. If while running it you encounter issues with any of the commands, make sure to follow-up and submit a PR to this document to ensure the next Hausmeister doesn't get bitten too.

## Checklist

- [ ] [Prepare your environment](#Prepare-your-environment)
- [ ] Determine if bad data has been, or risks being propagated
- [ ] **[If bad data risks being propagated]** [Pause the serving layer](#Pause-the-serving-layer)
- [ ] **[If bad data is being computed]** [Pause the run](#Pause-the-run)
- [ ] Determine the root cause
- [ ] **[If bad data was committed]** [Determine impacted datasets](#Determine-impacted-datasets)
- [ ] **[If bad data was served and a stakeholder specifically asks you]** [Serve the previous day's version of specific datasets](#Serve-the-previous-days-version-of-specific-impacted-datasets)
- [ ] **[If bad data was committed]** [Retract impacted datasets](#Retract-impacted-datasets)
- [ ] **[If bad data was archived]** [Retract archived datasets](#Retract-archived-datasets)
- [ ] **[If bad data was committed]** [Drain Kafka lag on serving layer services](#Drain-Kafka-lag-on-serving-layer-services)
- [ ] [Deploy fixes as necessary](#Deploy-fixes-as-necessary)
- [ ] [Resume the run](#Resume-the-run)
- [ ] [Resume the serving layer](#Resume-the-serving-layer)

## Checklist item playbook

### Prepare your environment

#### Why?

To ensure you're running the correct commands with the correct parameters.

#### How?

* Run `docker pull quay.io/nubank/datainfra-sabesp:latest` & `nu update`.
* Ensure you're on the `master` branch of `aurora-jobs` and run `git pull`.
* Get today's transaction id: `nu datainfra sabesp -- utils tx-id` and keep it handy.
* You'll probably want to `git checkout release` on Itaipu to ensure you're using whatever is running on Aurora at the moment.

### Pause the serving layer

#### Why?

Data computed by the ETL is used to automate business decisions such as credit increases and credit card releases. Feeding incorrect data into these automated business decision processes can usually result in direct financial losses for the company.

#### How?

**NB: IF A STACK SPIN IS IN PROGRESS, MAKE SURE TO RUN THE BELOW ACTIONS FOR BOTH STACKS**

Affected services: `tapir` & `cutia`

1. Pause live consumers for each service: `nu k8s consumers --env prod --stack-id <stack-id> stop global <service>`. To check the current stack: `nu stack current`
2. Go to the `config` branch of each service and add `"kafka_auto_start_consumers": false` to the config map; then deploy and `to-prod` the config. This will ensure the consumers aren't restarted accidentally by services being cycled.

You can check that the pausing worked by going to the serving layer [Splunk dashboard](https://nubank.splunkcloud.com/en-US/app/search/etl_serving_layer_tapir?form.time_range.earliest=%40d&form.time_range.latest=now) and verifying that no partitions are being served from the moment you've redeployed the services with the new config. You can also use [this query](https://nubank.splunkcloud.com/en-US/app/search/search?q=search%20source%3Dcutia%20%22%3Aappend-to-archived-series-response%22%20%7C%20timechart%20count&display.page.search.mode=fast&dispatch.sample_ratio=1&earliest=%40d&latest=now&display.page.search.tab=visualizations&display.general.type=visualizations&sid=1558353292.9647121) to verify that no more datasets are being archived by `cutia`.

### Pause the run

#### Why?

To prevent more bad data from being computed, and avoid wasting money on computing datasets which we can't use.

#### How?

1. Go to the [Airflow UI](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao)
2. Select the most upstream node which has produced bad data, mark this node and its downstream nodes as failed. This will ensure Airflow doesn't re-attempt killed jobs
3. Kill all active jobs:
   1. Go to the [Aurora UI](https://cantareira-stable-aurora-scheduler.nubank.com.br:8080/scheduler/jobs/prod)
   2. Click on 'sort by : active' to get the list of currently active jobs
   3. For each job, run `nu datainfra sabesp -- --aurora-stack cantareira-stable jobs kill jobs prod <job-name>`
4. Downscale EC2 instances for all killed jobs:
   1. [Search the AWS EC2 for mesos instances .](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:instanceState=running;tag:Name=cantareira-stable-mesos-on-demand;sort=desc:tag:Name)
   2. Terminate all `on-demand` instances.

**NB**: The instructions above assume you want to kill all active jobs. This is the simplest scenario, but in some cases you might want to leave some jobs running (for example if they aren't affected by the crash). In this case you'll want to only downscale instances corresponding to the jobs you killed.

### Determine impacted datasets

#### Why?

You'll need this info for various retractions, and if any were loaded, you'll want to let relevant stakeholders know about it.

#### How?

There is currently no good standard way to do this. In most crashes, a set of buggy source datasets will lead to a number of children datasets being computed with bad data.

* You can adapt the code in [this slack message](https://nubank.slack.com/archives/CE98NE603/p1557323037118200) to obtain the children of a dataset (i.e. dataset which would be impacted by this dataset not computed/computed with wrong data). You can run this code from a local sbt console, on the latest version of Itaipu's `release`  branch.

* You can use [this splunk dashboard](https://nubank.splunkcloud.com/en-US/app/search/etl_serving_layer_tapir?form.time_range.earliest=%40d&form.time_range.latest=now) to verify whether any of the impacted datasets were propagated/loaded.

### Serve the previous day's version of specific impacted datasets

#### Why?

For some specific datasets, it may happen that stakeholders ask you to serve the previous day's version again to get back to a stable state.

Note that you should only do this *if asked by a stakeholder*, as they would know best and would understand the impact of serving data again.

#### How?

Follow the instructions in [Ops How-To](/hausmeister/ops_how_to.md#serve-a-dataset-again).

### Retract impacted datasets

#### Why?

In cases when bad data has already been committed, this step is necessary if you wish for Itaipu to recompute the fixed datasets in the same transaction.

#### How?

1. Obtain a list of datasets to retract using the [Determine impacted datasets](#Determine-impacted-datasets) step. You'll need a list in `json` format of the dataset names, e.g.:

   ```json
   ["dataset/itaipu-spark-stage-metrics",
    "dataset/itaipu-spark-op-metrics"]
   ```

2. If you retract Dataset Series, make sure you also retract all datasets involved in computing them (upstreams):

   - The `series-contract/*`
   - The `series-raw/*`

3. Obtain the ids of the datasets you wish to retract.

   ```graphql
   {
     transaction(transactionId: <tx-id>){
       datasets(datasetNames: [
         <dataset/name>,
         ...
       ],
         committed: ONLY_COMMITTED
       ) {
         id
         name
       }
     }
   }

   ```

4. Assuming you've saved the output of the above query in a file called `result.json`, run the following command:

   ```bash
   cat result.json | \
   jq -r ".data.transaction.datasets | .[].id  " | \
   xargs -P 10 -I {} nu ser curl POST global metapod /api/migrations/retract/committed-dataset/{}
   ```

### Retract archived datasets

#### Why?

If datasets with bad data were committed and marked for archiving, they will be appended to their respective archive dataset series. These series are used heavily for, among other things, monitoring purposes, and so it's important to guarantee the correctness of their data.

#### How?

Assuming you've paused Cutia, run the following:

```bash
nu ser curl POST global metapod /api/migrations/retract/transaction/<transaction-id>/archived-datasets --env prod
```

Because this will retract all archives for the transaction, including good archives, we need to re-archive any already committed dataset (assuming you've already [retracted impacted datasets](#Retract-impacted-datasets)):

1. Find out which datasets need to be archived:

   ```bash
   nu datainfra sabesp -- archive --env prod --token check <transaction-id>
   ```

2. For each dataset, run:

   ```bash
   nu ser curl POST global cutia /api/admin/migrations/append-dataset/<transaction-id>/<dataset-name>
   ```

   Note that `dataset-name` should be the unqualified name of the dataset, without the `archive/` prefix.

### Drain Kafka lag on serving layer services

#### Why?

This step is a follow-up to pausing the serving layer; the idea is to ensure that, when we resume it, we do not serve partitions from the faulty run, but instead only start serving correct datasets.

#### How?

**NB: IF A STACK SPIN IS IN PROGRESS, MAKE SURE THIS HAPPENS ON ALL STACKS**

##### Tapir

1. Go to the config branch, and add the following entries:

   ```json
   {
     ...,
     "kafka_auto_start_consumers": true,
     "enable-loading": false,
     "enable-propagation": false,
     ...
   }
   ```

   This will have the effect of starting the consumers again, but having their handling of the messages be a no-op.

2. `to-prod` the new config. You can monitor that things are going as expected with:

   * The [TAPIR topic lags on Grafana](https://prod-grafana.nubank.com.br/d/000000225/kafka-lags-consumer-group-view?refresh=5m&orgId=1&var-PROMETHEUS=prod-thanos&var-GROUP_ID=TAPIR&var-PROTOTYPE=All&var-STACK_ID=All). Normally it should progressively drain to 0, for both `DATASET-COMMITTED` and `PARTITION-TO-SERVE` topics.
   * The [serving layer splunk dashboard](https://nubank.splunkcloud.com/en-US/app/search/etl_serving_layer_tapir?form.time_range.earliest=%40d&form.time_range.latest=now). No partition should be loaded or propagated from after you've resumed the producer.

3. remove the `"enable-loading"` & `"enable-propagation"` entries, set `"kafka_auto_start_consumers"` back to false and `to-prod` the config. This restores the service to its paused state (you'll probably want to wait until you're confident you have a working Itaipu before having it resume normal activity).

##### Cutia

1. Go to the config branch and add the following entries:

   ```json
   {
     ...,
     "kafka_auto_start_consumers": true,
     "process_data": false,
     ...
   }
   ```

   This will have the effect of starting the consumers again, and their handling of messages be a no-op

2. `to-prod` the new config. You can monitor that things are going as expected with:

   - The [Cutia topic lags](https://prod-grafana.nubank.com.br/d/000000225/kafka-lags-consumer-group-view?refresh=5m&orgId=1&var-PROMETHEUS=prod-thanos&var-GROUP_ID=CUTIA&var-PROTOTYPE=All&var-STACK_ID=All). Normally it should progressively drain to 0 for `DATASET-COMMITTED`.
   - This [Splunk query](https://nubank.splunkcloud.com/en-US/app/search/search?q=search%20source%3Dcutia%20%22%3Aappend-to-archived-series-response%22%20%7C%20timechart%20count&display.page.search.mode=fast&dispatch.sample_ratio=1&earliest=%40d&latest=now&display.page.search.tab=visualizations&display.general.type=visualizations&sid=1558353292.9647121). No dataset should be archived while the lag drains.

3. remove the `"process_data"` entry, set `"kafka_auto_start_consumers"` back to false and `to-prod` the config. This restores the service to its paused state (you'll probably want to wait until you're confident you have a working Itaipu before having it resume normal activity).

### Deploy fixes as necessary

See [Deploying a hot-fix of Itaipu](/hausmeister/ops_how_to.md#deploy-a-hot-fix-to-itaipu).

### Resume the run

#### How?

If you paused the run using the instructions above, then all you should have to do is clear the same root nodes that you marked as failed. Make sure that `Downstream` and `Recursive` are turned on to ensure children nodes are properly cleared.

### Resume the serving layer

#### How?

Once you're satisfied that the run is outputting correct data, remove the `kafka_auto_start_consumers` entry in `tapir` and `cutia`'s configs and `to-prod` them.

There's a chance that you might have retracted the archives for correct datasets which won't get recomputed by your resumed run. Even though we have an alarm to prevent this happening, it can be a good idea to run.
