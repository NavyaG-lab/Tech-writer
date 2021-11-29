---
owner: "#data-access"
---

# Data Access' On-call Engineer

## What is this role about

In a weekly based fashion, the responsibilities of the On-call Engineer is to ensure that all Data Access' services are running smoothly and that users are able to interact with our data tools without any problems.

The on-call schedule only covers working hours during weekdays since Data Access does not own any time-sensitive services or processes.

It is expected from On-call Engineers that they:

* monitor our data tools
* write playbooks for common incidents
* update documentations about incidents resolutions
* solve root causes of problems that cause incidents or address them

Along with the Weekly On-call Engineer (Data Access Level 1 rotation), we also have a Data Access Level 2 rotation to help in case of emergency or overburden.

During idle time, On-call Engineers can work on normal backlogs tasks.

## Configuration

If new members need to be added to the rotation, first they need to be added to OpsGenie. Any admin can add users [here](https://nubank.app.opsgenie.com/settings/users/).
The admin should also [add the new member to the Data Access Team](https://nubank.app.opsgenie.com/teams/dashboard/7dd354df-4fdf-4b26-8ae1-f4726948afe4/members). Then, [add the user to the Level 1 and Level 2 rotations](https://nubank.app.opsgenie.com/teams/dashboard/7dd354df-4fdf-4b26-8ae1-f4726948afe4/main).

Users need to download OpsGenie App on their mobile phone or configure SMS/Voice Notifications [here](https://nubank.app.opsgenie.com/settings/user/notification).

Currently, Data Access doesn't have off hours on-call policies, so if you don't want to be disturbed, you need to [configure quiet hours](https://nubank.app.opsgenie.com/settings/user/notification).

## Playbooks

If you are in the middle of an incident go here for [common failure scenarios and solutions](https://github.com/nubank/playbooks/tree/master/squads/data-access).

## Responsibilities

### Monitoring

* [Looker](https://nubank.looker.com/admin/performance_audit_dashboard)
* [Grafana](https://prod-grafana.nubank.com.br/dashboards/f/R127sB0Zz/data-access)
* [bilbo](https://nubank.splunkcloud.com/en-US/app/search/bilbo_monitoring)
* [#data-access-alarms](https://nubank.slack.com/archives/C8TENL0C8)

#### BigQuery

* [Data access project](https://console.cloud.google.com/bigquery?project=nubank-data-access)
* [Loader monitoring](https://github.com/nubank/monsoon#monitoring)
* [Usage dashboard](https://nubank.looker.com/dashboards/gcp_bigquery_logs::bigquery_audit)

#### Databricks

* [Clusters management](https://nubank.cloud.databricks.com/#setting/clusters)

#### Things to keep an eye on

* Detach notebooks older than 1 day
* Restart clusters that are not working as expected
* Attach, detach, add and remove libraries. There are some instructions [here](../../tools/databricks/README.md)
* Automated jobs:

- [Autobump itaipu and restart clusters](https://nubank.cloud.databricks.com/#job/8737)

        - Runs daily at 5:30am (UTC-2)

* [Databricks BR loader](https://nubank.cloud.databricks.com/#notebook/1321846)

  * Runs daily every 3 hours

- [Databricks MX loader](https://nubank.cloud.databricks.com/#notebook/1223300/)

- Manually triggered

### Documenting

Keep documentation up to date to help solve incidents:

* [Data Platform Docs] (<https://github.com/nubank/data-platform-docs>>
* [Common failures documentation](https://github.com/nubank/playbooks/tree/master/squads/data-access)
* [Nubank wiki](https://wiki.nubank.com.br/)
* [Data Access Playbooks](https://playbooks.nubank.com.br/squads/data-access/)
* [Monsoon documentation](https://github.com/nubank/monsoon/blob/master/README.md)
* [Mordor documentation](https://github.com/nubank/mordor/blob/master/README.md)
* [Mordor Python lib documentation](https://github.com/nubank/imordor/blob/master/README.md)
* [Bilbo documentation](https://github.com/nubank/bilbo/blob/master/README.md)

### Post-mortem

If there were relevant incidents during the weekend, On-call Engineers are recommended to share what they learned in our Slack Channel.
When applicable, document the post-mortem on the [Post-mortems Google Drive](https://drive.google.com/drive/folders/1c3r0P-gsRgivgXRZokVNMUVhBg35RT2z) with the learnings from the incident. More on our blameless post-mortem culture can be found [here](https://playbooks.nubank.com.br/incident-response/how-to-write-a-postmortem-document/).

### Handover

When finishing the on-call week, post the updates on [#squad-data-access](https://nubank.slack.com/archives/C84FAS7L6), so the next person in the rotation can get context before starting their week. Check [this example](https://nubank.slack.com/archives/C84FAS7L6/p1583772429182800).

## Opsgenie

Opsgenie is the way to be notified in case of an incident is going on. Currently only `critical` alerts are configured to go to Opsgenie ([Default](https://github.com/nubank/playbooks/blob/master/observability/alerts/routing-alerts-to-squads.md#default-routing-per-environment) behaviour for Data Access).

Any email sent to `data-access-incident@nubank.opsgenie.net` will fire an alarm to the on-call engineer.

Opsgenie setup configuration can be found [here](https://github.com/nubank/definition/blob/master/resources/br/squads/data-access.edn).

## Schedule

Data Access schedules can be found [here](https://nubank.app.opsgenie.com/teams/dashboard/7dd354df-4fdf-4b26-8ae1-f4726948afe4/main).

Other way to find who is on call is to use Slack Opsgenie Integration, just run the command anywhere on Slack:

`/genie whoisoncall Data Access Level 1`

`/genie whoisoncall Data Access Level 2`

## Overrides

Whenever there is someone on a leave, vacations, or if the person asked someone to take their place on the schedule, create an override on the respective On-call schedule:

![Override OpsGenie Data Hero](/images/override-opsgenie-data-hero.png)

## Escalating

Do not be afraid of asking for help if you need to. The On-call Engineer Level 2 will be available:

* if you want to start working on an issue but don't know where to start;
* if you try to solve an issue for more than one hour and feel you are not making progress;
* if you don't know how to prioritize a new incoming issue;
* if you are already working on a issue and more issues came up.

This also applies to everyone else in Data Access, if either the Level 1 or Level 2 On-call Engineers are stuck.
