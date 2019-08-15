# On-Call Runbook

This document is a resource for engineers *on-call*.  The general layout of
this document is Alert: Reasoning: Action(s). All the alert entries here
should be linked with the alerts being dispatched from our alerting platform.
The "ALERT" string should be verbatim the same string that is dispatched.

## Alarms

- [alert-itaipu-contracts triggered on Airflow](#alert-itaipu-contracts-triggered-on-airflow)
- [Deadletter prod-etl-committed-dataset](#deadletter-prod-etl-committed-dataset)
- [Correnteza - database-claimer is failing](#correnteza-database-claimer-is-failing)
- [Correnteza - attempt-checker is failing](#correnteza-attempt-checker-is-failing)
- [check-serving-layer triggered on Airflow](#check-serving-layer-triggered-on-airflow)
- [check-archiving triggered on Airflow](#check-archiving-triggered-on-airflow)
- [Riverbend - no file upload in the last hour](#no-file-upload-in-the-last-hour)
- [Datomic backup - No successful backup](#no-successful-backup-for-database-in-the-last-96-hours-please-take-a-look)
- [Warning: [PROD] correnteza_last_t_greater_than_basis_t](#warning-prod-correnteza_last_t_greater_than_basis_t)

## alert-itaipu-contracts triggered on Airflow

This means the first task in our daily DAG failed. This task is a dependency
to all the rest of the DAG, so it's important that it runs smoothly and
on time in order for us to meet our SLA.

_You need VPN access to follow the steps below._

### Check reason for the failure

Check what was the reason for the failure, by following these steps:

1. Access https://cantareira-stable-mesos-master.nubank.com.br:8080/scheduler/jobs/prod/itaipu-contracts?jobView=history
1. You'll see the past instances of that task. Check if the first entry has failed around the time you got the alarm. If this entry indicates the task finished too long ago (15-23 hours ago), that was the previous run. That means the task was failed to be created in Aurora. In this case, refer to the section further below [Checking errors directly in Airflow](#checking-errors-directly-in-airflow).
1. To see the logs, click on the link that is an IP address that starts like `10.` ![image](https://user-images.githubusercontent.com/1674699/37596958-2dd3da18-2b7e-11e8-8b12-9ea541753656.png)
1. Click the `stderr` link in the right end of the screen that will appear. `stdout` might also have useful info.
1. Check the logs for any errors you can read, in some cases there could be an error message or an exception type that makes it clear what is the specific cause for the failure.
1. Check the `#crash` channel in Slack for possible ongoing outages that might cause the DAG run to fail.
1. If you are not sure what is the cause for the failure, or you are not sure what to do about it, jump to the next step which is to restart the task.

> If there is no content in that page or if you get a connection error, that means the task host machine is down and we can't get to the logs that way. In this case, we need to resort to Splunk. Use [this search](https://nubank.splunkcloud.com/en-US/app/search/etl_job_logs?form.the_time.earliest=-60m%40m&form.the_time.latest=now&form.search=*&form.job=aurora%2Fprod%2Fjobs%2Fitaipu-contracts)

### Restart the task

1. Access https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao
1. You'll see the state of the entire DAG in this page. The status of each node in the graph is represented by its stroke color. There is a reference on the upper right corner. In this specific scenario, the first node named `itaipu-contracts` should have a red stroke color.
1. Click on the `itaipu-contracts` node, and you will see a pop-up appear with some buttons. Click the "Clear" button (dark green), while making sure the "Downstream" and "Recursive" options are pressed (which means enabled) beside it.
_What you just did is "clearing" the state of the node. This will effectively make Airflow try to figure out the next steps to try to get the state to a "succeeded" state, which is first transitioning into a "running" state by executing the task_
1. After a few seconds, the node stroke color should be back to light green. If not, refresh the graph view after a few seconds via the refresh button in the upper-right corner.

After executing these steps, there is a possibility that the task fails once more. In this case, escalate to the next layer of on-call and coordinate with another engineer to figure out next steps.

### Checking errors directly in Airflow

It is possible that a failure happens before the task is created in Aurora, and the usual case is lack of credentials to access the aurora API. To verify that:

1. Access https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao
1. Click on the `itaipu-contracts` node in the graph, and you will see a pop-up appear. Click "Zoom into Sub DAG".
1. In the graph that will appear, click the `itaipu-contracts` node. Then, click "View Log".
1. You'll be seeing the log of the last attempt to start that task. If there was a failure, you'll see a stack trace, and right before that, a line that starts with:
```
{base_task_runner.py:98} INFO - Subtask: [2018-03-22 00:32:36,584] {create.py:52} ERROR - job failed with status FAILED and message [...]
```
- What is logged after "status FAILED and message <message>" is the reason why the task failed. If it reads simply `Task failed`, that means the task was started in Aurora, but the actual failure should be inspected via the Aurora logs. For that, jump back to the [Check reason for the failure](#check-reason-for-the-failure) step for this alarm.
- In other cases, you might see a message such as: `Subtask: 401 Client Error: Unauthorized for url`. This means there was an error fetching credentials to talk to the Aurora API. Restarting the task should be enough. To achieve that, follow the steps in the [Restart the task](#restart-the-task) section above.

## Deadletter prod-etl-committed-dataset

This happen when there is a problem on producing a dataset on capivara.

### Check what type of dataset broke

- Open the aws SQS service in the browser and change the region to `us-east-1` (North Virginia).
- There will be at least two queues there: the one consumed by capivara `prod-etl-committed-dataset` and the deadletter queue (messages that failed in the capivara processing are produced to this queue) `prod-etl-committed-dataset-failed`.
- Check the `prod-etl-committed-dataset-failed` queue on `Queue Actions` > `View/Delete Messages` > `Start pooling the messages`
- Each line will be one deadletter. In the body of the message there will be the name of the dataset, if it's an archived (the name starts with `archive/` go to the [next step](#replay-archived-dataset-deadletter). If it's another type of dataset just delete it.

## No file upload in the last hour

This alert means that [Riverbend](https://github.com/nubank/riverbend) is not properly consuming, batching and uploading incoming messages.

- First, check on Grafana if that's really the case [Grafana Dashboard](https://prod-grafana.nubank.com.br/d/000000301/riverbend)
- If that's the case and files upload is actually 0 in the last couple hours you should cycle riverbend, `nu ser cycle global riverbend`
- After a while check if it gets back to normal, it can take a while (~20 min) as it has to restore the state store.
- If it doesn't start working again, check for further exceptions on Splunk.

## Correnteza database-claimer is failing

If you see a `ops_health_failure` alarm on `#squad-di-alarms` for `component: database-claimer` then you can get more info by running

```bash
nu ser curl GET global correnteza /ops/health/database-claimer | jq .
```

Usually this means that the database claimer, which is responsible for acquiring zookeeper locks that correspond to datomic databases, has somehow failed to acquire the appropriate number of locks.

If you cycle the service it should acquire the locks within 30 or so minutes:

`nu ser cycle global correnteza`

You can see the databases that have been claimed via:

`nu ser curl GET --env prod global correnteza /ops/database-claimer/list -- -v | jq .`

## Correnteza attempt-checker is failing

Correnteza has several instances that coordinate via zookeeper to extract from all the datomic databases discovered. If for some reason these instances fail to connect to a datomic database it has extracted from in the past it means that either: there is a bug or the database has been deprecated. In order to check for this we always log in a little docstore when we try to extract from a database. Then every hour we have a healthcheck that ensures that every database listed in that docstore has had an extraction attempt in the last 2 or so hours.

When this healthcheck fails you'll see a `ops_health_failure` alarm on `#squad-di-alarms` for `component: attempt-checker`. For more info run:

```bash
nu ser curl GET global correnteza /ops/health/attempt-checker | jq .
```

Generally this failure means that out of all the `correnteza` instances, one of them somehow failed to start extracting from a database that has been extracted from before.

You can see the databases that have been claimed via:

`nu ser curl GET --env prod global correnteza /ops/database-claimer/list -- -v | jq .`

You can try to cycle the service to see if it acquires the left out database (takes 30 or so minutes to get all the locks):

`nu ser cycle global correnteza`

If the database that isn't being extracted from has been deprecated, you can remove it from the attempt checker list:

`nu ser curl DELETE --env prod global correnteza /api/admin/delete-attempt/waldo-s0`

where `waldo-s0` is the name of the database+prototype.

You can force the healthcheck to recompute its state via:

`nu ser curl POST global --env prod correnteza /ops/attempt-checker/force`


## "check-serving-layer" triggered on Airflow

This means that some partitions of some serving layer datasets have not been processed by tapir yet.

This check runs every day at 17h, 19h and 20h UTC, the last being our SLA for serving layer data to be served via [tapir](https://github.com/nubank/tapir).

To perform the check in your local machine:
- make sure you have sabesp >=2.5.1
```
docker pull quay.io/nubank/datainfra-sabesp:latest
```

- check using the transaction ID of the day
```
nu datainfra sabesp -- serving-layer --env prod --token check-datasets-served <transaction-id>
```

The output will inform you which datasets have not been loaded.

First action is to check [Mortician](https://backoffice.nubank.com.br/mortician/) for deadletters from the `tapir` producer, `Global` shard. If there are any, replay them all.

If there are no deadletters, this probably means a `DATASET-COMMITTED` message from `metapod` was not consumed by `tapir`, for some reason. See below for a way to work around this.

### Force re-processing of datasets

You can manually make `tapir` walk through all the committed serving layer datasets present in the transaction in metapod and process all of them once again.

For that, replace `:transaction-id` for the command below and run it:
```
nu ser curl POST global tapir /api/admin/process-transaction/:transaction-id
```

It's safe to always tell `tapir` to re-process the entire transaction, since it has a mechanism for idempotency where it will not process the same partition twice.

### Further investigation

You can check this [Grafana dashboard](https://prod-grafana.nubank.com.br/d/waGZJY2mk/serving-layer-monitoring?orgId=1&var-prometheus=prod-prometheus) for progress after you've triggered the re-processing.

You can also check the [Splunk dashboard](https://nubank.splunkcloud.com/en-US/app/search/etl_serving_layer_tapir) and find the dataset(s) that are in the `stdout` of the failed job in [aurora job page](https://cantareira-stable-mesos-master.nubank.com.br:8080/scheduler/jobs/prod/check-serving-layer?jobView=history). If they appear in the dashboard, it's possible that they have been processed only partially.

You can also check the [Splunk error logs](https://nubank.splunkcloud.com/en-US/app/search/search?sid=1538150037.2995655) for errors in general. Keep in mind that some instances of `ProvisionedThroughputExceededException` are expected, as explained below.

### DynamoDB write capacity

Another thing to look out for is the DynamoDB autoscaling and provisioned throughput capacity: https://sa-east-1.console.aws.amazon.com/dynamodb/home?region=sa-east-1#tables:selected=prod-conrado-docstore;tab=capacity

In the `Metrics` tab, if the throttled write events are too frequent, you can try scaling the write capacity to a higher amount, such as 15000. Just remember to scale it back down after everything is done, and avoid changing this unless you can see it's indeed the reason why tapir is not making progress - instances of `ProvisionedThroughputExceededException` in the deadletters might indicate this.

`tapir` relies on DynamoDB autoscaling to be able to write data, and autoscaling requires signaling you want a bigger throughput capacity for writes. That is done by continously retrying if this is the error returned from DynamoDB, so there might be some instances of this exception in the error logs. However, if this error is listed as a reason for a deadletter in Mortician, then the retries were not enough and it eventually timed out.

## "check-archiving" triggered on Airflow

This means that some dataset marked to be archived was committed but not archived to the dataset-series.

To perform the check in your local machine:
- make sure you have [sabesp](https://github.com/nubank/sabesp/#installation) >=3.1.0
- check using the transaction ID of the day
```bash
nu datainfra sabesp -- archive --env prod --token check <transaction-id>
```

The output will inform you which datasets have not been archived

First action is to check [mortician](https://backoffice.nubank.com.br/mortician/) for deadletters from the `cutia` producer in the `global` "shard"˜. If there are any, replay them all.

If there is no deadletter or the problem persists after replaying the deadletter you can try running a migration to fix it.

Use the dataset name output that you got running the sabesp command above and the same transaction id to call the migration endpoint:
```bash
nu ser curl POST global cutia /api/admin/migrations/append-dataset/<transaction-id>/<dataset-name>
```

## No successful backup for {database} in the last 96 hours! Please take a look.

**Note:** In this case, the alert message is not copied verbatim because it contains the name of the affected database.

This means that a given production database (Datomic or RDS) didn't create any backups for the specified period of time.

The most common reason for this to happen is that the database was deleted and re-created, and the
[datomic backup process](https://github.com/nubank/datomic-backup-restore) does not know how to recover.

The first step would be to ensure that this is the problem. For that, go to the [Backup and Restore Debug dashboard](https://nubank.splunkcloud.com/en-US/app/search/backup_and_restore_debug) in Splunk and look for a message like this:

```
{"line":"java.lang.IllegalArgumentException: :backup/claim-failed Backup storage already used by skyler-66ccf2fe-3e22-4dc0-ae57-ebadff5315f3","source":"stderr","tag":"6e72516dd850","attrs":{"database":"skyler","dynamo_table":"prod-s6-skyler-datomic"}}
```

This message refers to the `skyler` database, but the rest should be similar.

Before continuing, let's unpack what is happening. The message above suggests that a new backup could not be started because it is being used by `skyler-66ccf2fe-3e22-4dc0-ae57-ebadff5315f3`.
This happens because the backup process uses the unique identifier for each database (`66ccf2fe-3e22-4dc0-ae57-ebadff5315f3` in this case), but since the database was deleted and re-created, it has a new identifier, which the Datomic backup doesn't know about.
Ideally, we would make the Datomic backup aware of this change and recover graciously. For now, the solution is to delete the existing backup for the database, and let the backup process start a new one (which happens automatically).
It's worth noting that deleting the backup also deletes the lock that associates the database with the old identifier.

### Deleting the older backup, allowing a new one to start

The process of deleting an old backup requires running a command for each alert received. Since in our infrastructure each shard is a different Datomic database, it is likely that we receive an alert per shard, and consequently have to run the command multiple times.

Continuing with the example above, here is the process to delete the backup corresponding to the alert above.

Go to [Datomic backup and restore project](https://github.com/nubank/datomic-backup-restore)

Run the `clear_backup` script

```
./scripts/clear_backup.sh prod-s6-skyler/skyler
```

If you want to be sure that you are deleting the right thing, you can use the AWS CLI to list the files on S3:

```
aws s3 ls s3://nu-backups/datomic/sa-east-1/prod-s6-skyler/skyler/
```

It's worth noting that S0 is an exception to the structure above. In this case, the shard part of the aforementioned commands is omitted.
Running the script to clear the backup for Skyler's S0 would look like this:

```
./scripts/clear_backup.sh prod-skyler/skyler
```

The script should print out information about the deleted keys, but once again, you can list the files on S3 to double-check that the process was successful.

The directory listed above should be empty after running the script.

## Warning: [PROD] correnteza_last_t_greater_than_basis_t

### Context

Correnteza tracks the extractions from the Datomic databases by storing the ``last-t` that it extracted from each of those databases.
The actual last `t` stored on those databases is referred to as `basis-t` in Correnteza. This alarm goes off when Correnteza thinks that
it is ahead of the original database, which means that it won't extract any new data from that database.

The condition described above seems impossible to reach, and so far, it has only happened when people destroy and re-create databases for
the production services.


### Solution

Note that this solution only applies for the cases described above, **so please confirm with the service owners that the database was
re-created**.

The solution involves 3 steps:

#### Delete all the extractions for the databases that the alarm is going off for.

There is an admin endpoint in Correnteza exactly for this purpose, but it's protected with the scope `correnteza-extraction-delete`.
If you have to execute this command, make sure to ask for this scope in #access-request.

```
# parameterised with database name (skyler) and prototype (s0)
nu ser curl DELETE --env prod s0 correnteza /api/admin/extractions/s0/skyler -- -v
```

The command runs asynchronously, so the expected response is `HTTP 202 Accepted`. To check if the extractions were actually deleted,
query the [Correnteza docstore][correnteza-docstore] in the AWS console. To check the items corresponding to the command above, the filter
would be `db-protobe = skyler-s0`.

#### Cycle Correnteza in the corresponding prototype

After the extractions are deleted, the next step is to cycle the instances of Correnteza that are connected to that DB prototype. This is
necessary to refresh the `last-t` kept by Correnteza for that database prototype, which happens at service startup.

Correnteza is sharded and it connects to the databases within the same prototype, so we have to cycle the same one that we deleted the extractions
for.

```
# parameterised prototype (s0)
nu k8s cycle s0 correnteza
```

To check the progress of the service cycling, run this command:

```
# parameterised with service name (correnteza) and prototype (s0)
watch --differences --interval 10 nu k8s ctl s0 -- get po -l nubank.com.br/name=correnteza
```

#### Monitor re-extractions

After the service has cycled, wait for a few minutes. Correnteza's startup is noticeably slow because it has to discover and connect to many Datomic databases.
Then, check the status of the Datomic extractor using [Correnteza's extractor dashboard][correnteza-extractor-dashboard] on Graphana.

![Correnteza extractor dashboard][correnteza-extractor-dashboard-img]

The dashboard has a lot more useful information about Correnteza's extractions, but the important bits for this purpose are highlighted in the screenshot.

[correnteza-docstore]: https://sa-east-1.console.aws.amazon.com/dynamodb/home?region=sa-east-1#tables:selected=prod-correnteza-docstore;tab=items
[correnteza-extractor-dashboard]: https://prod-grafana.nubank.com.br/d/A8ULVDTmz/correnteza-datomic-extractor-service?orgId=1&var-stack_id=All&var-host=All&var-database=skyler&var-prototype=s0&var-prometheus=prod-thanos
[correnteza-extractor-dashboard-img]: images/correnteza_extractor_dashboard_highlighted.png
