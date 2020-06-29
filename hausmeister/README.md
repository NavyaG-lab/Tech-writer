# Data-infra's Hausmeister (a.k.a. on-call rotation)

"Hausmeister" is an on-call rotation, responsible for maintaining stable ETL systems across the squad and ensure that the ETL job runs are smoothly running.

<details>
  <summary>Get started</summary>
  
## Hausmeister Prerequisites

- [Knowledge requirements](../hausmeister/hausmeister.md)
- [Setup](../hausmeister/hausmeister.md)
- [Understanding the Severity levels](https://github.com/nubank/playbooks/blob/master/incident-response/incident-severity-levels.md)
- [Working and Non-Working hours](../hausmeister/on_call_runbook.md)
- [Slack channels to look during on-call](../hausmeister/on_call_runbook.md)

</details>

<details>
  <summary>On-call runbooks</summary>
  
- [Operations Cookbook](../ops_how_to.md)

- [Monitoring nightly run](../monitoring_nightly_run.md)

### Troubeshooting

- [Alerts](../hausmeister/on_call_runbook.md)
- [Frequently occurred issues](../hausmeister/on_call_runbook.md)
- [Issues related to Services](../hausmeister/on_call_runbook.md)
- Accounts and access permissions related issues
- Debugging tips

</details>

<details>
    <summary>Checklists</summary>

### Checklist

- [Incident response checklist](https://github.com/nubank/data-platform-docs/blob/master/etl_operators/incident_response_checklist.md)

</details>

## Responsibilities

The responsibilities include:

- Monitoring run during the day even when there are no alerts, and make sure that nodes in Airflow finish successfully in time (~10 mins). You can proactively solve performance issues if you have bandwidth.
- Quickly address the Opsgenie pagers related to the run.
  
  Addressing any failures such as:
  - committing datasets empty
  - removing faulty archives
  - re-running nodes with bigger timeouts/more cores,
  - reverting PRs, and
  - managing communication with users about their dataset - when PR's are reverted or when the datasets have poor performance.

- Addressing user issues, such as missing data in dataset series or archives.
- Fix low-priority alarms, such as:
  - Riverbend lag alarms
  - Cutia dead letter alarms
  - Correnteza alarms
  - Metapod-Datomic transactor health alarms
