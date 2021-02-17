---
owner: "#squad-data-access"
---
# Looker Common Tasks

## People need access to Looker

The Looker lambda takes care of most cases, but if someone has their Aloka information outdated they might be missing some kinda of access.

Here are the most common cases:

## User request to create a New Folder:

Solution: Create a new folder on Shared Folders, allow Nubankers group View access and give the user who requested it Manage access.

1. Through the [Looker UI](https://nubank.looker.com/folders/home)

## User doesn't have access to SQL Runner

Solution: add the person to the `Basic User` group

1. Through the [Looker UI](https://nubank.looker.com/admin/groups?groupId=51)
2. Through nucli `nu looker add first_name.last_name --basic`

## User doesn't have access to schedule Dashboards or Looks

Solution: check if there's a Business Analyst or Data Analyst on the squad and if not add the person to the `Power User` group:

1. Through the [Looker UI](https://nubank.looker.com/admin/groups?groupId=5)
2. Through nucli `nu looker add first_name.last_name --power`

Tell the power user to be mindful on:

1. What you are trying to schedule: try to use datasets instead of contracts and not very complex queries
1. The time of the schedule: try to schedule the delivery early in the morning or late in the day, as some heavy schedules can impact the instance 

## User doesn't have access to a specific explore or Dashboard

Debugging process:
![https://mermaidjs.github.io/mermaid-live-editor/#/edit/eyJjb2RlIjoic3RhdGVEaWFncmFtXG5zdGF0ZSBcIlN1ZG8gYXMgdGhlIFVzZXJcIiBhcyBzMVxuc3RhdGUgXCJTdG9wIHN1ZG9pbmcgYXMgdGhlIFVzZXJcIiBhcyBzMlxuc3RhdGUgXCJXaGF0J3MgdGhlIGNvbnRlbnQgdGhlIFVzZXIgY2FuJ3QgYWNjY2Vzcz9cIiBhcyBzM1xuc3RhdGUgXCJHbyB0byB0aGUgRGFzaGJvYXJkIFNwYWNlXCIgYXMgczRcbnN0YXRlIFwiQ2hlY2sgdGhlIFNwYWNlIHBlcm1pc3Npb25zIHNldHRpbmdzXCIgYXMgczVcbnN0YXRlIFwiQWRkIHRoZSBVc2VyIHBlcm1pc3Npb25zIHRvIGJyb3dzZSB0aGUgU3BhY2VcIiBhcyBzNlxuc3RhdGUgXCJDbGljayBvbiBhbiBFeHBsb3JlIG9mIHRoZSBEYXNoYm9hcmQgdGhhdCdzIG5vdCBsb2FkaW5nXCIgYXMgczdcbnN0YXRlIFwiQ2hlY2sgd2hpY2ggTW9kZWwgdGhlIEV4cGxvcmUgaXMgYWNjZXNzaW5nXCIgYXMgczhcbnN0YXRlIFwiTG9vayBhdCB0aGUgdXJsLCBpdCdzIHVzdWFsbHkgaW4gdGhpcyBmb3JtYXQgaHR0cHM6Ly9udWJhbmsubG9va2VyLmNvbS9leHBsb3JlL01PREVMX05BTUUvRVhQTE9SRV9OQU1FXCIgYXMgczhcbnN0YXRlIFwiR28gdG8gdGhlIFJvbGVzIHBhZ2VzXCIgYXMgczlcbnN0YXRlIFwiaHR0cHM6Ly9udWJhbmsubG9va2VyLmNvbS9hZG1pbi9yb2xlc1wiIEFTIHM5XG5zdGF0ZSBcIkNoZWNrIHdoaWNoIFJvbGUgaGFzIHRoZSBwZXJtaXNzaW9ucyB0byBhY2Nlc3MgdGhlIE1vZGVsXCIgYXMgczEwXG5zdGF0ZSBcIkNoZWNrIHdoaWNoIEdyb3VwIGhhcyB0aGUgUm9sZSBhdHRhY2hlZCB0byBpdFwiIGFzIHMxMVxuc3RhdGUgXCJBZGQgdGhlIFVzZXIgdG8gdGhlIEdyb3VwXCIgYXMgczEyXG5bKl0gLS0-IHMxXG5zMSAtLT4gWypdOiBVc2VyIGNhbiBhY2Nlc3MgdGhlIGNvbnRlbnRcbnMxIC0tPiBzMjogVXNlciBjYW4ndCBhY2Nlc3MgdGhlIGNvbnRlbnRcbnMyIC0tPiBzM1xuczMgLS0-IHM0OiBJdCdzIERhc2hib2FyZFxuczMgLS0-IHM4OiBJdCdzIGFuIEV4cGxvcmVcbnM0IC0tPiBzNVxuczUgLS0-IHM2OiBVc2VyIGRvZXNuJ3QgaGF2ZSBhY2Nlc3MgdG8gdGhlIFNwYWNlXG5zNSAtLT4gczc6IFVzZXIgaGFzIGFjY2VzcyB0byB0aGUgU3BhY2VcbnM2IC0tPiBzMVxuczcgLS0-IHM4XG5zOCAtLT4gczlcbnM5IC0tPiBzMTBcbnMxMCAtLT4gczExXG5zMTEgLS0-IHMxMlxuczEyIC0tPiBzMSIsIm1lcm1haWQiOnsidGhlbWUiOiJkZWZhdWx0In19](looker-debug-access.png)

## Adding a new BPO to Looker

Refer to this [video guide](https://drive.google.com/file/d/1jjVEI2lIN7mnGAiR3MZ3jvlJ1SEgPSmz/view) on how to do this.
Ask @leonardo.matsuura for help.

## Disable Users who left Nubank

This process is done to free up Looker licenses, as disabled users do not count as used licenses.

To disable users refer to this notebook [this notebook](https://github.com/nubank/data-access/blob/master/looker-migration/not-nubanker-disabler.ipynb).
