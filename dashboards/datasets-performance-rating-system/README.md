---
owner: "#analytics-chapter-engineering"
title: "Datasets Performance Rating System"
toc: false
---

**Audience**

The Datasets Performance Rating dashboard is intended for all data users or dataset owners.

## What you'll learn

This documentation walks you through the datasets performance dashboard, datasets rating system, metrics considered, visibility over non-performant datasets. It also provides the details of the most urgent issues and ways to fix them.

- [Introduction](#introduction)
- [Tutorial on How to use dashboard](dashboards/datasets-performance-rating-system/tutorial-how-to-use-dashboard.md)
- [How to fix non-performant datasets](dashboards/datasets-performance-rating-system/how-to-fix-nonperformant-dashboards.md)

==This guide assumes that you're already familiar with [creating datasets](../datasets/basic-datasets/create-dataset-flow.md).==

## Introduction

The [Datasets Performance Rating](https://datastudio.google.com/reporting/eb3ec818-9bcc-478d-bf95-d707a8440d44/page/p_qwuxgef1oc) dashboard shows the non-performant datasets identified during Itaipu run. The datasets performance rating system classifies the datasets as non-performant and performant based on specific metrics - aborted count, skew ratio, and execution time.

In addition, one of the objectives of the datasets performance rating system is to help you fix your non-performant datasets by providing a detailed explanation of the problem on the dashboard.

## Usecases

As a dataset owner, you can use the dashboard to

- check if your dataset is classified as non-performant dataset
- ways to fix if it is non-performant

## Datasources

The dataset.dataset_performance_metrics collects all the metrics and calculations needed to classify a dataset as non-performant or performant. This `dataset.dataset_performance_metrics` dataset is used to generate the dashboard. To know the description of this dataset and associated columns, navigate to the [compass](https://backoffice.nubank.com.br/compass/#details/dataset/dataset-performance-metrics).

## Data freshness in dashboard

The dashboard currently shows the datasets' performance based on the data computed two days before the current day. (T-2, T-current day)

## Metrics

### Performance metrics

Currently, the following are the three metrics used to calculate the performance of a dataset.

**Aborted count**: Rate a dataset based on the number of times it aborted in the past 7 days

**Skew Ratio**: Rate a dataset based on the maximum skew ratio of the stages in the respective run ( task max execution time/task median execution time)

**Execution Time**
Rate a dataset based on its execution time in minutes

#### Metrics rating

A rating is calculated for each metric. The greater the rating, the more critical or non-performant a dataset is on that specific metric.

The following table shows the rating for each metric calculated based on the defined criteria.

|Rating|Aborted Count|Skew Ratio|Execution Time|
|------|-------------|----------|--------------|
|-1| If data to calculate the metric is missing|
|3|If aborted count is greater than 3 times consecutively| If skew ratio is greater than 1000|If execution time is greater than 120|
|2|greater than 3 times|greater than 100|greater than 60|
|1|at least once| greater than 50|greater than 30|
|0|was not aborted|below 50|below 30|

### Performance rating

A rating is calculated for each metric. The greater the rating, the more critical or non-performant a dataset is on that specific metric. Based on the rating value, the dashboard shows different rating levels:

- **Severe**: Performance rating is above 7 or aborted count rating is 3 and any other metric is missing
- **High**: Performance rating between 4 and 7
- **Medium**: Performance rating between 1 and 3

!!! Note
 Currently, the performance rating is the sum of the values of all the rating metrics - except when they're -1.
!!!

==Currently, the dashboard shows the details of high and severe non-performant datasets.==

## What's Next

- [Tutorial on How to use dashboard](dashboards/datasets-performance-rating-system/tutorial-how-to-use-dashboard.md)
- [How to fix non-performant datasets](dashboards/datasets-performance-rating-system/how-to-fix-nonperformant-dashboards.md)
