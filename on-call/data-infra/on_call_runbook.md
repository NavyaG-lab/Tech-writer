---
owner: "#data-infra"
---

<!-- markdownlint-disable-file-->

# On-Call Runbook

- [On-Call Runbook](#on-call-runbook)
  - [Incident response](#incident-response)
  - [Alarms](#alarms)
    - [alert-itaipu-contracts triggered on Airflow](#alert-itaipu-contracts-triggered-on-airflow)
      - [Check reason for the failure](#check-reason-for-the-failure)
      - [Restart the task](#restart-the-task)
      - [Checking errors directly in Airflow](#checking-errors-directly-in-airflow)
    - [Alph - No file upload in the last hour](#alph---no-file-upload-in-the-last-hour)
      - [Solution](#solution)
    - [Alph - kafka lag above threshold](#alph---kafka-lag-above-threshold)
      - [Solution](#solution-1)
    - [Correnteza database-claimer is failing](#correnteza-database-claimer-is-failing)
    - [Correnteza attempt-checker is failing](#correnteza-attempt-checker-is-failing)
    - [Barragem - segment handling time above threshold](#barragem---segment-handling-time-above-threshold)
      - [Solution](#solution-2)
    - [Barragem - segment processing errors](#barragem---segment-processing-errors)
      - [Overview](#overview)
      - [Troubleshooting](#troubleshooting)
      - [Solution](#solution-3)
      - [Escalation](#escalation)
    - [Barragem - not receiving requests from scheduler](#barragem---not-receiving-requests-from-scheduler)
      - [Overview](#overview-1)
      - [Troubleshooting](#troubleshooting-1)
      - [Solution](#solution-4)
      - [Escalation](#escalation-1)
    - [Warning: [PROD] correnteza_last_t_greater_than_basis_t](#warning-prod-correnteza_last_t_greater_than_basis_t)
      - [Context](#context)
      - [Solution](#solution-5)
      - [Delete all the extractions for the databases that the alarm is going off for](#delete-all-the-extractions-for-the-databases-that-the-alarm-is-going-off-for)
      - [Cycle Correnteza in the corresponding prototype](#cycle-correnteza-in-the-corresponding-prototype)
      - [Monitor re-extractions](#monitor-re-extractions)
  - [Itaipu/Aurora/Mesos/Spot: Job has not accepted any resources](#itaipuauroramesosspot-job-has-not-accepted-any-resources)
    - [Alert Severity](#alert-severity)
    - [Overview](#overview-2)
    - [Verification](#verification)
    - [Solution](#solution-6)
  - [Itaipu OutOfMemory error](#itaipu-outofmemory-error)
    - [Alert Severity](#alert-severity-1)
    - [Overview](#overview-3)
    - [Verification](#verification-1)
    - [Troubleshooting](#troubleshooting-2)
    - [Solution](#solution-7)
    - [Escalation](#escalation-2)
    - [Relevant links](#relevant-links)
  - [No space left on device](#no-space-left-on-device)
    - [Symptoms](#symptoms)
    - [Solution](#solution-8)
    - [Dagao is using an out-of-date version of itaipu's release branch](#dagao-is-using-an-out-of-date-version-of-itaipus-release-branch)
      - [Context](#context-1)
      - [Solution](#solution-9)
  - [Escafandro - responses with empty data points above threshold](#escafandro---responses-with-empty-data-points-above-threshold)
    - [Overview](#overview-4)
      - [Alert Severity](#alert-severity-2)
    - [Verification](#verification-2)
    - [Troubleshooting](#troubleshooting-3)
    - [Solution](#solution-10)
    - [Escalation](#escalation-3)
    - [Relevant links](#relevant-links-1)
  - [Frequent dataset failures](#frequent-dataset-failures)
    - [Leaf dataset is failing because of bad definition](#leaf-dataset-is-failing-because-of-bad-definition)
      - [Symptoms](#symptoms-1)
      - [Solution](#solution-11)
      - [Notes](#notes)
    - [Dataset partition not found on s3](#dataset-partition-not-found-on-s3)
      - [Symptoms](#symptoms-2)
      - [Solution](#solution-12)
  - [Aurora "More than one prod-dagao running"](#aurora-more-than-one-prod-dagao-running)
    - [Overview](#overview-5)
      - [Alert Severity](#alert-severity-3)
    - [Verification](#verification-3)
    - [Solution](#solution-13)
    - [Escalation](#escalation-4)
  - [Issues related to services](#issues-related-to-services)
    - [Queued Jobs in PENDING state - aurora web UI](#queued-jobs-in-pending-state---aurora-web-ui)
      - [Symptom](#symptom)
      - [Solution](#solution-14)
    - [Non-responsive Aurora](#non-responsive-aurora)
      - [Symptom](#symptom-1)
      - [Solution](#solution-15)
    - [Airflow: Dagão run failed](#airflow-dagão-run-failed)
      - [Diagnosis](#diagnosis)
      - [Solution](#solution-16)
    - [Decrease in row count on databases](#decrease-in-row-count-on-databases)

This document is a resource for engineers *on-call*.

The general layout of the Alerts part is “alert, reason, action”. All the alert entries here should be linked with the alerts being dispatched from our alerting platform. The "ALERT" string should be verbatim the same string that is dispatched.

The frequent dataset failures should enumerate the symptoms of the particular failure, along with the best known way to mitigate it. Links to Slack threads about the previous failures are appreciated for traceability.

*Before contributing, please keep in mind [the following guidelines](/writing_runbooks.md).*

## Incident response

The Data Infra issue response procedure is loosely modelled after [Nubank's incident response procedure](https://github.com/nubank/playbooks/blob/master/incident-response/incident-response-procedure.md). The reason that it's different is that Data Infra issues are mostly of the [severity levels](https://github.com/nubank/playbooks/blob/master/incident-response/incident-severity-levels.md) SEV-4 or SEV-5.

When an issue arises, it is expected that you mention the failure, communicate updates and actions taken in [#data-crash](https://nubank.slack.com/messages/CE98NE603/). This allows people to follow along and contribute suggestions.

For serious incidents, also perform these steps:

- find someone to actively communicate updates about the incident, referred to as the "comms" person. if you're alone, you can take that role.
- you are the "point" person, which means you're the first responder and primary person acting on the issue
- change the [#data-crash](https://nubank.slack.com/messages/CE98NE603/) channel topic to ":red_circle: -short description of the failure- | point:  -your-name- comms: -comms-person-" e.g. "itaipu-dimensional-modeling not finishing"
- move any discussions about the issue to this channel (no need for threads)
If the incident affects the time which data will be available for users at Nubank, or availability of some user-facing service (e.g. BigQuery, Looker, Belo Monte, Databricks), post a short message about what is being affected in [#data-announcements](https://nubank.slack.com/messages/C20GTK220/). This way, users know we are aware of the issue. Note that this channel serves a wider audience than engineers, so describe the issue in plain terms and at a high level.

After the incident has been taken care of and resolved, change the topic back to ":green_circle:" (and post an update for users in #data-announcements, if applicable).

## Alarms

### alert-itaipu-contracts triggered on Airflow

This means the first task in our daily DAG failed. This task is a dependency
to all the rest of the DAG, so it's important that it runs smoothly and
on time in order for us to meet our SLA.

_You need VPN access to follow the steps below._

#### Check reason for the failure

Check what was the reason for the failure, by following these steps:

1. Access [](https://cantareira-stable-aurora-scheduler.nubank.com.br:8080/scheduler/jobs/prod/itaipu-contracts?jobView=history)
1. You'll see the past instances of that task. Check if the first entry has failed around the time you got the alarm. If this entry indicates the task finished too long ago (15-23 hours ago), that was the previous run. That means the task was failed to be created in Aurora. In this case, refer to the section further below [Checking errors directly in Airflow](#checking-errors-directly-in-airflow).
1. To see the logs, click on the link that is an IP address that starts like `10.` ![image](https://user-images.githubusercontent.com/1674699/37596958-2dd3da18-2b7e-11e8-8b12-9ea541753656.png)
1. Click the `stderr` link in the right end of the screen that will appear. `stdout` might also have useful info.
1. Check the logs for any errors you can read, in some cases there could be an error message or an exception type that makes it clear what is the specific cause for the failure.
1. Check the `#crash` channel in Slack for possible ongoing outages that might cause the DAG run to fail.
1. If you are not sure what is the cause for the failure, or you are not sure what to do about it, jump to the next step which is to restart the task.

> If there is no content in that page or if you get a connection error, that means the task host machine is down and we can't get to the logs that way. In this case, we need to resort to Splunk. Use [this search](https://nubank.splunkcloud.com/en-US/app/search/etl_job_logs?form.the_time.earliest=-60m%40m&form.the_time.latest=now&form.search=*&form.job=aurora%2Fprod%2Fjobs%2Fitaipu-contracts)

#### Restart the task

1. Access https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao
1. You'll see the state of the entire DAG in this page. The status of each node in the graph is represented by its stroke color. There is a reference on the upper right corner. In this specific scenario, the first node named `itaipu-contracts` should have a red stroke color.
1. Click on the `itaipu-contracts` node, and you will see a pop-up appear with some buttons. Click the "Clear" button (dark green), while making sure the "Downstream" and "Recursive" options are pressed (which means enabled) beside it.
_What you just did is "clearing" the state of the node. This will effectively make Airflow try to figure out the next steps to try to get the state to a "succeeded" state, which is first transitioning into a "running" state by executing the task_
1. After a few seconds, the node stroke color should be back to light green. If not, refresh the graph view after a few seconds via the refresh button in the upper-right corner.

After executing these steps, there is a possibility that the task fails once more. In this case, escalate to the next layer of on-call and coordinate with another engineer to figure out next steps.


#### Checking errors directly in Airflow

It is possible that a failure happens before the task is created in Aurora, and the usual case is lack of credentials to access the aurora API. To verify that:

1. Access https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao
1. Click on the `itaipu-contracts` node in the graph, and you will see a pop-up appear. Click "Zoom into Sub DAG".
1. In the graph that will appear, click the `itaipu-contracts` node. Then, click "View Log".
1. You'll be seeing the log of the last attempt to start that task. If there was a failure, you'll see a stack trace, and right before that, a line that starts with:

`
{base_task_runner.py:98} INFO - Subtask: [2018-03-22 00:32:36,584] {create.py:52} ERROR - job failed with status FAILED and message [...]
`

- What is logged after "status FAILED and message <message>" is the reason why the task failed. If it reads simply `Task failed`, that means the task was started in Aurora, but the actual failure should be inspected via the Aurora logs. For that, jump back to the [Check reason for the failure](#check-reason-for-the-failure) step for this alarm.
- In other cases, you might see a message such as: `Subtask: 401 Client Error: Unauthorized for url`. This means there was an error fetching credentials to talk to the Aurora API. Restarting the task should be enough. To achieve that, follow the steps in the [Restart the task](#restart-the-task) section above.

### Alph - No file upload in the last hour

This alert means that [Alph](https://github.com/nubank/alph) is not properly consuming, batching and uploading incoming messages.

#### Solution
- First, check on Grafana if that's really the case [Grafana Dashboard](https://prod-grafana.nubank.com.br/d/000000301/dataset-series-ingestion)
- If that's the case and files upload is actually 0 in the last couple hours you should cycle alph, `nu k8s cycle global alph`
- After a while check if it gets back to normal.
- If it doesn't start working again, check for further exceptions on Splunk.

### Alph - kafka lag above threshold

This alert means that [Alph](https://github.com/nubank/alph) is not consuming messages on at least one partition on the prototype. This is usually caused by one of two things: either Alph is under-provisioned, or one of the consumers/partitions got temporarily stuck somehow. A third event that can create a significant lag, which is related to the previous one, is that we might have a series whose messages are too big and therefore are not being processed.

#### Solution

Open [Alph Grafana Dashboard](https://prod-grafana.nubank.com.br/d/000000301/dataset-series-ingestion) as well as the [Kubernetes CPU and Memory dashboard](https://prod-grafana.nubank.com.br/d/000000268/kubernetes-cpu-and-memory-pod-metrics?orgId=1&from=now-6h&to=now&refresh=1m&var-PROMETHEUS=prod-thanos&var-namespace=default&var-container=nu-alph&var-PROTOTYPE=All&var-stack_id=All). Make sure to correctly set the prototype to whatever prototype is alarming on both dashboards.

- First, check on the Kubernetes dashboard for frequent restarts; this is usually visible for example on the memory usage graph where you'll see a lot of new lines appearing through time as new processes are added. Under normal circumstances the memory usage lines should be mostly stable.
- If there are frequent restarts, check the memory usage of the pods (both average and per pod) on the same dashboard to see whether Alph may be under-provisioned on that shard. If it is, you'll need to bump memory by submitting a PR on [definition](https://github.com/nubank/definition) or, if you want to go fast or if there isn't anyone around to approve your PR, directly by editing the k8s deployment with `nu-"$country" k8s ctl --country "$country" --env "$env" "$prototype" -- edit deploy "$env-$prototype-$stack-alph-deployment"`.
- If there are no restarts, the next step is to check directly the alph dashboard to see if the issue is occuring on all partitions or only on a single one. Usually if the issue is not due to provisioning, there'll be a single stuck partition. In this case the fix is to cycle alph: `nu-$country k8s cycle --env prod $prototype alph`. It'll take some time for processing to resume, usually between 10 minutes and an hour, but you should eventually see a dip in the lag.

### Correnteza database-claimer is failing

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

### Correnteza attempt-checker is failing

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

### Barragem - segment handling time above threshold

This alert means that [Barragem](https://github.com/nubank/barragem) is not able to process segments in time (10 minutes SLO), for at least one prototype and one database. This can mean that big or faulty segments are being submitted to Barragem (e.g. files generated on a backfill job were too big and may be slowing down Barragem overall) or the service is under provisioned.

#### Solution

- First, check Splunk for any errors or big delays using `source=barragem error` or `source=barragem timing_ms>600000` (you can also specify a prototype by adding `prototype=s0` to the query, for example). Any exception here may indicate faulty segments or integration issues with other components (ex: AuroraDB). This [troubleshooting] playbook section can be consulted for more info about possible errors at this point. If there are no exceptions or errors, continue to the steps below.
- Then, open the [Barragem Grafana Dashboard](https://prod-grafana.nubank.com.br/d/ApXjNMwZk/barragem) as well as the [Kubernetes CPU and Memory dashboard](https://prod-grafana.nubank.com.br/d/000000268/kubernetes-cpu-and-memory-pod-metrics?orgId=1&refresh=1m&var-PROMETHEUS=prod-thanos&var-namespace=default&var-container=nu-barragem&var-PROTOTYPE=All&var-stack_id=All). Make sure to correctly set the prototype to whatever prototype is alarming on both dashboards. Check the service resource comsumption on the Kubernetes dashboard. If the pods are caped on CPU or RAM, seems unresponsive, or if there are frequent restarts, Barragem may be under-provisioned on the observed shard. In this case, you'll need to bump resources (CPU and/or memory) by submitting a PR on [definition](https://github.com/nubank/definition/blob/master/resources/br/services/barragem.edn) or, if you want to go fast or if there isn't anyone around to approve your PR, you can bump resources directly by editing the k8s deployment with `nu-"$country" k8s ctl --country "$country" --env "$env" "$prototype" -- edit deploy "$env-$prototype-$stack-barragem-deployment"`. For example, for the `global` prototype on `br`, and the `staging` env: `nu-br k8s ctl --country br --env staging global -- edit deploy staging-global-blue-barragem-deployment`
- If there are no restarts, the next step is to check [AuroraDB dashboard on AWS](https://sa-east-1.console.aws.amazon.com/cloudwatch/home?region=sa-east-1#dashboards:name=barragem_aurora) (pay attention to check the AWS account on the correct country) to see if the database instances is struggling for resources, which would affect write- and read-throughput and thus slow-down the processing of segments. If this is the case, you will need to bump the size of the writer DB instance by clicking on the _Modify_ button on the [prod-global-barragem-aurora-instance](https://sa-east-1.console.aws.amazon.com/rds/home?region=sa-east-1#database:id=prod-global-barragem-aurora-instance;is-cluster=false) dashboard. Bump one or more instance types and evaluate if it was of any help.

### Barragem - segment processing errors

#### Overview

This error means Barragem is not being able to process a given Correnteza segment from a given datomic database. This also means that the streaming contract is not being processed correctly, and therefore the BigQuery table is not being updated.

#### Troubleshooting

The best way to troubleshoot and better understand what is happening, is by using [Splunk](https://nubank.splunkcloud.com/en-GB/app/launcher/home). Initially you should be looking for ["error-processing-segment" errors](https://github.com/nubank/barragem/blob/master/src/barragem/diplomat/consumer.clj#L76), i.e., `source=barragem "error-processing-segment" "acquisition"`.
Alternatively you can look for "barragem.diplomat.consumer/exception-consuming", i.e., `source=barragem "barragem.diplomat.consumer/exception-consuming"`, this will give you the whole stack trace and allow you to find the root cause.

#### Solution

If a bug is found, a fix needs to be put in place as soon as possible. BQ tables are not being updated and we are breaking the streaming contacts 1h SLO.

#### Escalation

Please consider informing our users (#data-announcements) about the ongoing issue.

### Barragem - not receiving requests from scheduler

#### Overview

This error means that Barragem is not able to receive requests from the scheduler (currently, [Tempo](https://github.com/nubank/tempo)) for a certain amount of time. As consequence, missing those requests will make Barragem not consume new files deployed by Correnteza and no contract will be update meanwhile.

#### Troubleshooting

This problem can be caused by either issues or down times on Tempo, or by problems while receiving Tempo requests on Barragem side. You can the check logs of both components by using [Splunk](https://nubank.splunkcloud.com/en-GB/app/launcher/home), where you should look for exceptions of any kind, i.e., `source=tempo OR source=barragem exception`.

#### Solution

If a bug is found on Barragem side, a fix needs to be put in place as soon as possible. BQ tables are not being updated and we are breaking the streaming contacts 1h SLO.

#### Escalation

Please consider informing Foundation (#foundation-tribe) in case of any issue on Tempo side.

### Warning: [PROD] correnteza_last_t_greater_than_basis_t

#### Context

Correnteza tracks the extractions from the Datomic databases by storing the `last-t`
that it extracted from each of those databases.
The actual last `t` stored on those databases is referred to as `basis-t` in Correnteza.
This alarm goes off when Correnteza thinks that it is ahead of the original database, which
means that it won't extract any new data from that database.

The condition described above seems impossible to reach, and so far, it has only happened when
people destroy and re-create databases for the production services.

#### Solution
Note that this solution only applies for the cases described above, **so please confirm
with the service owners that the database was re-created**.

The solution involves 3 steps:

#### Delete all the extractions for the databases that the alarm is going off for

There is an admin endpoint in Correnteza exactly for this purpose, but it's protected with
the scope `correnteza-extraction-delete`.
If you have to execute this command, make sure to ask for this scope in #access-request.

```bash
# parameterised with database name (skyler) and prototype (s0)
nu ser curl DELETE --env prod s0 correnteza /api/admin/extractions/s0/skyler -- -v
```

The command runs asynchronously, so the expected response is `HTTP 202 Accepted`. To check if
the extractions were actually deleted, query the [Correnteza docstore](https://sa-east-1.console.aws.amazon.com/dynamodb/home?region=sa-east-1#tables:selected=prod-correnteza-docstore;tab=items) in the AWS console. To check the items corresponding to the command above, the filter would
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
[Correnteza's extractor dashboard](https://prod-grafana.nubank.com.br/d/A8ULVDTmz/correnteza-datomic-extractor-service?orgId=1&var-stack_id=All&var-host=All&var-database=skyler&var-prototype=s0&var-prometheus=prod-thanos) on Graphana.

![Correnteza extractor dashboard](/images/correnteza_extractor_dashboard_highlighted.png)

The dashboard has a lot more useful information about Correnteza's extractions, but the
important bits for this purpose are highlighted in the screenshot.

[correnteza-extractor-dashboard]: https://prod-grafana.nubank.com.br/d/A8ULVDTmz/correnteza-datomic-extractor-service?orgId=1&var-stack_id=All&var-host=All&var-database=skyler&var-prototype=s0&var-prometheus=prod-thanos

## Itaipu/Aurora/Mesos/Spot: Job has not accepted any resources

### Alert Severity

Critical

### Overview

This error indicates that the cluster has insufficient resources to run the current job; This is usually related to a scale up issue, i.e., Spot not being able to spin on-demand instances in a certain availability zone.

### Verification

In order to verify this, you should
1) Open the Aurora logs, and you will probably see several messages like this one `job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources`. This means that there are no nodes available to run the current job on.
2) Open the Spot UI and look at the logs from the faulty job (Okta -> Spotinst -> Elasticgroup -> Groups -> filter by job name, for example `itaipu-brando` -> Log -> select the time period), and you might see something like `08/26/2020, 18:44:02, ERROR, Can't Spin On-Demand Instance: Code: InsufficientInstanceCapacity, Message: We currently do not have sufficient r5.4xlarge capacity in the Availability Zone you requested (us-east-1c). Our system will be working on provisioning additional capacity. You can currently get r5.4xlarge capacity by not specifying an Availability Zone in your request or choosing us-east-1a, us-east-1b, us-east-1d, us-east-1f.` This indicates that `Spot` is not working as expected and failing to create on demand instances.

### Solution

Since a random AZ is selected every time we run a scale-up job, re-triggering the entire Airflow SubDag from scratch will hopefully fix it.

## Itaipu OutOfMemory error

### Alert Severity

Soft alert.

### Overview

While computing a dataset, an Itaipu node fails with `java.lang.OutOfMemoryError`. This error is usually thrown during a Spark stage when there are insufficient resources to process said dataset. It is a Soft Alert because **usually**, these datasets get eventually computed and succeed, as they end up running on a different node.

### Verification

The OOM check runs every hour, and we get alerted only once - within a 45 minute window - per job name. The issue is still ongoing if we get subsequent alerts for the same job name, 45m after the first one.
If OOM happens in two jobs within the 45m window, two alerts - one per each job - are sent.

### Troubleshooting

First things first, we are going to need to understand which dataset has failed, and you can do this by parsing the Itaipu logs (*stderr* from the Aurora page). This is not very straightforward, because multiple threads log to that file, and for that reason, it might not be easy to identity which dataset is the culprit, but you should at least be able to narrow it down to a few candidates.

And now, it is time to understand if said dataset was already committed (potentially in different node), by running, for example, `nu-br etl info <dataset-name>`, e.g., `nu-br etl info nu-br/dataset/customer-eavt-pivotted`; if yes, you should still warn the users (see the Escalation section), informing them that the dataset failed, and that its stability might not be the best.

### Solution
Even though sometimes no action needs to be taken (as the dataset often succeeds in a different node), **you should consider committing the faulty dataset empty if it keeps failing, and a critical part of the run is getting blocked by it.**
Something else worth trying is to isolate the faulty dataset in a different node, i.e., `itaipu-other-flaky-datasets`, and see if its behaviour changes during the next run.

Most of the time, our users are the ones coming up with the long term solutions for these kind of problems, and it usually involves them optimizing their SparkOP or even breaking it down in multiple ones.

We do have one known event that can cause these issues, and that we can try to solve on our side: a combination of a Spark listener event queue being too big (we control their size) for a given job, and an issue with a Dataset - user behaviour, this can cause the node to OOM and we can try to fix it by reducing the size of the queue. We do this by changing a variable called `spark_listener_bus_capacity` inside `dagao.py`. You can set a smaller value in the order of tens of thousands. The default set by Spark is 10k. You must hot deploy `dagao` if you want these changes to take effect right away.

### Escalation
If the problem is found to originate from user behaviour, we should leave a message in #data-tribe, informing our users that a specific dataset(s) is having OOM issues. We should inform them that the dataset succeeded on a different node, but that we are concerned about its long term stability. Please follow our [communication templates](https://docs.google.com/document/d/1L5MwBH2OZ0uvr5sTHG-LrLQTFRtx44Az8HyeN46rnc8/edit). They should investigate.

### Relevant links

* https://spark.apache.org/docs/latest/configuration.html, `spark.scheduler.listenerbus.eventqueue.capacity` field.

## No space left on device

### Symptoms

No real symptoms. This alert directly points to the real cause: one or
more EC2 instances running Spark Executors are out of disk space.

### Solution

  * Consider decreasing the workload. For example if the job is a periodic
    maintenance job like `pollux-auto` consider [decreasing the number of databases](https://github.com/nubank/castor/blob/master/resources/castor_config.json.base)
    it updates the cache for at a time, as long it can still maintain the service
    SLO.
  * Change the storage class for the instances assigned to that job in
    `aurora-jobs`. See [this
    PR](https://github.com/nubank/aurora-jobs/pull/1232) for an
    example. Please note: at the time of the PR, we had three storage
    classes defined: `low`, `standard`, `high`. Also, see [this Slack
    thread](https://nubank.slack.com/archives/CP3F163C4/p1591794519178600)
    to trace back to the context leading to that PR.
  * If the job is critical, run it manually with this override.

### Dagao is using an out-of-date version of itaipu's release branch

#### Context

The alert is telling us that the version being deployed is different
from the current top of the tree in Itaipu’s `release` branch. For
more context see [How Itaipu is deployed to the
Dagao](/itaipu/workflow.md#how-itaipu-is-deployed-to-the-dagao).

#### Solution

  * Set release back to the correct version
      * If we know there were no hotdeploys that day, we can get the
        correct release from
        [`#etl-updates`](https://nubank.slack.com/archives/CCYJHJHR9/p1597104023128200),
        otherwise the user should go check out the commit history to
        find the latest commit for that day's run.
      * And use it to revert the `release` branch to that value.
  * Push the changes and wait for the `dagao` pipeline to finish.
  * Once it’s done, trigger a hot-deploy by triggering the gated step
    in `dagao`, i.e. [the `>|>` arrow after the `create-release`
    step](https://go.nubank.com.br/go/tab/pipeline/history/dagao).
  * Restart the failing jobs
      * Kill the job with `nu-<country> datainfra sabesp -- --aurora-stack <stack-name> jobs kill jobs prod <job-name>`
      * [Clear the nodes in Airflow](/airflow.md#triggering-a-DAG-vs-clearing-a-DAG-and-its-tasks)

  * Change the storage class for the instances assigned to that job in
    `aurora-jobs`. See [this
    PR](https://github.com/nubank/aurora-jobs/pull/1232) for an
    example. Please note: at the time of the PR, we had three storage
    classes defined: `low`, `standard`, `high`. Also, see [this Slack
    thread](https://nubank.slack.com/archives/CP3F163C4/p1591794519178600)
    to trace back to the context leading to that PR.
  * If the job is critical, run it manually with this override.

## Escafandro - responses with empty data points above threshold

Escafandro - responses with empty data points above threshold

### Overview

The purpose of this alert is to hint On-Call Engineers that there are more responses with empty datapoints than expected. This means that Itaipu is not being provided with enough data to perform `(Strictly)IncreasingRowCountCheck` checks, an anomaly check that helps our users to make sure the output of our ETL is behaving in a sane manner.

#### Alert Severity

Soft alert.

### Verification

To verify whether there is an on-going situation, access [Escafandro Monitoring](https://prod-grafana.nubank.com.br/d/b3gOJwFMz/escafandro-monitoring?orgId=1)  Grafana dashboard, more especifically checking the [Range Endpoint - Empty Responses](https://prod-grafana.nubank.com.br/d/b3gOJwFMz/escafandro-monitoring?orgId=1&viewPanel=2) chart. This dashboard gives you an overview of empty responses that Escafandro usually sends back to Itaipu. One reasonable explanation for empty responses to be provided is when a new dataset is added to the ETL. Once this happens, Escafandro will not have any datapoints for the very first run of the recently-added dataset.

### Troubleshooting

Before jumping into problem solving mode, it's important to understand whether there actually is something to be fixed in the current situation.

One important aspect to keep in mind is the fact that many new datasets might have been added to the ETL at the same day, and since Escafandro will not have historical metrics about these, there is nothing that can be done about it.
One way to check whether this is the case, you can collect the name of some dataset samples using the following search query in Splunk: `source=escafandro "metric-query-response" ":datapoints ()"`

To kick-start troubleshooting this, your first stop is again accessing [Escafandro Monitoring](https://prod-grafana.nubank.com.br/d/b3gOJwFMz/escafandro-monitoring?orgId=1) Grafana dashboard. Compare the [Persist Endpoint - Metric created](https://prod-grafana.nubank.com.br/d/b3gOJwFMz/escafandro-monitoring?orgId=1&viewPanel=4) pane with the [Range Endpoint - Empty Responses](https://prod-grafana.nubank.com.br/d/b3gOJwFMz/escafandro-monitoring?orgId=1&viewPanel=2). There should be an inversely proportional relationship between the number of metrics created vs the number empty datapoint responses. Meaning, the less metrics being created on a given day the higher is the likelyhood of the number of empty datapoints response on the upcoming day. E.g., On 1st October if `nu-br/important-dataset` does not create metrics, the execution of `nu-br/important-dataset` on 2nd October will return empty datapoints.

So, look for possibly big gaps in the metrics creation over the past days. If that's the case, you might have to start digging into why did this happen by checking the following Grafana dashboards:
- [Datomic Transactor Metrics](https://prod-grafana.nubank.com.br/d/XbZytFTWk/datomic-transactor-metrics?orgId=1&var-PROMETHEUS=prod-thanos&var-PROTOTYPE=All&var-TRANSACTOR=escafandro-1-datomic)
- [Kubernetes CPU and Memory pod metrics](https://prod-grafana.nubank.com.br/d/000000268/kubernetes-cpu-and-memory-pod-metrics?orgId=1&refresh=1m&var-PROMETHEUS=prod-thanos&var-namespace=default&var-container=nu-escafandro&var-PROTOTYPE=All&var-stack_id=All)
- [JVM by Service](https://prod-grafana.nubank.com.br/d/000000276/jvm-by-service?orgId=1&var-ENVIRONMENT=prod&var-PROMETHEUS=prod-thanos&var-SERVICE=escafandro&var-PROTOTYPE=global&var-STACK_ID=All&var-POD=All)
- [Escafandro Monitoring - Custom metrics](https://prod-grafana.nubank.com.br/d/b3gOJwFMz/escafandro-monitoring?orgId=1)

It's also possible to use Splunk to assert [Escafandro](https://github.com/nubank/escafandro/)'s behavior from the perspective of the consumer of the API, in this case [Itaipu/Mergulho](https://github.com/nubank/itaipu/). [This link](https://nubank.splunkcloud.com/en-US/app/search/search?q=search%20index%3Dcantareira%20step%3DCheckAnomaliesUsingMetricValues&display.page.search.mode=verbose&dispatch.sample_ratio=1&earliest=-24h%40h&latest=now&sid=1602083082.13899927_441E883E-2B06-437D-97A4-B78C146189E2) should take you to Splunk with the following initial search query `index=cantareira step=CheckAnomaliesUsingMetricValues`. From there, one can refine the search to validate potential hypothesis. E.g. Is the anomaly check being correctly performed over the critical dataset `xyz`? If not, it's worth escalate to the owners of the datasets. (see: [Escalation](#escalation-2) section)

### Solution
As mentioned above, there might be cases where too many new datasets might have been added on the same day, and therefore there is nothing to worry about.

In case this alert is firing too ofen throughout the days, It could mean that the threshold set for this alert is too low and we should consider increasing it.
The current state of this alert can be found [here](https://github.com/nubank/definition/blob/master/resources/alert-templates/escafandro-empty-data-points-above-threshold.edn).

If it has not been possible to draw any conclusion about the actual problem by checking the above mentioned elemets for troubleshooting, you might have to look for recent changes over either [Escafandro](https://github.com/nubank/escafandro/) or [Itaipu/Mergulho](https://github.com/nubank/itaipu/).

### Escalation

Whenever you find yourself in doubt, escalating to the L2 Engineer should be your first step.

As mentioned in the [Troubleshooting](#troubleshooting-2) section above, in case we clearly detect issues from any of the infrastructure resources like Datomic or Kubernetes, the escalation path should be reaching out to Foundation tribe through their Slack channel `#foundation-tribe`

**Important**: Ensure that you inform our users via #data-announcements slack channel about the ongoing issue.

### Relevant links

Escafandro's relevant links are:
- [README](https://github.com/nubank/escafandro/)
- [Datomic Transactor Metrics](https://prod-grafana.nubank.com.br/d/XbZytFTWk/datomic-transactor-metrics?orgId=1&var-PROMETHEUS=prod-thanos&var-PROTOTYPE=All&var-TRANSACTOR=escafandro-1-datomic)
- [Kubernetes CPU and Memory pod metrics](https://prod-grafana.nubank.com.br/d/000000268/kubernetes-cpu-and-memory-pod-metrics?orgId=1&refresh=1m&var-PROMETHEUS=prod-thanos&var-namespace=default&var-container=nu-escafandro&var-PROTOTYPE=All&var-stack_id=All)
- [JVM by Service](https://prod-grafana.nubank.com.br/d/000000276/jvm-by-service?orgId=1&var-ENVIRONMENT=prod&var-PROMETHEUS=prod-thanos&var-SERVICE=escafandro&var-PROTOTYPE=global&var-STACK_ID=All&var-POD=All)

## Frequent dataset failures
### Leaf dataset is failing because of bad definition

#### Symptoms

  * Any of the steps during running the dataset is failing
  * It's not an environment issue, but purely specific to how the dataset is defined
  * The dataset has been recently modified/introduced


#### Solution
  * Revert the most recent commits modifying the failing datasets along with any other commits that depend on
    those recent changes.
  * [Commit an empty dataset](ops_how_to.md#manually-commit-a-dataset-to-metapod) in place of the failing
    datasets in order to ignore this dataset for the rest of the ETL run.
  * Announce in [#guild-data-eng](https://nubank.slack.com/archives/C1SNEPL5P) about the reverted changes.

#### Notes

  * You should be aware that reverting changes spanning more than one dataset might cause problems if some of
    the datasets have already been committed but are then consumed by the reverted-to earlier versions of the
    other datasets.
  * This solution doesn't apply to non-leaf datasets since then the situation is more complicated and it would
    require different actions based on the kinds of datasets involved.

### Dataset partition not found on s3

#### Symptoms

  * A thrown `java.io.FileNotFoundException: No such file or directory` on a Spark executor for a file on S3.
  * The partition file in question is accounted for in the mentioned bucket via the AWS console web UI (because the AWS CLI is usually unable to find it either), and it has no permissions listed then it's most likely this issue.

Some instances of this happening include:
  - [1] https://nubank.slack.com/archives/CE98NE603/p1566893108104300
  - [2] https://nubank.slack.com/archives/CE98NE603/p1566115955069000?thread_ts=1566105267.068700&cid=CE98NE603
  - [3] https://nubank.slack.com/archives/CE98NE603/p1573363471193700

#### Solution

[Retracting](ops_how_to.md#retracting-datasets-in-bulk) the inputs for the failing datasets in order to recompute the inputs and re-store them on s3 usually fixes it.

## Aurora "More than one prod-dagao running"

### Overview

The purpose of this alert is to hint On-Call Engineers that there is more than one dagao running at the same time, and there is currently a hard cap of 2 running DAGs in Data-Infra's Airflow. Whenever it in this state, we are at risk of not properly scheduling the next day's DAG. If we have a DAG running over into the next day it usually means something is wrong with some jobs and it needs to be addressed.

Let’s say the ETL runs late on day D1, and continues running throughout D2 (maybe due to a node getting stuck). If the D2 run is also late, then at the start of D3 we’ll have already 2 DAGs running (D1 + D2) and so the D3 DAG will not get scheduled.

#### Alert Severity

Soft alert.

### Verification

To verify whether there is an on-going situation, [open the Airflow](https://airflow.nubank.com.br/admin/) running `Dagao`. Notice that the DAG `prod-dagao` will be marked with red. Indicating that there are already two DAGs running at the same time.

![image](../../images/airflow_number_of_active_dags_runs.png)

By clicking at [prod-dagao](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao) link listed in the list of DAGs, you should be able to see the current day running DAG.

### Solution

To prevent Aurora job failing due to name clashes, or even Airflow failing to schedule the following day's DAG, the usual actions required in this case are:
- Inspect the previous day’s DAG to figure out what’s still running
![image](../../images/airflow_previous_day_dag_run.png)
- Identify the remaining running nodes
![image](../../images/airflow_highlight_running_nodes.png)
- Left click on the running node a pop-up will be displayed
- Mark the running node as failed
![image](../../images/airflow_mark_as_failed.png)

It may happen that Aurora fails to automatically finish some of the scheduled or running jobs. If needed, manually kill jobs that are still running by using `nu-br datainfra sabesp -- --aurora-stack cantareira-stable jobs kill jobs prod name.of.the.running.job`

Alternatively, one can also perform the same through Spotinst UI by accessing the service through your Okta account.

### Escalation

Whenever you find yourself in doubt, escalating to the L1 or L2 Engineer should be your first step.

## Issues related to services


### Queued Jobs in PENDING state - [aurora web UI](https://cantareira-stable-aurora-scheduler.nubank.com.br:8080)

#### Symptom

[aurora web UI](https://cantareira-stable-aurora-scheduler.nubank.com.br:8080) leaving tasks in PENDING state for more than 20 minutes. Currently, we don't have a mechanism to detect the Aurora Jobs in PENDING state for long time and indicate the hausmeister about it.

#### Solution

1. SSH into aurora-scheduler, via `nu ser ssh aurora-scheduler --suffix stable --env cantareira --region us-east-1` and look at the aurora logs via `journalctl -u aurora-scheduler` to find out why the jobs are not being scheduled. Often these will be in the form of exceptions.
2. If the logs seem normal, kill one of the pending jobs via sabesp. Run the following to kill each job:

    `nu datainfra sabesp -- --aurora-stack cantareira-stable jobs kill jobs prod <job-name>`
3. Do a sanity check to ensure that no job is scheduled.
4. If the issued is not fixed using the above steps, [Restart Mesos](ops_how_to.md#restart-aurora)
4. If the issue still persists, [restart Aurora](ops_how_to.md#restart-aurora). It takes ~5 mins to resume the jobs.
5. If the jobs are not resumed, then [restart Airflow](/airflow.md#restarting-the-airflow-process).

**Important** The result of restarting aurora is an orphaned mesos framework. You must delete orphan mesos frameworks as indicated in the [Operations Cookbook](ops_how_to.md#restart-aurora) doc.

### Non-responsive Aurora

Every once in a while, Aurora goes down. `sabesp` commands, such as ones involved in running the DAG, won't work in this case.

#### Symptom

- The [aurora web UI](https://cantareira-stable-aurora-scheduler.nubank.com.br:8080) does not load, but the [mesos web UI](https://cantareira-stable-mesos-master-bypass.nubank.com.br) does.

#### Solution

1. SSH into `aurora-scheduler`, via `nu ser ssh aurora-scheduler --suffix stable --env cantareira --region us-east-1` and look at the aurora logs via `journalctl -u aurora-scheduler` to find out why the jobs are not being scheduled. Often these will be in the form of exceptions.
2. If the logs seem normal, kill one of the pending jobs via sabesp. Run the following to kill each job:

`nu datainfra sabesp -- --aurora-stack cantareira-stable jobs kill jobs prod <job-name>`

3. [Restart Mesos](ops_how_to.md#restart-aurora).
4. If the issue still persists, [restart Aurora](ops_how_to.md#restart-aurora).

### Airflow: Dagão run failed

#### Diagnosis

- Check for errors on the failed aurora tasks.
- Check for recent commits and deploy on Go, to make sure if they are related to the recent commits.
- If nothing seems obvious and you get lots of generic errors (reading non-existent files, network errors, etc), you should then follow the steps in the solution.

#### Solution

 1. Cycle all machines (eg `nu ser cycle mesos-on-demand --env cantareira --suffix stable --region us-east-1`)
 2. Get the transaction id from [#etl-updates](https://nubank.slack.com/archives/CCYJHJHR9/p1538438447000100)
 3. Retry rerunning the dagão with the same transaction (eg `sabesp --verbose --aurora-stack=cantareira-stable jobs create prod dagao --filename dagao "profile.metapod_transaction=$metapod_tx"`)
 4. If that fails, increase the cluster size (eg `sabesp --aurora-stack=cantareira-stable jobs create prod scale  --job-version "scale_cluster=4945885" MODE=on-demand N_NODES=$nodes SCALE_TIMEOUT=0`)
 5. Retry dagão.
 6. If it still doesn't work, rollback to a version that worked and retry dagão.

 ### Decrease in row count on databases

 #### Context

 Sometimes, you will be notified or alarmed about the decrease in row count on production databases, whereas the current run seems to be normal. Some possible reasons for this is, 
 - duplicate rows in the previous day run or 
 - data is deleted from some databases. 
 
Currently, the anomaly detection system checks only for the significant increase in row count and cannot count the duplicate rows / keep track of deleted rows on DB. Even if the current day run is processing well and shows the correct row count, an alarm raises as there is a decrease in row count from previous day to current day.

 #### Reason for duplicate rows

In case the cache creation time in Pollux happens simultaneously at the same time of contracts computation (commit-time of the last contract computed in the run) in Itaipu, there is a time overlap during the run, which led to creating duplicate rows.

#### Diagnosis

1. Check the row count variations of all the affected DBs in Escafandro using the following sample `curl` query:

    `nu-br ser curl GET --env prod global escafandro '/api/metrics/raw-dementor-s6%2Flog/row-count/last-n?count=10&to=2020-11-26' | jq`
1. Then check if the cache creation time in Pollux is same as the contracts computation time.
    - To find the cache creation time (which is stored in castor service), use the following `curl` query:

      `nu-br ser curl GET --env prod global castor /api/active-snapshot/BR/<shard>/<name of the database> | jq .`
    
      Ex - `nu-br ser curl GET --env prod global castor /api/active-snapshot/BR/s6/chargebacks | jq`
    - To find the commit-time of the last contract computed in a day’s transaction, query Metapod using the graphql.

    <pre>
      {
        transaction(transactionId: "<transaction-id>") {
          id
          startedAt
          datasets(
            countries: BR,
            committed: ONLY_COMMITTED
          ) {
            id
            committedAt
            name
          }
        }
      }
    </pre>

      You can find the `transaction-id` in the #etl-updates slack channel.

    - Filter the result and look for the latest `committedAt` value.

      `$.data.transaction.datasets[?(@.name.match(/^contract-/))].committedAt`
    
    or Check the end time of the node in the Airflow.

1. Then, check when the cache is refreshed lately.

If the alarm is raised because of the data deleted from the DBs (as per data deletion requests), consider it as a false alarm.

#### Solution, a Work around:

To avoid the problem that arises due to time overlap, Pollux's cache creation time is changed to 1 pm UTC, whereas the computation of all the contracts is done by 12 pm UTC usually.
