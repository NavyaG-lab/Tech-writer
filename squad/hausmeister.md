# Data-infra's Hausmeister (aka weekday ops rotation)

"Hausmeister" is the weekly Monday-Friday on-call rotation.

1. _non-work hours_ the hausmeister is on-call to ensure our services and DAG runs operate smoothly.
2. _work hours_ the hausmeister is responsible for triaging issues and customer inquiries during work hours.

_Level 2_: There should always be a secondary engineer with more ops experience supporting the hausmeister. This is the first person the hausmeister can elevate an issue to if he/she needs assistance.

_Weekend on-call_: similar to the hausmeister role, but only responsible for being on pager duty (see below).

## responsibilities

### pager duty
Outside of work hours you should have a phone with [OpsGenie](http://opsgenie.com/) configured with you at all times. Your work-configured laptop should be readily available to address any alerts you receive from OpsGenie.

If an issue comes up that you cannot handle independently, you should escalate the alert to the Level 2 and pair with them to resolve the issue.

_For visibility_: when an issue arises, it is expected that you:
 - mention the failure in [#guild-data-eng](https://nubank.slack.com/messages/C1SNEPL5P/). This allows people to follow along, contribute suggestions, and better connect their code changes to failures you have to wake up in the night for.
 - add an entry to the [data-infra log book](https://docs.google.com/spreadsheets/d/1-1AEX2aPvZvEQgGjXyxIoYl4eD2oav6_6V-eAH2oZ74/edit#gid=0) so we can track the most common failures.
 
### report squad's weekly progress
On Friday we shoud should update our clients about the work done in the week. We should send a message on [#data-announcements](https://nubank.slack.com/messages/C20GTK220/) and replicate the message on [#guild-data-eng](https://nubank.slack.com/messages/C1SNEPL5P/) and [#squad-data-infra](https://nubank.slack.com/messages/C0XRWDYQ2/).

This message should contain the main tasks done on new features, bug fixes and even squad tasks like hiring jobs.

### support our clients
Over the course of the week our customers, Nubank's data scientists, often encounter platform issues while using our services.
To support their effectiveness, the hausmeister is responsible for communicating with these users; looking into their issues in a timely manner.

Slack channels you should monitor for questions:

* [#squad-data-infra](https://nubank.slack.com/messages/C0XRWDYQ2/)
* [#guild-data-eng](https://nubank.slack.com/messages/C1SNEPL5P/)
* [#data-help](https://nubank.slack.com/messages/C06F04CH1/)

### review open PRs
The Hausmeister should check all Data Infra projects for new PRs and review them, asking other people to help (via the GitHub Review Request feature) if they feel it is needed.
There is one inventory of Data Infra projects available [here](https://github.com/nubank/data-infra-docs/blob/master/infrastructure/inventory.md), and we are trying to centralize all reviews using [this GitHub query](https://github.com/pulls?q=is%3Apr+team-review-requested%3Anubank%2Fdata-infra+archived%3Afalse+user%3Anubank+is%3Aopen), although it currently contains only Itaipu PRs.

### address open P4-P3 issues
Hausmeister should work on any open P4-P3 issues. Others should be pulled in to help with any P4 issues.

If there are no open P4-P3 issues, the hausmeister can work on tech-debt or normal work. From a resourcing perspective, they are resourced as hausmeister and nothing else during this week.

### monitoring
Monitor the normal operation of our services via

* the [#squad-di-alarms](https://nubank.slack.com/messages/C51LWJ0SK/) slack channel
* the [data-infra riemann dashboard](http://prod-s0-watchtower.nubank.com.br/#data-infra) (check it for each shard by changing the url)

### escalating
Do not be afraid of asking the Level 2 for help if you need to. Here are some non-comprehensive guidelines on when to escalate:
* if you want to start to work on an issue but do not know where to start;
* if you try to solve an issue for more than one hour and feel you are not making progress;
* if you do not know how to prioritize a new incoming issue.

### hand-off

* On Friday at 5pm, the hausmeister shift ends and any pending issues are handed off to the weekend on-call engineer.
* On Monday at 11am, the weekend on-call engineer hands off any open P4-P3 issues to the new hausmeister.

### gain familiarity with new areas
As engineers we tend to specialize. The hausmeister rotation gives us visibility and experience into new parts of the code-base and tech stack.

## triaging

An issue has come to your attention via a slack channel, an alarm, or monitoring dashboards

### user questions
If the issue is with how a client is using the service, point them in the right direction. It isn't necessarily your responsibility to help them do their work, but consider writing docs if you see the same question coming up.

### service issues
If the issue is with our services, create an [itaipu issue](https://github.com/nubank/itaipu/issues/) tagged with `bug` and `data-infra` and a priority.
[Here is a list](https://github.com/nubank/itaipu/issues?q=is%3Aopen+is%3Aissue+label%3Abug+label%3Adata-infra) of current such issues.

The priority breakdown tells us how the issue should resourced:

* _P4 Very high priority_: Stop everything and pull in other people to get this resolved. Includes: building invalid datasets and bugs that prevent us from meeting external SLAs.
* _P3 High priority_: Hausmeister should actively work on this or hand-off to someone with more context who should actively work to resolve it.
* _P2/P1 Medium/low priority_: Backlog issue that can be addressed when time permits if even worth the time investment.

One should also be aware of the [severity levels](https://github.com/nubank/morgue#severity-levels) described on the `Nubank`-wide incident procedure docs. If an issue falls into one of those severity levels (rare for data-infra), those procedures should be followed.

## Reporting The [DAG](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao) run status

Note: The dag status can be gotten programmatically now.

Using the [sabesp](https://github.com/nubank/sabesp) utility<br>
Example:
<pre>
%> sabesp metapod --env prod --token transaction status a725694a-3cc3-5a39-9a69-eefa7193669e
</pre>
Each day the data-announcements job [defined in Aurora](https://github.com/nubank/aurora-jobs/blob/master/jobs/data-announcements.aurora#L21) is run as a part of [another DAG](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=data-announcements) defined [here](https://github.com/nubank/aurora-jobs/blob/master/airflow/data-announcements.py#L1) that posts the ETL DAG status in [#data-announcements](https://nubank.slack.com/messages/C20GTK220/)

Everyday the hausmeister should check the run status of the [DAG](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao) for other teams to view.
This is posted to the slack channel [#data-announcements](https://nubank.slack.com/messages/C20GTK220/)
