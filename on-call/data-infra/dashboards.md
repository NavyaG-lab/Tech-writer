---
owner: "#data-infra"
---

# Dashboards

The dashboards that are available in Looker under Data Infra will provide the visibility on yesterday's (D(current day)-1) data. The following are the list of use cases that describes how a Hausmeister can use these dashboards:

- Hausmeisters can use these dashboards to understand the issue pattern i.e if an issue has emerged suddenly or if it’s part of a broader pattern.
- Use these dashboards to compare the dataset performance, i.e historical performance of a dataset vs current performance, and correlate this with the changes on github repos or PRs
- Performance problems on a dataset are often caused by a slow degradation of its compute time. Hausmeisters usually become aware of this when it is not possible for Itaipu to compute. But having the historical data helps Hausmeisters to determine the root cause.
- Optimization of the scheduler, is often based on historical computation of datasets. The hausmeister has to know the list of nodes where a group of datasets compute and see the possibility of moving it to run earlier in the day.
- Whenever a hausmeister need to get insights from the data and investigate to prevent most repeated issues, they can use the historical data to strategically identify the things that can be improved permanently for the future.

The following are the dashboards available on Looker:

- [Dataset computation](https://nubank.looker.com/dashboards/3860)
- [Amount of data we process, time and success rates](https://nubank.looker.com/dashboards-next/3918)
- [Data Infra SLO Monitoring](https://nubank.looker.com/dashboards/2367?Contracts-Type=datomic&filter_config=%7B%22Contracts-Type%22:%5B%7B%22type%22:%22%3D%22,%22values%22:%5B%7B%22constant%22:%22datomic%22%7D,%7B%7D%5D,%22id%22:1%7D%5D%7D)
- [TimelineExecution_SparkOpsWithinAirflowNode](https://nubank.looker.com/looks/2610)
