---
owner: "#data-infra"
---

# Glossary

Work-in-progress, please add placeholders or info as you come across new terminology

Table of contents

* [transaction](#transaction)
  * [reference and target date](#reference-and-target-date)
  * [transaction-type](#transaction-type)
* [dataset](#dataset)
* [logical type schema](#logical-type-schema)
* [Permanence of a dataset](#Permanence-of-a-dataset)

## transaction

A **metapod transaction** is a concept present in metapod, which is composed by a set of datasets and it's used to group those together in a logical semantic unit, such as a daily batch of data consumed and processed.

### reference and target date

ETL transactions have several date fields:

* target date: the date for which Itaipu begins to run
* reference date: the day for which we have the most complete data, i.e. `targetDate - 1`
* started at: the datetime that the ETL run began

This is some standard values for an ETL transaction:

```
"startedAt": "2019-09-05T00:02:54.189Z"
"targetDate": "2019-09-05"
"referenceDate": "2019-09-04"
```

### transaction type

ETL transactions can be run for different reasons and hence are given different types. These are important so that we know what to do with the computed data.

Types

* Daily: The normal daily ETL run, data will be loaded into BigQuery, serving layer, databricks, etc.
* Hotfix: A manual run meant to fix an issue in production. Will trigger downstream logic in data warehouse, serving layer, etc.
* Debug, Custom, Unknown: A custom manual run used for debugging and testing
* Compaction: for compacting dataset series
* Copied: Represents a transaction that was (partially) created by copying another. Usually for debugging

### dataset

It is essentially a piece of data in a table-like structure.

It is usually, but not always, accompanied by metadata associated with it, such as the date (e.g. when it was produced, consumed, persisted, committed, or copied), where to find (e.g. S3 path) it and a name (e.g. `bills-past-due`). Services such as `metapod` can also track the schema for a dataset and any other metadata about it.

### schema

The specification of some logical data structure, such as an event, a dataset, a Clojure map, etc. It can be used to set expectations of what the structure looks like (e.g. fields/columns and their types and length) and also to validate a given structure of the data. It is used pervasively across many different contexts.

For more info, see: <https://github.com/nubank/playbooks/blob/master/docs/glossary.md#schemas>

#### logical type schema

##### Rationale

##### Types

Base types: `DOUBLE, INTEGER, DECIMAL, UUID, ENUM, STRING DATE, TIMESTAMP`

Complex types: `ARRAY of X (where X is a base type)`

##### Representations

###### JSON

Logical type schemas need to be passed between systems, such as between our Scala batch processing code and our metadata store. We do this by encoding them as JSON.

[Here is an example](/data-users/etl_users/manual_series_schema.json) of a logical type schema encoded as JSON. Below is a snippet of it:

```json
{
    "attributes": [
      {
        "name": "example_enum",
        "primaryKey": false,
        "logicalType": "DOUBLE",
        "logicalSubType": null
      },
      {
        "name": "id",
        "primaryKey": true,
        "logicalType": "UUID",
        "logicalSubType": null
      },
      ...
      ]
}
```

### Scala

`SparkOp` datasets in `itaipu` need to define a logical type schema if they are to be used in various contexts (the data-warehouse, the serving-layer, as archives, etc.)
This is done by overriding the `attributes` field of the `SparkOp`, [for example here](https://github.com/nubank/itaipu/blob/bc7bdd85301ba46418f1b116f3679f7cf844983c/src/main/scala/etl/dataset/data_infra/DummyServedDataset.scala#L39-L98).

This schema is registered in `metapod`, our metadata store. We also validate that the schema defined matches the data produced by the dataset, failures of which can be seen [on this dashboard](https://nubank.splunkcloud.com/en-US/app/search/etl__dataset_issues_monitoring?earliest=%40d&latest=now&form.squad=*)

### Clojure

We use logical types to describe the event data sent from production services to the ETL via `alph`.

These logical types are encoded using edn and their format is described in [`common.ingestion.schema`](https://github.com/nubank/common-ingestion/blob/master/src/common/ingestion/schema.clj)

### Permanence of a dataset

Datasets are marked as either `ephemeral` or `permanent`, and this dictates what s3 bucket we place them in.
Ephemeral s3 buckets are configured to delete files that are over 1 week old, while permanent datasets are kept forever.
