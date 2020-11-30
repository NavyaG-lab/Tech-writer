---
owner: "#data-infra"
---

# Data-infra's Hausmeister (a.k.a. on-call rotation)

"Hausmeister" is an on-call rotation, responsible for maintaining stable ETL systems across the squad and ensure that the ETL job runs are smoothly running.

## Topics this guide will cover

- **Hausmeister Prerequisites**

  - [Knowledge requirements](hausmeister.md)
  - [Setup](hausmeister.md)
  - [Understanding the Severity levels](https://github.com/nubank/playbooks/blob/master/incident-response/incident-severity-levels.md)
  - [Working and Non-Working hours](on_call_runbook.md)
  - [Slack channels to look during on-call](on_call_runbook.md)

- **On-call runbooks**

  - [Operations Cookbook](ops_how_to.md)

  - [Monitoring nightly run](monitoring_nightly_run.md)

- **Troubeshooting**

  - [Alerts](on_call_runbook.md)
  - [Frequently occurring issues](on_call_runbook.md)
  - [Issues related to Services](on_call_runbook.md)

- **Checklist**
  - [Incident response checklist](incident_response_checklist.md)

<!-- - Accounts and access permissions related issues
Debugging tips-->

## Responsibilities

The responsibilities include:

- Monitoring run during the day even when there are no alerts, and make sure that nodes in Airflow finish successfully in time (usually takes time between 40 minutes to 8 hours). You can proactively solve performance issues if you have bandwidth.
- Quickly address the Opsgenie pagers related to the run.

  Addressing any failures such as:
  - committing datasets empty
  - removing faulty archives
  - re-running nodes with bigger timeouts/more cores,
  - reverting PRs, and
  - managing communication with users about their dataset - when PR's are reverted or when the datasets have poor performance.

- Addressing user issues, such as missing data in dataset series or archives.
- Fix low-priority alarms, such as:
  - Cutia dead letter alarms
  - Correnteza alarms
  - Metapod-Datomic transactor health alarms
