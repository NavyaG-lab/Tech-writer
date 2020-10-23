---
owner: "#data-access"
---

<!-- markdownlint-disable MD026-->

# Views in BigQuery

**Materialized views** - Materialised views are created incrementally from the raw streaming data. The materialized views contain data - from the moment the contract was created to 5am BRT. Querying the materialized views are generally faster and consume less resources, as BigQuery will only need to retrieve the precomputed data (from the last day).

**Views** - Views contain the materialized data combined with the delta changes in the data from 5 am BRT till the time of query. Therefore, it is guaranteed that the views will always contain the fresh data.

You can have access to the following views:

- Contract history
- Contracts
- Contracts PII
- Contracts history PII

Contract history tables provide the entire information about Datomic contracts - from the moment the data is being processed by Barragem up until the current time. If you choose to have the most recent version of data of the customers, use the **Contracts** view.

!!! Important: Currently, the above materialised views are restricted to all. To access the data, you must first [get access](streaming-contracts-intro.md) to the Streaming Contracts feature.

## Viewing batch and streaming contracts

In BigQuery, by default, the tables for batch contracts and streaming contracts are under different projects.

- For batch contracts - [nu-br-data](https://console.cloud.google.com/bigquery?project=nu-br-data&p=nu-br-data&d=contract&page=dataset)
- For streaming contracts - [nu-br-streaming](https://console.cloud.google.com/bigquery?project=nu-br-streaming&p=nu-br-streaming&d=contract&page=dataset)

Currently, the streaming contracts system computes only some real-time Contracts, as the system currently supports very specific use cases. However, you can use batch contracts ([nu-br-data](https://console.cloud.google.com/bigquery?project=nu-br-data&p=nu-br-data&d=contract&page=dataset)) as it is guaranteed that Itaipu contains all datasets and the historical data.

If you need a new database to be added to the streaming contracts system, request it via a slack channel - **#tf-streaming-contracts**.

## Checking the freshness of data

All rows in the streaming contract table contain a `db__tx_instant field`, which indicates the date and time of the record. Therefore, by querying the maximum value for this field on a table, you can check the last updated date and time of the data.

### Tools to access views

You can access the contracts data using the following tools:

- [Google Bigquery](https://console.cloud.google.com/bigquery?project=nu-br-streaming&p=nu-br-streaming&d=contract&page=dataset)
- Jupyter Notebook
You can access streaming contracts from Jupyter Notebook through [Tapajós](https://github.com/nubank/belomonte):

`tp = belomonte. Tapajos(project_id_override='nu-br-streaming')`
