---
owner: "#data-access"
---

<!-- markdownlint-disable MD026-->

# Streaming Contracts

## Introduction

This guide describes the changes introduced in processing and serving contracts to the analytical environment through a new feature - Streaming Contracts. It outlines the challenges involved with the existing analytics tool, Mordor, and contracts generated and served through Itaipu.

This guide walks you through:

- Streaming contracts architecture and its capabilities
- Data process flow and the microservices involved
- Logical reasons involved in developing Streaming Contracts and how will it help Nubankers
- Reasons for migrating from Mordor analytics tool to Google BigQuery or Jupyter Notebooks
- Guaranteed data freshness and more.

This guide assumes that you're familiar with writing SQL queries, BigQuery, or Jupyter notebooks.

## Challenges

The primary challenges are:

- Mordor has been the analytics tool at Nubank over the past few years. Lately, we have discovered that Mordor is susceptible to arbitrary code execution and could potentially allow direct access to the Production database, which could lead to a major data breach.
- Lack of near-real-time data: Currently, processing a huge volume of latest data and making it available in an analytical environment in real-time is a stumbling block. Due to this higher latency, the real-time data is not accessible to quickly analyze and provide helpful insights into the business conditions and customer engagement.
- A real-time fraud detection - Detecting and preventing false transactions.

### Overview

The above reviewed challenges can be dealt with, if we have a solution, well-organized and thought-through architecture. The Streaming contracts system scales to meet the needs of an analytical environment - accessing the near-real-time data in a safer analytical tool.

The Streaming Contracts, a low-latency contracts system quickly extracts data from different microservices production databases. It then transforms and processes the data to make it available for the analytical environment.

This system enables you to quickly query a big volume of streaming data and extract the latest version of contracts within an hour (eventually the time will be reduced to minutes and seconds). It helps you to view the contracts data quickly and make real-time decisions for the changing business conditions.

!!! Note: Currently, the low-latency contracts system supports streaming data that is already available on the ETL system.

**New Users:** The streaming contracts feature is accessible only upon raising a request. Get started by [submitting the form](https://forms.gle/isYrmebwiWzFvUkK6) for feature access.

### Why Streaming Contracts

#### Streaming Contracts over Itaipu contracts?

- Data can be used for other strategic purposes in batch mode, but there is a window of opportunity with streaming contracts - The ability to collect, process, analyze, and act on a continuing stream of data in real time. The data-driven immediate actions can strengthen ties with customers and enable organizations to quickly respond to business conditions.
- Streaming contracts process data into analytics tools as soon as they are generated and display analytics results quickly, whereas Itaipu contracts are processed in batches. Therefore, the latency of Streaming Contracts will be from minutes to an hour, while with Itaipu Contracts it can take more than 24 hours.
- Reduces the time to update data. Access fresh data with a maximum of 1 hour delay.

#### BigQuery over Mordor?

BigQuery provides fine-grained access to sensitive data in columns using policy tags, or type-based classification, which safeguards the customers PII data. On the other hand, Mordor allows arbitrary code execution and direct access to production databases resulting in poor data security.

- Supports running custom queries in SQL to retrieve desired contracts.
- Protects sensitive data by restricting access to the PII data.
- Stores Contracts historical data in BigQuery and makes it accessible.
- Supports multiple tools for data visualisation - BigQuery UI, Jupyter Notebook.

#### Other Key differences between Mordor and Streaming Contracts

|Mordor (current solution)|Streaming Contracts (new solution)|
|--------------------------|---------------------------------|
|Queries written in datalog, unknown to most non-engineers.|Queries written in SQL, widely known and easy to teach.|
|Require one query per shard.|Single query for all shards.|
|Known security flaws like arbitrary code execution.|Guarantees against undesired access.|
|Provides access to the PII data that endangers the customers identity and credit information.|Access restrictions to the PII data.|
|Direct access to the production database.|Access to a filtered copy of production.|

### Get feature access

All Nubankers should have general access to streaming contracts:

- 🇧🇷 Brazil: [nu-br-streaming](https://console.cloud.google.com/bigquery?project=nu-br-streaming)
- 🇲🇽 Mexico: [nu-mx-streaming](https://console.cloud.google.com/bigquery?project=nu-mx-streaming)
- 🇨🇴 Colombia: [nu-co-streaming](https://console.cloud.google.com/bigquery?project=nu-co-streaming)

For PII access fill out this [forms](https://nubank.atlassian.net/servicedesk/customer/portal/53/group/246/create/920).

## Next steps

- [How fresh data is processed and transformed](data-freshness.md)
- [View data in Google BigQuery](views-bigquery.md)
