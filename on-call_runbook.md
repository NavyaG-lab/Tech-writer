# On-Call Runbook

This document is a resource for engineers *on-call*.  The general layout of
this document is Alert: Reasoning: Action(s).  All the alert entries here
should be linked with the alerts being dispatched from our alerting platform.
The ["ALERT"] string should be verbatim the same string that is dispatched.

<hr>

## ["alert-itaipu-contracts triggered on Airflow"]

This means the first task in our daily DAG failed. This task is a dependency
to all the rest of the DAG, so it's important that it runs smoothly and 
on time in order for us to meet our SLA.

_You need VPN access to follow the steps below._

**First:** check what was the reason for the failure, by following these steps:

1. Access https://cantareira-stable-mesos-master.nubank.com.br:8080/scheduler/jobs/prod/itaipu-contracts?jobView=history
1. You'll see the past instances of that task. To see the logs, click on the link that is an IP address that starts like `10.` ![image](https://user-images.githubusercontent.com/1674699/37596958-2dd3da18-2b7e-11e8-8b12-9ea541753656.png)
1. Click the `stderr` link in the right end of the screen that will appear. `stdout` might also have useful info.
1. Check the logs for any errors you can read, in some cases there could be an error message or an exception type that makes it clear what is the specific cause for the failure.
1. Check the `#crash` channel in Slack for possible ongoing outages that might cause the DAG run to fail.
1. If you are not sure what is the cause for the failure, or you are not sure what to do about it, jump to the next step which is to restart the task.

> If there is no content in that page or if you get a connection error, that means the task host machine is down and we can't get to the logs that way. In this case, we need to resort to Splunk. Search for `source="http:cantareira-docker-logs"` in our Splunk tenant https://nubank.splunkcloud.com/en-US/ _TODO: add link on DAG log output to splunk_

**Second:** restart the task

1. Access https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao
1. You'll see the state of the entire DAG in this page. The status of each node in the graph is represented by its stroke color. There is a reference on the upper right corner. In this specific scenario, the first node named `itaipu-contracts` should have a red stroke color.
1. Click on the `itaipu-contracts` node, and you will see a pop-up appear with some buttons. Click the "Clear" button (dark green), while making sure the "Downstream" and "Recursive" options are pressed (which means enabled) beside it.
_What you just did is "clearing" the state of the node. This will effectively make Airflow try to figure out the next steps to try to get the state to a "succeeded" state, which is first transitioning into a "running" state by executing the task_
1. After a few seconds, the node stroke color should be back to light green. If not, refresh the graph view after a few seconds via the refresh button in the upper-right corner.

After executing these steps, there is a possibility that the task fails once more. In this case, escalate to the next layer of on-call and coordinate with another engineer to figure out next steps.

<hr>

## [Alert]
* put the reasoning behind the alert here to provide context

What should be done to most directly resolve the alert.  What things
we need to look for.  What procedures to follow.  What commands to
enter.  If there is an associated script that can automate these steps
it should be linked here.

<hr>
