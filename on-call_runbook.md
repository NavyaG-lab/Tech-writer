# On-Call Runbook

This document is a resource for engineers *on-call*.

The general layout of the Alerts part is “alert, reason, action”. All the alert entries here should be linked with the alerts being dispatched from our alerting platform. The "ALERT" string should be verbatim the same string that is dispatched.

The frequent dataset failures should enumerate the symptoms of the particular failure, along with the best known way to mitigate it. Links to Slack threads about the previous failures are appreciated for traceability.

*Before contributing, please keep in mind [the following guidelines](writing-runbooks).*

## Alarms

- [alert-itaipu-contracts triggered on Airflow](#alert-itaipu-contracts-triggered-on-airflow)
- [Correnteza - database-claimer is failing](#correnteza-database-claimer-is-failing)
- [Correnteza - attempt-checker is failing](#correnteza-attempt-checker-is-failing)
- [Riverbend - no file upload in the last hour](#no-file-upload-in-the-last-hour)
- [Warning: [PROD] correnteza_last_t_greater_than_basis_t](#warning-prod-correnteza_last_t_greater_than_basis_t)

## Frequent Dataset Failures
- [Dataset partition not found on s3](#dataset-partition-not-found-on-s3)
- [Leaf dataset is failing because of bad definition](#leaf-dataset-is-failing-because-of-bad-definition)

## alert-itaipu-contracts triggered on Airflow

This means the first task in our daily DAG failed. This task is a dependency
to all the rest of the DAG, so it's important that it runs smoothly and
on time in order for us to meet our SLA.

_You need VPN access to follow the steps below._

### Check reason for the failure

Check what was the reason for the failure, by following these steps:

1. Access https://cantareira-stable-aurora-scheduler.nubank.com.br:8080/scheduler/jobs/prod/itaipu-contracts?jobView=history
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


## No file upload in the last hour

This alert means that [Riverbend](https://github.com/nubank/riverbend) is not properly consuming, batching and uploading incoming messages.

- First, check on Grafana if that's really the case [Grafana Dashboard](https://prod-grafana.nubank.com.br/d/000000301/riverbend)
- If that's the case and files upload is actually 0 in the last couple hours you should cycle riverbend, `nu ser cycle global riverbend`
- After a while check if it gets back to normal, it can take a while (~20 min) as it has to restore the state store.
- If it doesn't start working again, check for further exceptions on Splunk.

## Correnteza database-claimer is failing

If you see a `ops_health_failure` alarm on `#squad-di-alarms` for `component: database-claimer` then you can get more info by running

```bash
nu ser curl GET global correnteza --env prod /ops/health/database-claimer | jq .
```

Usually this means that the database claimer, which is responsible for acquiring zookeeper locks that correspond to datomic databases, has somehow failed to acquire the appropriate number of locks. The claimer state contains two metrics that are important to us: `locked` indicates how many databases this instance of correnteza has acquired, and `lowest_acceptable` indicates how many it needs to acquire to be considered healthy (it's normally the same as the total number of existing databases for this shard). In other words `database-claimer` will be unhealthy when `locked` is below `lowest_acceptable`.

The most common cause is for a given instance of `correnteza` to finish boostrapping before all locks were released. As a result, it reaches a state where it no longer attempts to get new locks, without having acquired all of them.

In this context, the first thing you'll want to do is run:

```bash
nu k8s ctl <prototype> --env prod -- get pods -l nubank.com.br/name=correnteza
```

and verify that there is only a single instance of `correnteza` running for this protoype. If there are two, you will need to either wait for it to get back to a normal number of pods (1 in the current setup), or force a scale down with:

```bash
nu k8s scale <prototype> --env prod correnteza 1 --min 1 --max 1
```

To monitor the scale down, you can use:

```bash
watch -n 10 'nu k8s ctl <prototype> --env prod -- get pods -l nubank.com.br/name=correnteza'
```

Once there's only one instance, and if it's still unhealthy, you can:

- run `nu ser curl POST <prototype> correnteza --env prod /ops/database-claimer/acquire-new` which will schedule a new round of lock acquisition attempts. Depending on how many locks it needs to catch up on, this may take up to 30 minutes. Use `watch -n 10 'nu ser curl GET <prototype> correnteza --env prod /ops/health | jq ".[1].database_claimer.checks"'` to monitor whether the count increases. Remember that you want `locked` to become equal to `lowest_acceptable`

- cycle the service with `nu ser cycle <prototype> correnteza --env prod`. Bear in mind that this has the potential of making correnteza more unstable (due to the above-mentioned issue of having several instances up at the same time), so you really should first attempt the `acquire-new` approach first.

If the above doesn't solve the issue, you may need to dig into which specific locks are not being acquired are not being extracted, using Splunk to find any error messages which may help you understand what's going on, for example with the query: `source=correnteza prototype=<prototype> error`.

## Correnteza attempt-checker is failing

Correnteza has several instances that coordinate via zookeeper to extract from all the datomic databases discovered. If for some reason these instances fail to connect to a datomic database it has extracted from in the past it means that either: there is a bug or the database has been deprecated. In order to check for this we always log in a little docstore when we try to extract from a database. Then every 20 minutes we have a healthcheck that ensures that every database listed in that docstore has had an extraction attempt in the last 10 minutes.

When this healthcheck fails you'll see a `ops_health_failure` alarm on `#squad-di-alarms` for `component: attempt-checker`. For more info run:

```bash
nu ser curl GET global correnteza /ops/health/attempt-checker | jq .[1].attempt-checker
```

The output will give you a list of which databases haven't had any recent extractions. The first thing you can do is to run `nu ser curl POST <prototype> --env prod correnteza /ops/attempt-checker/force` to force a refresh of the component and verify that it wasn't a temporary issue.

If the component is still unhealthy, the first thing you should check is whether the `database-claimer` component may also be unhealthy, using `nu ser curl GET global correnteza --env prod /ops/health/database-claimer | jq .`. If it is the case, then it's very likely the issues may be related, and you should fix the `database-claimer` first. Use the section above about the `database-claimer` to do this. Don't forget to run `nu ser curl POST <prototype> --env prod correnteza /ops/attempt-checker/force` again once you've fixed the `database-claimer` to get the `attempt-checker` into a fresh state.

If/once the claimer is healthy, and if the `attempt-checker` is still failing, you'll need to investigate each database listed in the health-check message individually. The first thing to check is Splunk, using a query such as `source=correnteza prototype=prototype error <database>`. A common thing to look for here is messages indicating issues when attempting to connect to these databases, such as:

- `... :error :connecting, :url "datomic:ddb://sa-east-1/prod-<database>-datomic/<database>" ...`: usually means the table doesn't exist.
- `Could not find <database> in catalog`: usually means the table does exist, but the service is still being bootstrapped and hasn't started transacting anything yet.

You can then look through the commit of the service's repo, or of their definition file for their datomic transactor, to assess whether this is likely a service under construction. You can also ask the owner squad directly (use `nu ser owner <service>` to find out who it is), though depending on the time of the day this may not be the most efficient way to get information.

If you strongly suspect, or discover that the database that isn't being extracted from has been deprecated or isn't really live yet, you can remove it from the attempt checker list:

`nu ser curl DELETE --env prod <prototype> correnteza /api/admin/delete-attempt/<database>`

You can then force the healthcheck to recompute its state via:

`nu ser curl POST <prototype> --env prod correnteza /ops/attempt-checker/force`

If the service in question has been live for a long time, or if you know it to be a critical service AND if the last extraction attempt is more than 1 day old, you should reach out to the owner squad urgently to find out what's going on and work with them to solve the situation.

## Warning: [PROD] correnteza_last_t_greater_than_basis_t

### Context

Correnteza tracks the extractions from the Datomic databases by storing the `last-t`
that it extracted from each of those databases.
The actual last `t` stored on those databases is referred to as `basis-t` in Correnteza.
This alarm goes off when Correnteza thinks that it is ahead of the original database, which
means that it won't extract any new data from that database.

The condition described above seems impossible to reach, and so far, it has only happened when
people destroy and re-create databases for the production services.


### Solution

Note that this solution only applies for the cases described above, **so please confirm
with the service owners that the database was re-created**.

The solution involves 3 steps:

#### Delete all the extractions for the databases that the alarm is going off for.

There is an admin endpoint in Correnteza exactly for this purpose, but it's protected with
the scope `correnteza-extraction-delete`.
If you have to execute this command, make sure to ask for this scope in #access-request.

```bash
# parameterised with database name (skyler) and prototype (s0)
nu ser curl DELETE --env prod s0 correnteza /api/admin/extractions/s0/skyler -- -v
```

The command runs asynchronously, so the expected response is `HTTP 202 Accepted`. To check if
the extractions were actually deleted, query the [Correnteza docstore][correnteza-docstore]
in the AWS console. To check the items corresponding to the command above, the filter would
be `db-prototype = skyler-s0`.

#### Cycle Correnteza in the corresponding prototype

After the extractions are deleted, the next step is to cycle the instances of Correnteza that
are connected to that DB prototype. This is necessary to refresh the `last-t` kept by
Correnteza for that database prototype, which happens at service startup.

Correnteza is sharded and it connects to the databases within the same prototype, so we have
to cycle the same one that we deleted the extractions for.

```bash
# parameterised prototype (s0)
nu k8s cycle s0 correnteza
```

To check the progress of the service cycling, run this command:

```bash
# parameterised with service name (correnteza) and prototype (s0)
watch --differences --interval 10 nu k8s ctl s0 -- get po -l nubank.com.br/name=correnteza
```

#### Monitor re-extractions

After the service has cycled, wait for a few minutes. Correnteza's startup is noticeably
slow because it has to discover and connect to many Datomic databases.
Then, check the status of the Datomic extractor using
[Correnteza's extractor dashboard][correnteza-extractor-dashboard] on Graphana.

![Correnteza extractor dashboard][correnteza-extractor-dashboard-img]

The dashboard has a lot more useful information about Correnteza's extractions, but the
important bits for this purpose are highlighted in the screenshot.

[correnteza-docstore]: https://sa-east-1.console.aws.amazon.com/dynamodb/home?region=sa-east-1#tables:selected=prod-correnteza-docstore;tab=items
[correnteza-extractor-dashboard]: https://prod-grafana.nubank.com.br/d/A8ULVDTmz/correnteza-datomic-extractor-service?orgId=1&var-stack_id=All&var-host=All&var-database=skyler&var-prototype=s0&var-prometheus=prod-thanos
[correnteza-extractor-dashboard-img]: images/correnteza_extractor_dashboard_highlighted.png
[writing-runbooks]: writing_runbooks.md

## Leaf dataset is failing because of bad definition
### Symptoms ###
  * Any of the steps during running the dataset is failing
  * It's not an environment issue, but purely specific to how the dataset is defined
  * The dataset has been recently modified/introduced

### Solution ###
  * Revert the most recent commits modifying the failing datasets along with any other commits that depend on
    those recent changes.
  * [Commit an empty dataset](ops_how_to.md#manually-commit-a-dataset-to-metapod) in place of the failing
    datasets in order to ignore this dataset for the rest of the ETL run.
  * Announce in [#guild-data-eng](https://nubank.slack.com/archives/C1SNEPL5P) about the reverted changes.

### Notes ###
  * You should be aware that reverting changes spanning more than one dataset might cause problems if some of
    the datasets have already been committed but are then consumed by the reverted-to earlier versions of the
    other datasets.
  * This solution doesn't apply to non-leaf datasets since then the situation is more complicated and it would
    require different actions based on the kinds of datasets involved.

## Dataset partition not found on s3
### Symptoms ###
  * A thrown `java.io.FileNotFoundException: No such file or directory` on a Spark executor for a file on S3.
  * The the partition file in question is accounted for in the mentioned bucket via the AWS console web UI (because the AWS CLI is usually unable to find it either), and it has no permissions listed then it's most likely this issue.

Some instances of this happening include:
  - [1] https://nubank.slack.com/archives/CE98NE603/p1566893108104300
  - [2] https://nubank.slack.com/archives/CE98NE603/p1566115955069000?thread_ts=1566105267.068700&cid=CE98NE603
  - [3] https://nubank.slack.com/archives/CE98NE603/p1573363471193700

### Solution ###
[Retracting](https://github.com/nubank/data-platform-docs/blob/master/ops_how_to.md#retracting-datasets-in-bulk) the inputs for the failing datasets in order to recompute the inputs and re-store them on s3 ususally fixes it.
