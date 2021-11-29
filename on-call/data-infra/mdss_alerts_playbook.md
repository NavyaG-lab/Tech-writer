---
owner: "#data-infra"
---

# MDSS Alerts Playbook

## Ouroboros - Number of newly created manual series resource groups higher than expected

## Number of newly created manual series resource groups higher than expected

### Overview

This is not an urgent, matter-of-hours, alert, but it is an important one that shouldn't go unnoticed for a long time.

If you are a Hausmeister who is not already familiar with the context of this alert and/or have to deal with something more urgent, it is enough that you simply notify the IO team about this alert.

### Context

In order to make manual series deletable, we create a new resource group every time someone appends a resource to a manual series.

This alert means that a manual series got a lot of new resources (and, therefore, resource groups) in the configured period.

Since some manual series are actually automated and get a lot of new resources every day, the performance price of making them deletable would be too high, and we maintain a deny-list of such series.

A series that is deny-listed doesn't get a new resource group for each new resource and, as a consequence, cannot be deleted from.

### Troubleshooting

Using the [Manual Series Group Creation Monitoring](https://nubank.splunkcloud.com/en-US/app/search/manual_series_group_creation_monitoring) dashboard, identify the exact series for which a lot of resource groups have been created lately.

What to do next with such series depends on a few things:

* Is the increase in resource group creation a one-time thing (due to a backfill, for example) or something that will keep happening on a regular basis?

  This can possibly be deduced from some of the following:
  - Series name (e.g. it might have "backfill" in its name)
  - Source email (e.g. something-ingestor@nubank.com.br indicates that this is probably an automated series, whereas name.last.name@nubank.com.br
is more likely to be the source email of a one-time manual ingestion)
  - What's the distribution of new resources through time? (e.g. if a series got 100 new resource groups 10 days ago and nothing after that, it's more likely to be a one-time thing than if the series has been getting 10 new resources every day)
  - Alternatively, or if no definite conclusion can be reached using the above criteria, you can simply contact the users in charge of the series in question
and ask them about the expected future behavior of the series.

* Is the series PII?

  This can be checked directly by looking at Itaipu code for the series (specifically, checking the value of its clearance attribute).

  If the series is not classified as PII, but you think it should or could be one day, it's best to talk to the user and double-check this.

* How many new resource groups exactly did the series get?

  Is it just slightly above the configured threshold or is it much higher?

### Solution

If the increase in the number of new resource groups for this series was a one-time thing and we don't expect it to continue getting similar numbers of resources on a regular basis, nothing needs to be done.

If the series is not PII and we expect its resource groups to continue growing regularly, it should be added to the deletion-deny-list in the appropriate country's config(s) (e.g. [BR config](https://github.com/nubank/ouroboros/blob/config/src/prod/ouroboros_br_config.json#L6))

If the series is both automated and PII, this is a situation we didn't optimize for in our design and the matter should be raised with the IO team.

Depending on how high the number of new resource groups is, some of the following might be done: change the alert threshold, talk to the user and see if we can suggest improvements for their flow, prioritize work on batch ingestion etc.

Unless you are 100% sure you understand the alert and the solution, please raise the issue in the IO team's channel.
