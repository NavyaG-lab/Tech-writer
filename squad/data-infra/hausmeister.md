# Data-infra's Hausmeister (a.k.a. on-call rotation)

"Hausmeister" is an on-call rotation split into several shift types:

 * Level 1 Weekday: Monday 6pm - Friday 6pm
   1. _non-work hours_ the hausmeister is on-call to ensure our services and DAG runs operate smoothly.
   2. _work hours_ the hausmeister is responsible for triaging issues and customer inquiries during work hours.
 * Level 1 Weekend (_Friday 6pm - Monday 6pm_)
   Same as weekday, but not responsible for customer inquiries
 * Level 2 (_Monday - Monday_):
   A supporting engineer with more ops experience to support the Level 1. This is the first person the hausmeister can elevate an issue to if he/she needs assistance.
   

At the end of each shift, any pending open issues are handed off to the next Level 1 Hausmeister.

## Outside of work hours: pager duty

Outside of work hours, your sole responsibility as a Hausmeister is to respond to hard alerts, for which you will be notified via OpsGenie. This means that:

- you should have a phone with [OpsGenie](http://opsgenie.com/) configured with you at all times.
- your work-configured laptop should be readily available to address any alerts you receive from OpsGenie.

If an issue comes up that you cannot handle independently, you should escalate the alert to the Level 2 and pair with them to resolve the issue.

### Setup
Make sure your work environment is set up and you:
  * have your [VPN functioning properly](https://nubank.slack.com/archives/C024U9800/p1545380162000900).
  * know your way around [Airflow](https://github.com/nubank/data-platform-docs/blob/master/airflow.md).
  * know [how to use sabesp](https://github.com/nubank/data-platform-docs/blob/master/cli_examples.md).
  * have a [GraphQL client accessible](https://github.com/nubank/data-platform-docs/blob/master/ops/graphql_clients.md).

### Handling Alerts/Issues
Check [the runbook](https://github.com/nubank/data-platform-docs/blob/master/on-call_runbook.md) for how to handle the raised alert.

Common maintenance operations are listed in the [Ops HOWTO document](https://github.com/nubank/data-platform-docs/blob/master/ops_how_to.md). Consider contributing back to it if you come across a repeated task that is worth sharing.

Before handling an issue, be sure to go through the [Data Incident Response Checklist](https://github.com/nubank/data-platform-docs/blob/master/etl_operators/incident_response_checklist.md).

### Escalating
Do not be afraid of asking the Level 2 for help if you need to. Here are some non-comprehensive guidelines on when to escalate:
* if you want to start to work on an issue but do not know where to start;
* if you try to solve an issue for more than one hour and feel you are not making progress;
* if you do not know how to prioritize a new incoming issue.

## During work hours: run monitoring
Monitor the normal operation of our services via

* the [#squad-di-alarms](https://nubank.slack.com/messages/C51LWJ0SK/) slack channel
* general DAG status via [airflow](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao): you should check on the status of the DAG every few hours during working hours to make sure things are progressing smoothly.
* at-a-glance DAG status via [#etl-updates](https://nubank.slack.com/messages/CCYJHJHR9/): It is also a good idea to pay attention to the ETL status updates posted to the slack channel [#etl-updates](https://nubank.slack.com/messages/CCYJHJHR9/). It can be a quick way to notice irregularities in the run.

### During work hours: support our Clients
Over the course of the week our customers (Nubank's data scientists, business analysts, data analysts, etc), often encounter platform issues while using our services. To support their effectiveness, the Hausmeister is responsible for communicating with these users; looking into their issues in a timely manner.

The main slack channel you should monitor for user questions is Slack channels you should monitor for questions are:

* [#squad-data-infra](https://nubank.slack.com/messages/C0XRWDYQ2/)
* [#data-tribe](https://nubank.slack.com/archives/C1SNEPL5P)
* [#data-announcements](https://nubank.slack.com/messages/C20GTK220/)
* [#data-help](https://nubank.slack.com/messages/C06F04CH1/)
* [#di-hausmeister](https://nubank.slack.com/archives/CP3F163C4)

**NB**: as a Hausmeister your role is to ensure their problems are addressed, but this does not mean that you are responsible for fixing every single problem you see; the reason being that you should always make sure you have the headspace necessary to tackle a hard alarm when it comes up.

### During work hours: address the Hausmeister Backlog

During your Level 1 on-call rotation you usually encounter bugs and corner cases in our system. The following should make it to the Hausmeister backlog, which we track on [clubhouse](https://app.clubhouse.io/nubank/project/352/data-infra-hausmeister):

 * Items about improving the visibility, monitoring, maintenance, and operation of our infrastructure. In short, items which improve the workflow for the primary Hausmeister.
 * Low-hanging non-blocking bugs observed as part of the hausmeister's attempts to keep the DAG running. More laborious fixes should be part of pack backlogs.

 Items with non-immediate payoff, such as “good-to-have” features, should be moved to pack backlogs.

Backlog tickets should be annotated with a "why", as in, the benefit of completing the particular work-item.

Tickets for which the question ‘ *will it come back to bite the Hausmeister in the future?* ’ can't be answered with "yes" shouldn't belong on the hausmeister backlog.

From a resourcing perspective, the on-call enginer is resourced exclusively as hausmeister during their rotation. If there aren't any open issues you are working on, feel free to tackle issues in the hausmeister backlog or general tech-debt.

