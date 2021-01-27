---
owner: "#data-infra"
---

# Dashboards for Hausmeisters

This guide provides you with a list of dashboards in Looker and Grafana that Hausmeisters and Engineers can visualize and monitor the data.

The dashboards that are available in Looker under Data Infra will provide the visibility on yesterday's (D(current day)-1) data. The following are the list of use cases that describes how a Hausmeister can use these dashboards:

- Hausmeisters can use these dashboards to understand the issue pattern i.e if an issue has emerged suddenly or if it’s part of a broader pattern.
- Use these dashboards to compare the dataset performance, i.e historical performance of a dataset vs current performance, and correlate this with the changes on github repos or PRs
- Performance problems on a dataset are often caused by a slow degradation of its compute time. Hausmeisters usually become aware of this when it is not possible for Itaipu to compute. But having the historical data helps Hausmeisters to determine the root cause.
- Optimization of the scheduler, is often based on historical computation of datasets. The hausmeister has to know the list of nodes where a group of datasets compute and see the possibility of moving it to run earlier in the day.
- Whenever a hausmeister need to get insights from the data and investigate to prevent most repeated issues, they can use the historical data to strategically identify the things that can be improved permanently for the future.

## Looker Dashboards

The following are the dashboards available on Looker, and the data source for these is the Google Big Query. You can find the tables under `nu-br-data` project.

<table>
<tr>
    <td><b>Dashboards</b></td>
    <td><b>Purpose</b></td>
    <td><b>Data sources (<a href="https://console.cloud.google.com/bigquery?project=nu-br-data&page=queries">table names in BQ</a>)</b></td>
</tr>
<tr>
    <td><a href="https://nubank.looker.com/dashboards/3860">Dataset computation</a>
    </td>
    <td>Details datasets run per node, the no.of times a dataset is computed on different nodes, time taken for a dataset to compute on each node.
    </td>
    <td>itaipu_spark_stage_metrics & Itaipu_Step_metrics</td>
</tr>
<tr>
    <td><a href="https://nubank.looker.com/dashboards-next/3918">Amount of data we process, time and success rates</a>
    </td>
    <td>Total assets (contracts + datasets) computed and percentage of successfully loaded assets, percentage of datasets computed on a day and failed datasets in a week.
    </td>
    <td>spark_op_types & spark_ops_summary</td>
</tr>
<tr>
     <td><a href="https://nubank.looker.com/dashboards/2367?Contracts-Type=datomic&filter_config=%7B%22Contracts-Type%22:%5B%7B%22type%22:%22%3D%22,%22values%22:%5B%7B%22constant%22:%22datomic%22%7D,%7B%7D%5D,%22id%22:1%7D%5D%7D">Data Infra SLO Monitoring</a>
    </td>
    <td>Proportion of datasets committed to metapod on time (before 5:00) per day, datasets propogated to serving layer on time per day, serving layer lag, no.of rows propogated, & streaming contracts segements processing time.
    </td>
    <td>data_infra_contract_sla_monitoring &
    data_infra_serving_layer_sla_monitoring</td>
</tr>
<tr>
     <td><a href="https://nubank.looker.com/dashboards/4218">Dagao Timeline</a>
    </td>
    <td>How all Dagao nodes performed over the course of a daily ETL run. You can quickly identify bottlenecks, i.e., where the bulk of the time is spent for a specific run.</td>
    <td>airflow_aurora_operational_metrics</td>
</tr>
<tr>
     <td><a href="https://nubank.looker.com/dashboards-next/4252">Running time of Dagao nodes</a>
    </td>
    <td>This line chart allows you to understand the duration of different tasks over the past N ETL runs. It lets you visualise task duration and quickly understand how a given Dagao node is performing over many ETL runs</td>
    <td>airflow_aurora_operational_metrics</td>
</tr>
<tr>
     <td><a href="https://nubank.looker.com/dashboards/4240">Dataset Lifecycle</a>
    </td>
    <td>The purpose of this dashboard is to provide a glimpse of the happy path of a given dataset's lifecycle by enabling the comparison of a given dataset lifecycle between different daily runs; or by comparing different datasets lifecycle within a given daily run.</td>
    <td>sparkop_evaluation_events, aurora_pipeline_events, data_infra_serving_layer_sla_monitoring, spark_op_types, and metapod__transactions</td>
</tr>
</table>

## Grafana Dashboards

<table>
<tr>
    <td><b>Dashboards</b></td>
    <td><b>Purpose</b></td>
</tr>
<tr>
   <td><a href="https://prod-grafana.nubank.com.br/d/waGZJY2mk/serving-layer-monitoring?orgId=1">Monitor Serving Layer</a>
    </td>
    <td>
        Use this to monitoring dataset propogation details, rate of rows loaded by datasets, batch load and propogation latency, serve throughput etc.</td>
</tr>
<tr>
    <td><a href="https://prod-grafana.nubank.com.br/d/wMprEQbMz/airflow-metrics?orgId=1">Airflow Metrics</a></td>
    <td>Use this for monitoring number of tasks queued on Airflow, delay in scheduling the tasks on Airflow.</td>
</tr>
</td>
</table>
