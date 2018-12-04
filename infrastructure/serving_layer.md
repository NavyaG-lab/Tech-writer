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

 - Make sure your dataset has the [serving layer mode](https://github.com/nubank/common-etl/blob/97d640d6c280f4dcedd7b65eae4a64b875f213f2/src/main/scala/common_etl/operator/ServingLayerMode.scala) set up properly; [for example](https://github.com/nubank/itaipu/blob/a77ca6e81c19e3331a96a1de3567a44671c2f7f9/src/main/scala/etl/dataset/policy/mgm_offenders/MgmOffendersPolicy.scala#L18). This will ensure your dataset is saved in the Avro format, with a number of partitions that is optimal for loading.
 - The serving layer mode has three modes right now: `NotUsed` (the default), `LoadedOnly` and `LoadedAndPropagated`, which define how the dataset should be sent to the serving layer. `LoadedOnly` datasets are available to be queried by normal production services, while `LoadedAndPropagated` datasets are also propagated via Kafka to notify other services whenever new data is available.
 - If you use the `LoadedAndPropagated` mode, you also have to specify a propagation key: it ensures we can find the appropriate prototype each row of your dataset belongs to, which is required to route them to the proper Kafka cluster (see [note](#note-on-prototype-column) below). The current valid propagation keys are `CreditCardAccount`, `Customer` and `Prospect`, and they require columns called `account__id`, `customer__id` and `prospect__id` to be available in the dataset, respectively.
 - Make sure your dataset's primary key ([for example](https://github.com/nubank/itaipu/blob/3e270152cc9f51200ad8423d7baf6d574c3aea57/src/main/scala/etl/dataset/policy/collections_policy/CollectionsUnionPolicy.scala#L53)) is distinct per row. This is necessary because the dataset's primary key is how you will access the row on `conrado`. The primary key is generally something like customer id, account id, cpf, etc.
 - Tests that fail if you change the schema [like here](https://github.com/nubank/itaipu/blob/93709a89e4243e56b048586a5dba0a8160007284/src/it/scala/etl/itaipu/ItaipuSchemaSpec.scala#L54).
   This is necessary because if we change the schema of a dataset loaded by `tapir` we need to ensure all downstream consumers of the data (your microservices) can handle this schema change.

## Tapir

`tapir` is a service that runs in the prod environment and listens to datasets being ready in the datalake using a list of dataset names, loading those datasets from s3 into a single DynamoDB table, and also making each row available as Kafka messages.
After this loading is done, it can optionally serve the dataset rows as Kafka messages. `conrado` handles serving this data out of the dynamo table via an HTTP interface, as described in the [next section](#conrado).

If the ETL run gets delayed, some datasets get delayed, and if your dataset depends on one of the affected ones, `tapir` may be run on the next calendar day, but still load data from the previous day.

As an engineer that would like to get data from ETL land into microservices land, you need to take the following into account:

### tell tapir to load the dataset

Your dataset is served automatically by Tapir according to the [Serving Layer Mode](#making-your-dataset-ready-for-the-serving-layer) associated with it, so no extra work is necessary.

### primary key

The primary key used when inserting rows of a dataset into the DynamoDB table is a conjunction of the primary key from the itaipu dataset (used as the dynamo hash key) along with the dataset name (used as the dynamo sort key).
Hence, if you have duplicate values in your primary key column, your dataset will fail while running the dataset SparkOp as it wouldn't be loadable from DynamoDB afterwards. This key is how you will access rows of the dataset when querying through `conrado`, via HTTP ([see below](#conrado)).

### setting serving style

The serving style is based on the [Serving Layer Mode](#making-your-dataset-ready-for-the-serving-layer) associated with the dataset.

The value of `LoadedOnly` instructs Tapir to load your dataset in the DynamoDB store where it will be available via http in `conrado`, which your service can hit.

You can alternatively set the Serving Layer Mode to `LoadedAndPropagated` to have the dataset rows be served via Kafka messages, as well as loaded in the db to queried from `conrado`. The dataset would be published to the `dataset-update` topic.

### when is data overwritten?

The ETL pipeline runs once a day and will load the results of the datasets in the list into the dynamo table. Data from previous loads is not cleared, but when new data is inserted at a primary key that already exists, it will be overwritten for that primary key. So if your dataset `recalculate-customer-limits` produces a new limit for every customer every day, then the data in the dynamo table will be updated for every customer every day. But if your dataset includes a customer only once a month, similar to what is done with `proactive-limit-increases`, then the data for a customer will only get refreshed once a month.


## Payload schema

Data is served either via HTTP or Kafka as [`DatasetRow`](https://github.com/nubank/common-schemata/blob/9cf054a6665341e0b44495151fa7ca2f744f5886/src/common_schemata/wire/tapir.clj#L6-L14)s, which contain some metadata and a `:value` key which is a map containing:

 - `:identifier`: the primary key value of the itaipu dataset
 - `:dataset`: the dataset name defined in itaipu, but with the prefix dropped. So `policy/collections-union` becomes `collections-union`
 - `:transaction-id`: the [metapod transaction](/glossary.md#transaction) that the dataset was a part of.
 - `:dataset-id`: the id for the dataset on metapod
 - `:prototype`: what shard the customer/account is associated with (not required)
 - `:expires-at`: loose proxy for when the data may become overwritten. We suggest you ignore this as it doesn't mean data will necessarily be overwritten before or after this time.
 - `:target-date`: the day that the data was loaded
 - `:value`: a map representing the row of the dataset

## Conrado

`conrado` is a service that runs in the prod environment. It serves data out the DynamoDB table that `tapir` loaded data into, via an HTTP interface, described below:

 - _fetch many_ `/api/dataset/:id`: gets the results for all datasets loaded into `conrado`'s table with the provided id/entry primary key (i.e. customer ID or account ID)
 - _fetch one_ `/api/dataset/:id/:dataset`: gets the row of a dataset given the primary key id

For example, running

```
nu ser curl GET global conrado /api/dataset/beefbeef-dead-beef-94fb-79cf00d68730/reactive-limit-optimal-limits -- -v
```

will result in

```json
{
  "identifier": "beefbeef-dead-beef-94fb-79cf00d68730",
  "transaction_id": "f6c45ccc-11f5-5717-99e8-3dc10221e531",
  "dataset_id": "5b19c743-13cf-4ffe-89bd-5413d2b58e0d",
  "expires_at": "2018-06-09T23:59:59Z",
  "target_date": "2018-06-08",
  "dataset": "reactive-limit-optimal-limits",
  "value": {
    "amount": 400,
    "account__id": "5ab2b6b4-723e-47db-94fb-79cf00d68730"
  }
}
```

## Kafka

`tapir` can serve datasets via Kafka, publishing to the `DATASET-UPDATE` with the subtopic set to the dataset name. The payload schema is the same as the http endpoints in `conrado`, which is [`common-schemata.wire.tapir/DatasetRow`](https://github.com/nubank/common-schemata/blob/9cf054a6665341e0b44495151fa7ca2f744f5886/src/common_schemata/wire/tapir.clj#L6-L14).


#### note on prototype column

Using the propagation key, `itaipu` automatically looks up the prototype each rows belongs to and adds this information in a `prototype` column. `tapir` then uses this `prototype` column to know which shard to produce the message on. In case the dataset row ends up not containing a value for the `prototype` column, `tapir` ignores the row and does not propagate it.

## Monitoring

[Splunk Dashboard for ETL Serving Layer](https://nubank.splunkcloud.com/en-US/app/search/etl_serving_layer_tapir)

This provides visibility as to whether data has been loaded and propagated today or over the last few days.
