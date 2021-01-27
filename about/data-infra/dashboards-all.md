---
owner: "#data-infra"
---

# Dashboards

This guide provides you with a list of dashboards in Looker and Grafana that DI engineers and Managers can visualize and monitor the data.

The dashboards that are available in Looker under Data Infra will provide the visibility on yesterday's (D(current day)-1) data. The following are some of the use cases that describes how you can use these dashboards:

- Use these dashboards to compare the dataset performance, i.e historical performance of a dataset vs current performance, and correlate this with the changes on github repos or PRs.
- Optimization of the scheduler, is often based on historical computation of datasets. The hausmeister has to know the list of nodes where a group of datasets compute and see the possibility of moving it to run earlier in the day.

The following is the list of dashboards that are useful.

<b>Note</b>: In addition to the dashboards below, there are other important dashboards that are essential and heavily used by Hausmeisters. Refer to [dashboards for Hausmeisters](../../on-call/data-infra/dashboards.md) for more information.

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
     <td><a href="https://nubank.looker.com/dashboards/4240">Dataset Lifecycle</a>
    </td>
    <td>The purpose of this dashboard is to provide a glimpse of the happy path of a given dataset's lifecycle by enabling the comparison of a given dataset lifecycle between different daily runs; or by comparing different datasets lifecycle within a given daily run.</td>
    <td>sparkop_evaluation_events, aurora_pipeline_events, data_infra_serving_layer_sla_monitoring, spark_op_types, and metapod__transactions</td>
</tr>
</table>

## Grafana Dashboards

### Data Infra specific dashboards

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
    <td><a href="https://prod-grafana.nubank.com.br/d/000000301/dataset-series-ingestion?orgId=1&refresh=5m">Monitor Dataset series Ingestion</a></td>
    <td>Use this for monitoring the kafka messages processing rate, kafka lag on prototypes and prototypes lag over time.</td>
</tr>
<tr>
    <td><a href="https://prod-grafana.nubank.com.br/d/A8ULVDTmz/correnteza-datomic-extractor-service?orgId=1">Monitor Datomic Ingestion</a></td>
    <td>Use this for monitoring the Correnteza, a datomic data extractor service.</td>
</tr>
<tr>
   <td><a href="https://prod-grafana.nubank.com.br/d/XEIhxKHMz/ouroboros-monitoring?orgId=1">Monitor Ouroboros</a></td>
    <td>Use this for monitoring the Ouroboros service status, compaction latency, details about resource groups, etc.</td>
</tr>
</td>
</table>

### General dashboards

<table>
<tr>
    <td><b>Dashboards</b></td>
    <td><b>Purpose</b></td>
</tr>
<tr>
    <td><a href="https://prod-grafana.nubank.com.br/d/000000222/kafka-lags-topic-view?orgId=1&refresh=1m">About Kafka lags</a>
    </td>
    <td>
        Use this for inspecting Kafka topics and monitoring lag.
    </td>
</tr>
<tr>
    <td><a href="https://prod-grafana.nubank.com.br/d/000000276/jvm-by-service?orgId=1">JVM Metrics monitoring</a>
    </td>
    <td>Use this for monitoring JVM metrics (total instances, CPU usage, memory used etc) of Clojure service.
    </td>
</tr>
<tr>
     <td><a href="https://prod-grafana.nubank.com.br/d/000000268/kubernetes-cpu-and-memory-pod-metrics?orgId=1&refresh=1m">Kubernetes CPU & Memory Pod Metrics</a>
    </td>
    <td>Use this for monitoring Kubernetes resources usage.</td>
</tr>
</tr>
</table>
