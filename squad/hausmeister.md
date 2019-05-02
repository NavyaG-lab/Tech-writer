# Data-infra's Hausmeister (a.k.a. on-call rotation)

"Hausmeister" is an on-call rotation split into several shift types:

 * Level 1 Weekday: Monday 6pm - Friday 6pm
   1. _non-work hours_ the hausmeister is on-call to ensure our services and DAG runs operate smoothly.
   2. _work hours_ the hausmeister is responsible for triaging issues and customer inquiries during work hours.
 * Level 1 Weekend (_Friday 6pm - Monday 6pm_)
   Same as weekday, but not responsible for customer inqueries
 * Level 2 (_Monday - Monday_):
   A supporting engineer with more ops experience to support the Level 1. This is the first person the hausmeister can elevate an issue to if he/she needs assistance.
 * Backlog Weekday: Monday 6pm - Friday 6pm
   The week after completing your Level 1 Weekday rotation you should dedicate to tackling issues on the [hausmeister backlog](https://app.clubhouse.io/nubank/project/352/data-infra-hausmeister) or other issues that cause
   Once going off The hausmeister from the previous is resourced as a backlog hausmeister

## Level 1 Responsibilities

### pager duty
Outside of work hours you should have a phone with [OpsGenie](http://opsgenie.com/) configured with you at all times. Your work-configured laptop should be readily available to address any alerts you receive from OpsGenie.

If an issue comes up that you cannot handle independently, you should escalate the alert to the Level 2 and pair with them to resolve the issue.

### visibility

When an issue arises, it is expected that you mention the failure, communicate updates and actions taken in [#data-crash](https://nubank.slack.com/messages/CE98NE603/). This allows people to follow along and contribute suggestions.

For serious incidents, also perform these steps:
  - find someone to actively communicate updates about the incident, referred to as the "comms" person. if you're alone, you can take that role.
  - you are the "point" person, which means you're the first responder and primary person acting on the issue
  - change the [#data-crash](https://nubank.slack.com/messages/CE98NE603/) channel topic to ":red_circle: -short description of the failure- | point: -your-name- comms: -comms-person-" e.g. "itaipu-dimensional-modeling not finishing"
  - move any discussions about the issue to this channel (no need for threads)

If the incident affects the time which data will be available for users at Nubank, or availability of some user-facing service (e.g. Metabase, Belo Monte, Databricks), post a short message about what is being affected in [#data-announcements](https://nubank.slack.com/messages/C20GTK220/). This way, users know we are aware of the issue. Note that this channel serves a wider audience than engineers, so describe the issue in plain terms and at a high level.

After the incident has been taken care of and resolved, change the topic back to ":green_circle:" (and post an update for users in #data-announcements, if applicable).

### support our clients
Over the course of the week our customers (Nubank's data scientists, business analysts, data analysts, etc), often encounter platform issues while using our services.
To support their effectiveness, the hausmeister is responsible for communicating with these users; looking into their issues in a timely manner.

Slack channels you should monitor for questions:

* [#squad-data-infra](https://nubank.slack.com/messages/C0XRWDYQ2/)
* [#guild-data-eng](https://nubank.slack.com/messages/C1SNEPL5P/)
* [#data-announcements](https://nubank.slack.com/messages/C20GTK220/)
* [#data-help](https://nubank.slack.com/messages/C06F04CH1/)

### address the hausmeister backlog
We use [clubhouse](https://app.clubhouse.io/nubank/project/352/data-infra-hausmeister) to track hausmeister issues.

From a resourcing perspective, the on-call enginner is resourced exclusively as hausmeister during their rotation. If there aren't any open issues you are working on, feel free to tackle issues in the hausmeister backlog or general tech-debt.

### monitoring
Monitor the normal operation of our services via

* the [#squad-di-alarms](https://nubank.slack.com/messages/C51LWJ0SK/) slack channel
* general DAG status via [airflow](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao): you should check on the status of the DAG every few hours during working hours to make sure things are progressing smoothly.
* at-a-glance DAG status via [#etl-updates](https://nubank.slack.com/messages/CCYJHJHR9/): It is also a good idea to pay attention to the etl status updates posted to the slack channel [#etl-updates](https://nubank.slack.com/messages/CCYJHJHR9/). It can be a quick way to notice irregularities in the run.

### escalating
Do not be afraid of asking the Level 2 for help if you need to. Here are some non-comprehensive guidelines on when to escalate:
* if you want to start to work on an issue but do not know where to start;
* if you try to solve an issue for more than one hour and feel you are not making progress;
* if you do not know how to prioritize a new incoming issue.

### hand-off

* On Friday at 6pm, the hausmeister shift ends and any pending issues are handed off to the weekend on-call engineer.
* On Monday at 6pm, the weekend on-call engineer hands off any open P4-P3 issues to the new hausmeister.

### gain familiarity with new areas
As engineers we tend to specialize. The hausmeister rotation gives us visibility and experience into new parts of the code-base and tech stack.

## Backlog Rotation

### Responsibilities
* Offer help to the Level 1 when they need it
* Work on the hausmeister backlog

### The backlog

During your Level 1 on-call rotation you usually encounter nice bugs and corner cases in our system. The following should make it to the hausmeister backlog:
 * Items about improving the visibility, monitoring, maintenance, and operation of our infrastructure. In short, items which improve the workflow for the primary Hausmeister.
 * Low-hanging non-blocking bugs observed as part of the hausmeister's attempts to keep the DAG running. More labourious fixes should be part of pack backlogs.

Items with non-immediate payoff, such as “good-to-have” features, should be moved to pack backlogs.

Backlog tickets should be annotated with a "why", as in, the benefit of completing the particular work-item.

Tickets for which the question ‘ *will it come back to bite the Hausmeister in the future?* ’ can't be answered with "yes" shouldn't belong on the hausmeister backlog.
