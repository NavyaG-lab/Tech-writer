---
owner: "#data-access"
---

# Looker Playbook

## Dashboard SLO Alert

Whether it’s the hourly or the daily alert that went on, you need to take a look at this look [here](https://nubank.looker.com/looks/4946)

Use the filters in the look at historical activity to understand how long since it’s been happening.

Check this [Looker Database Activity dashboard](https://nubank.looker.com/admin/database_performance_dashboard) to broadly understand if the issue is on dashboard queries, schedules or PDTs.

Check if the slots on Big Query are being enough on this [grafana dashboard](https://prod-grafana.nubank.com.br/d/QzigKRfZk/bigquery-stackdriver?orgId=1&refresh=1m). Check the “Queries in Flight” graph to see if there are too many concurrent queries. And the “Query Slots Usage Across Reservation” chart to check if the nu-br-loker is already at the max capacity.

If we are running out of slots consistently then consider buying more slots on BQ for a short period of time. Refer to this [guide](https://cloud.google.com/bigquery/docs/slots) on how to do that. Ask @leonardo.matsuura for help.

If the Database is not the bottleneck, check if this is due to [Looker Instance](https://nubank.looker.com/admin/instance_performance_dashboard).
Looker deployment is managed by Looker folks, so in this case reach out to them either by Slack or opening a ticket from the top right help icon on the Looker homepage.

Also for the hourly alert, there’s a good possibility that this is temporary due to too many queries being run at that point and the error should go away by itself.


## Critical System Errors Alert

System Alerts happen all the time but if this alert is fired there may be some deeper problems. Check if users are also reporting Looker issues on #data-help.

To find out what the critical system errors are - go to the [Looker System Activity](https://nubank.looker.com/projects/looker_system_activity/files/views/viewer_users.view.lkml) and check the filters we consider as Critical System Errors by looking at the dimension named `is_system_activity_critical_error`.

Use this [look](https://nubank.looker.com/explore/looker_system_activity/history_nubank) to explore the other errors that have been happening.

Do reach out to Looker Support if this problem is affecting our users.
