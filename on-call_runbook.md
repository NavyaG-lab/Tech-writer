# On-Call Runbook

This document is a resource for engineers *on-call*.  The general layout of
this document is Alert: Reasoning: Action(s).  All the alert entries here
should be linked with the alerts being dispatched from our alerting platform.
The "ALERT" string should be verbatim the same string that is dispatched.

## Alarms

- [conrado failed to propagate dataset](#conrado-failed-to-propagate-dataset)
- [tapir failed to load at least one row to DynamoDB in the last 24 hours](#tapir-failed-to-load-at-least-one-row-to-DynamoDB-in-the-last-24-hours)
- [alert-itaipu-contracts triggered on Airflow](#alert-itaipu-contracts-triggered-on-airflow)
- [Deadletter prod-etl-committed-dataset](#deadletter-prod-etl-committed-dataset)

---

## conrado failed to propagate dataset

This means that [conrado](https://github.com/nubank/conrado/) encountered an issue while reading a dataset out of its dynamoDB table and turning it into a series of kafka messages. It is important that most datasets propagate no later than the day they were generated, so this is not 'drop everything' issue, but is important to address quickly.

To get the relavant stack-trace, look at the `TO-PROPAGATE` deadletter on conrado associated with this failure via the [mortician web UI](https://backoffice.nubank.com.br/mortician/).

Ideally the issue can be addressed and the deadletter can be replayed.

For instance, sometimes there is read throttling on the dynamo table. This might come up if by chance two datasets are being propagated at the same time. You can try to increase the capacity of the `conrado` dynamo table on AWS and replay the deadletter.

---

## Tapir failed to load at least one row to DynamoDB in the last 24 hours

When `tapir` loads datasets in the `tapir-load` DAG node, it [scales up the dynamo capacity dynamically](https://github.com/nubank/tapir/blob/e0fb144c25cd2320e0535c7d08c63133c08d5fc9/src/tapir/core.clj#L205). For whatever reason, this doesn't always work leading to crazy throttling and data load issues.

You can check that this is the case by looking at the write capacity for the `conrado` DynamoDB table on [the metrics tab on AWS](https://sa-east-1.console.aws.amazon.com/dynamodb/home?region=sa-east-1#tables:selected=prod-conrado-docstore). If the capacity scale up failed, you will see that it is consuming way more than has been provisioned.

The solution when the dynamo scale up didn't work is to kill `tapir-load` manually and restart it on airflow.

---

## "alert-itaipu-contracts triggered on Airflow"

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

> If there is no content in that page or if you get a connection error, that means the task host machine is down and we can't get to the logs that way. In this case, we need to resort to Splunk. Use this search: https://nubank.splunkcloud.com/en-US/app/search/etl_job_logs?form.the_time.earliest=-60m%40m&form.the_time.latest=now&form.search=*&form.job=aurora%2Fprod%2Fjobs%2Fitaipu-contracts

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

---

## Deadletter prod-etl-committed-dataset

This happen when there is a problem on producing a dataset on capivara.

### Check what type of dataset broke

- Open the aws SQS service in the browser and change the region to `us-east-1` (North Virginia).
- There will be at least two queues there: the one consumed by capivara `prod-etl-committed-dataset` and the deadletter queue (messages that failed in the capivara processing are produced to this queue) `prod-etl-committed-dataset-failed`.
- Check the `prod-etl-committed-dataset-failed` queue on `Queue Actions` > `View/Delete Messages` > `Start pooling the messages`
- Each line will be one deadletter. In the body of the message there will be the name of the dataset, if it's an archived (the name starts with `archive/` go to the [next step](#replay-archived-dataset-deadletter). If it's another type of dataset just delete it.

### Replay archived dataset deadletter

- Click in `More Details` in the right side of the deadletter.
- Copy the message body.
- Delete the deadletter.
- Open a new tab and go to the SQS page (don't forget to check if you are in `us-east-1` region).
- For the `prod-etl-committed-dataset` go `Queue Actions` > `Send a Message` > paste the body of the deadletter there > `Send Message`
