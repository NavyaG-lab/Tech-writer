# The ETL Serving Layer

Say you have some megacool dataset that you want to use in one of your squad's microservices.
Datasets live near the datalakes of Cantareira, while microservices prefer the arid centrão of São Paulo; so how do you make this work?

With [Tapir](https://github.com/nubank/tapir/) and [Conrado](https://github.com/nubank/conrado/)!


- [Itaipu](#itaipu)
- [Tapir](#tapir)
- [Conrado](#conrado)
- [Monitoring](#monitoring)

## Itaipu

Before we get to our friends `tapir` and `conrado` we need to chill at the local dam with some brejas and get some work done.

### Writing a dataset

You can follow this nice tutorial on [how to write a dataset](/itaipu/create_basic_dataset.md)

### Making your dataset ready for the serving layer

 - Make sure your dataset is exported using the [serving layer functor](https://github.com/nubank/itaipu/blob/3e270152cc9f51200ad8423d7baf6d574c3aea57/src/main/scala/etl/itaipu/functors.scala#L90); [for example](https://github.com/nubank/itaipu/blob/3e270152cc9f51200ad8423d7baf6d574c3aea57/src/main/scala/etl/dataset/policy/collections_policy/package.scala#L20). Note, if you use the serving layer functor, you shouldn't also use `avroizeWithSchemaFunctor` on your dataset, because that will create two avro versions of the dataset.
   This will ensure your dataset is saved in the AVRO format, with a number of partitions that is optimal for loading.
 - The serving layer functor has the `joinColumn` optional argument. This can be set to `account__id` or `customer__id`, given that one of those columns exists in your dataset. Using `joinColumn` will add a `prototype` column to each entry with the appropriate shard info for that account/customer. The `prototype` column allows `conrado` to produce messages to the correct shard during dataset propagation.
 - Make sure your dataset's primary key ([for example](https://github.com/nubank/itaipu/blob/3e270152cc9f51200ad8423d7baf6d574c3aea57/src/main/scala/etl/dataset/policy/collections_policy/CollectionsUnionPolicy.scala#L53)) is distinct per row. This is necessary because the dataset's primary is how you will access the row on `conrado`. The primary key is generally something like customer id, account id, cpf, etc.
 - Tests that fail if you change the schema [like here](https://github.com/nubank/itaipu/blob/93709a89e4243e56b048586a5dba0a8160007284/src/it/scala/etl/itaipu/ItaipuSchemaSpec.scala#L54).
   This is necessary because if we change the schema of a dataset loaded by `tapir` we need to ensure all downstream consumers of the data (your microservices) can handle this schema change.

## Tapir

Tapir is a CLI script that walks the datalake with a list of datasets, loading those datasets from s3 into a single DynamoDB table.
After this loading is done, `conrado` handles serving this data out of the dynamo table, as described in the [next section](#conrado).

Tapir runs once a day towards the end of the daily ETL run. If the ETL run gets delayed `tapir` may be run on the next calendar day, but still load data from the previous day.

As an engineer that would like to get data from ETL land into microservice land, you need to take the following into account:

### tell tapir to load the dataset

Open a PR on `tapir` that adds your dataset name to the [`dataset-whitelist`](https://github.com/nubank/tapir/blob/e0fb144c25cd2320e0535c7d08c63133c08d5fc9/src/tapir/logic.clj#L11) and adds a line to the [logic test](https://github.com/nubank/tapir/blob/e0fb144c25cd2320e0535c7d08c63133c08d5fc9/test/tapir/logic_test.clj#L12) ([example PR](https://github.com/nubank/tapir/pull/52)). Note that the dataset name may be `policy/foo` but `tapir` needs the avro version, so be sure to add a `-avro` to the end of the name

Once this gets merged it will run as part of the following day's ETL run.

### primary key

The primary key used when inserting a dataset's row into the DynamoDB table is a conjunction of the primary key from the itaipu dataset (used as the dynamo hash key) along with the dataset name (used as the dynamo sort key).
Hence, if you have duplicate values in your primary key column, your dataset can't be loaded.
This key is how you will access rows of the dataset when getting data from `conrado` via http ([see below](#conrado)).

### setting serving style

By default `tapir` will tell `conrado` to make your data available via http endpoints your service can hit.

You can also have the dataset be served via kafka by adding your dataset to the [`propagatable-dataset-whitelist`](https://github.com/nubank/tapir/blob/e0fb144c25cd2320e0535c7d08c63133c08d5fc9/src/tapir/logic.clj#L24).
This will tell `conrado` to serve your dataset by publishing to the `dataset-update` topic.

### when is data overwritten?

`tapir` runs once a day and will load the results of the whitelisted datasets into the dynamo table. Data from previous loads is not cleared. Rather, when data is inserted at a primary key that already exists, it will be overwritten. So if your dataset `recalculate-customer-limits` produces a new limit for every customer every day, then the data in the dynamo table will be updated for every customer every day. But if your dataset includes a customer only once a month, similar to what is done with `proactive-limit-increases`, then the data for a customer will only get refreshed once a month.

### DAG topology

The [ETL DAG](https://airflow.nubank.com.br/admin/airflow/graph?dag_id=prod-dagao) has two nodes corresponding to the serving layer:

- `tapir-load`: performs the dataset loading. Should finish under an hour, but if it fails you need to retry the entire thing, because it doesn't keep state on which datasets loaded successfully.
- `tapir-propagate`: the step where `tapir` communicates to `conrado` to perform this propagation via http. This finishes in less than a minute, but the actual propagations take much longer, given they have to happen in serial due to dynamo limitations.


## Conrado

`conrado` is a service that runs in the prod environment that serves data out the DynamoDB table that `tapir` loaded data into.
It can do this via http endpoints or producing kafka messages to the `dataset-updated` topic:

### payload schema

`conrado` serves data as [`DatasetRow`](https://github.com/nubank/common-schemata/blob/9cf054a6665341e0b44495151fa7ca2f744f5886/src/common_schemata/wire/tapir.clj#L6-L14)s, which contain some metadata and a `:value` key which is a

 - `:identifier`: the primary key value of the itaipu dataset
 - `:dataset`: the dataset name defined in itaipu, but with the prefix dropped. So `policy/collections-union` becomes `collections-union`
 - `:transaction-id`: the [metapod transaction](/glossary.md#transaction) that the dataset was a part of.
 - `:dataset-id`: the id for the dataset on metapod
 - `:prototype`: what shard the customer/account is associated with (not required)
 - `:expires-at`: loose proxy for when the data may become overwritten. We suggest you ignore this as it doesn't mean data will necessarily be overwritten before or after this time.
 - `:target-date`: the day that the data was loaded
 - `:value`: a map representing the row of the dataset

### http

 - _fetch many_ `/api/dataset/:id`: gets the results for all datasets loaded into `conrado`'s table with the provided id/entry primary key (i.e. customer id or account id)
 - _fetch one_ `/api/dataset/:id/:dataset`: gets the row of a dataset given the primary key id

For example, running

```
nu ser curl GET global conrado /api/dataset/beefbeef-dead-beef-94fb-79cf00d68730/reactive-limit-optimal-limits -- -v
```

will result in

```
{"identifier":"beefbeef-dead-beef-94fb-79cf00d68730",
"transaction_id":"f6c45ccc-11f5-5717-99e8-3dc10221e531",
"dataset_id":"5b19c743-13cf-4ffe-89bd-5413d2b58e0d",
"expires_at":"2018-06-09T23:59:59Z",
"target_date":"2018-06-08",
"dataset":"reactive-limit-optimal-limits",
"value":{"amount":400,"account__id":"5ab2b6b4-723e-47db-94fb-79cf00d68730"}}
```

### kafka

`conrado` can serve datasets via kafka, publishing to the `DATASET-UPDATE` with the subtopic set to the dataset name. The payload schema is the same as the http endpoints: `DatasetRow`.
Due to limitations of scanning DynamoDB tables, `conrado` currently can only propagate one dataset at a time. Hence, `conrado` uses the kafka topic `to-propagate` to queue up and process dataset propagations one at a time. This means that dataset propagation can take a while given there are several datasets being propagated.

`conrado` uses the `prototype` column added via the `joinColumn` of the serving layer functor on itaipu to know which shard to produce the message on.

## Monitoring

[Splunk Dashboard for ETL Serving Layer](https://nubank.splunkcloud.com/en-US/app/search/etl_serving_layer)

This provides visibility as to whether data has loaded and been propagated today or over the last few days you can look at the
