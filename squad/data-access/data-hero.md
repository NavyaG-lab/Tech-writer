# Data Access' Data Hero (aka weekly on call engineer)

## What is a Data Hero?

Data Hero is Data Access' on call engineer. In a weekly based fashion, the resposabilities of the Data Hero is to ensure all Data Access' services are running smothly and if users are able to interact with our data tools without any problems.

The Data Hero on call schedule just works on work hours during weekdays as Data Access don't own any time sensitive services or processes.

It also expected from the Data Hero that our data tools are well monitored, playbooks are written for common incedents and documentation is up to date when used to resolve a incedent.

The Data Hero should be able to help users if they tag @data-acess on slack, or if someone reports a problem on [#data-help](https://nubank.slack.com/messages/C06F04CH1/) or [#squad-data-access](https://nubank.slack.com/messages/C84FAS7L6/) or someone from Data Access tags you.

Along with the Weekly Data Hero, we also have a Data Hero Backup rotation to help in case of an emergency.

During idle time, on-call engineers can work on normal backlogs tasks.

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

Things to keep an eye on:
* Detach notebooks older than 1 day
* Restart clusters that are not working as expected
* Attach, detach, add and remove libraries. There are some instructions [here](https://github.com/nubank/data-platform-docs/tree/master/databricks)
* Automated jobs:
    - [Autobump itaipu and restart clusters](https://nubank.cloud.databricks.com/#job/8737)
        - Runs daily at 5:30am (UTC-2)
    - [Databricks BR loader](https://nubank.cloud.databricks.com/#notebook/1321846)
        - Runs daily every 3 hours
    - [Databricks MX loader](https://nubank.cloud.databricks.com/#notebook/1223300/)
        - Manually triggered

### Documenting

Keep documentation up to date to help solve incidents:
* https://github.com/nubank/data-platform-docs
* https://github.com/nubank/playbooks/tree/master/squads/data-access
* https://wiki.nubank.com.br/
* https://github.com/nubank/monsoon/blob/master/README.md
* https://github.com/nubank/mordor/blob/master/README.md
* https://github.com/nubank/imordor/blob/master/README.md
* https://github.com/nubank/bilbo/blob/master/README.md


### Post-mortem

If there were incidents relevants during the weekend, the Data Hero can share what they learned in our Slack Channel.
If necessary, update [morgue](https://github.com/nubank/morgue) with the learnings from the incident.

### Handover

When finishing the on-call week, post the updates on our channel, so the next person in the rotation can get context before starting their week.

## Opsgenie

Opsgenie is the way to be notified in case of an incident is going on. Currently only `critical` alerts to Opsgenie ([Default](https://github.com/nubank/playbooks/blob/master/observability/alerts/routing-alerts-to-squads.md#default-routing-per-environment) behaviour for [Data Access](https://github.com/nubank/definition/blob/master/resources/br/squads/data-access.edn))

Any emails sent to `data-access-incident@nubank.opsgenie.net` will fire an alarm to the on-call engineer.

Opsgenie setup configuration can be found [here](https://github.com/nubank/definition/blob/master/resources/br/squads/data-access.edn).

## Schedule

Data Access schedules can be found [here](https://nubank.app.opsgenie.com/teams/dashboard/7dd354df-4fdf-4b26-8ae1-f4726948afe4/main).

Other way to find who is on call is to use Slack Opsgenie Integration, just run the command anywhere on Slack:

`/genie whoisoncall Data Access Level 1`
`/genie whoisoncall Data Access Level 2`

## Overrides

Whenever there is someone on a leave, vacations, or if the person asked someone to take their place on the schedule, create an override on the respective On-call schedule:

![Override Ops Genie Data Hero](/images/override-ops-genie-data-hero.png)

## Escalating

Do not be afraid of asking for help if you need to, the Data Hero Backups are available:
* if you want to start to work on an issue but do not know where to start;
* if you try to solve an issue for more than one hour and feel you are not making progress;
* if you do not know how to prioritize a new incoming issue;
* if you have already working on a issue and more apperead.

This also applies to anyone else in Data Access, if either the Data Hero and the Data Hero Backup are stuck.
