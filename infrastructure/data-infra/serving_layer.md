---
owner: "#data-infra"
---

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

You can follow this nice tutorial on [how to write a dataset](../../how-tos/itaipu/create_basic_dataset.md)

### Making your dataset ready for the serving layer

Make sure your dataset has the [serving layer mode](https://github.com/nubank/common-etl/blob/97d640d6c280f4dcedd7b65eae4a64b875f213f2/src/main/scala/common_etl/operator/ServingLayerMode.scala) set up properly; [for example](https://github.com/nubank/itaipu/blob/a77ca6e81c19e3331a96a1de3567a44671c2f7f9/src/main/scala/etl/dataset/policy/mgm_offenders/MgmOffendersPolicy.scala#L18). This will ensure your dataset is saved in the Avro format, with a number of partitions that is optimal for loading.

The serving layer mode has four modes right now that define how the dataset should be sent to the serving layer:

- `NotUsed`: the default
- `LoadedOnly`: datasets are only available to be queried by normal production services via Conrado
- `PropagatedOnly`: datasets can only be consumed via Kafka and are not loaded into Conrado's docstore
- `LoadedAndPropagated`: datasets can be queried via Conrado and are also propagated via Kafka to notify other services whenever new data is available.

#### loading into a persistent table

If you use either the `LoadedAndPropagated` or `PropagatedOnly` modes, you also have to specify a propagation key: it ensures we can find the appropriate prototype each row of your dataset belongs to, which is required to route them to the proper Kafka cluster (see [note](#note-on-the-prototype-column) below). The current valid propagation keys are listed [here](https://github.com/nubank/common-etl/blob/master/src/main/scala/common_etl/operator/ServingLayerPropagationKey.scala) (eg: `CreditCardAccount`, `Customer` and `Prospect` that require the columns called `account__id`, `customer__id` and `prospect__id`, respectively). If you want your all the rows to be propagated to the `global` prototype you should use the `Global` key.

Make sure your dataset's primary key ([for example](https://github.com/nubank/itaipu/blob/3e270152cc9f51200ad8423d7baf6d574c3aea57/src/main/scala/etl/dataset/policy/collections_policy/CollectionsUnionPolicy.scala#L53)) is distinct per row. This is necessary because the dataset's primary key is how you will access the row on `conrado`. The primary key is generally something like customer id, account id, cpf, etc.

#### data expiration

With serving layer data that is loaded into the serving layer table (`LoadedAndPropagated` or `LoadedOnly` modes), you must also specify when you would like that data to be wiped from the docstore and hence no longer retrievable via `conrado`. The options are `ServingLayerExpiration.NeverExpires` ([example](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/dataset/batch_models/fraud_daily/collisions/ServingAddressCollisions.scala#L45)) and `ServingLayerExpiration.ExpiresIn(days=5)` ([example](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/datasets/data_infra/DummyServedDataset.scala#L30)]. For `ServingLayerExpiration.ExpiresIn(days=X)`, the data will be wiped at the end of day of the `targetDay + X`, so if the target day is `2020-02-02` and `days` is `2`, the data will be wiped at `2020-02-04 23:59:59`.

#### integrity checks

Itaipu requires at least two `IntegrityCheck`s to be added to your dataset in order for it to be served in the serving layer: `UniqueColumn` and `NonBlankColumn` on the dataset's primary key. To do so, check your primary key name according to the dataset's `attributes` field and then declare the integrity checks like so:

```scala
// other imports and package

import common_etl.operator.IntegrityCheck.{NonBlankColumn, UniqueColumn}

object YourDataset extends SparkOp with DeclaredSchema {
  //...
  override def integrityChecks: Set[IntegrityCheck] = Set(UniqueColumn("your_primary_key"), NonBlankColumn("your_primary_key"))
  //...
}
```

## Tapir

`tapir` is a service that runs in the prod environment and listens to datasets being ready in the datalake using a list of dataset names, loading those datasets from s3 into a single DynamoDB table, and also making each row available as Kafka messages.
As Nubank's ETL is rewritten on a daily basis, the rows of the propagated dataset will be published as Kafka messages everyday.
After this loading is done, it can optionally serve the dataset rows as Kafka messages. `conrado` handles serving this data out of the dynamo table via an HTTP interface, as described in the [next section](#conrado).

If the ETL run gets delayed, some datasets get delayed, and if your dataset depends on one of the affected ones, `tapir` may be run on the next calendar day, but still load data from the previous day.

As an engineer that would like to get data from ETL land into microservices land, you need to take the following into account:

### Tell Tapir to load the dataset

Your dataset is served automatically by Tapir according to the [Serving Layer Mode](#making-your-dataset-ready-for-the-serving-layer) associated with it, so no extra work is necessary.

### Primary key

The primary key used when inserting rows of a dataset into the DynamoDB table is a conjunction of the primary key from the itaipu dataset (used as the dynamo hash key) along with the dataset name (used as the dynamo sort key).
Hence, if you have duplicate values in your primary key column, your dataset will fail while running the dataset SparkOp as it wouldn't be loadable from DynamoDB afterwards. This key is how you will access rows of the dataset when querying through `conrado`, via HTTP ([see below](#conrado)).

### Setting serving style

The serving style is based on the [Serving Layer Mode](#making-your-dataset-ready-for-the-serving-layer) associated with the dataset.

The value of `LoadedOnly` instructs Tapir to load your dataset in the DynamoDB store where it will be available via http in `conrado`, which your service can hit.

You can alternatively set the Serving Layer Mode to `LoadedAndPropagated` to have the dataset rows be served via Kafka messages, as well as loaded in the db to queried from `conrado`.

### When is data overwritten

The ETL pipeline runs once a day and will load the results of the datasets in the list into the dynamo table. When new data is inserted at a primary key that already exists, it will be overwritten for that primary key. So if your dataset `recalculate-customer-limits` produces a new limit for every customer every day, then the data in the dynamo table will be updated for every customer every day. But if your dataset includes a customer only once a month, similar to what is done with `proactive-limit-increases`, then the data for a customer will only get refreshed once a month. Data from previous loads might get cleared depending on the existence of a `ServingLayerExpirationTimestamp`. See [data expiration](#data-expiration) for more details.

## Dataset Row Schema

Data is served either via HTTP or Kafka. The payload is a [`dataset
row`](https://github.com/nubank/common-etl-spec/blob/master/src/common_etl_spec/serving_layer/schemata/dataset.clj#L31-L41),
which contain some metadata and a `:value` key. The row is a map containing the following fields:

- `:identifier`: the primary key value of the itaipu dataset
- `:dataset`: the dataset name defined in itaipu, but with the prefix dropped. So `policy/collections-union` becomes `collections-union`
- `:transaction-id`: the [metapod transaction](/glossary.md#transaction) that the dataset was a part of.
- `:dataset-id`: the id for the dataset on metapod
- `:prototype`: what prototype (eg: global, s0, s1, ...) the customer/account is associated with (not required)
- `:expires-at`: if a [data expiration](#data-expiration) policy is set, this is the human-readable datetime of when the row expires and hence stops being available in the serving layer table. When data expiration isn't set (defaulting to `ServingLayerExpiration.NeverExpires`) this is `"9999-12-31T23:59:59Z"`.
- `:target-date`: the day that the data was loaded
- `:value`: a map representing the row of the dataset

### Note on the prototype column

Using the propagation key, `itaipu` automatically looks up the
prototype each rows belongs to and adds this information in a
`prototype` column. `tapir` then uses this `prototype` column to know
which shard to produce the message on. In case the dataset row ends up
not containing a value for the `prototype` column, `tapir` ignores the
row and does not propagate it.

#### Example

Here's an example of the row with id
`11111111-1111-1111-1111-111111111111` of the `dummy-served` dataset
fetched from Conrado with the following command:

```shell
nu ser curl GET global conrado --accept application/edn /api/dataset/dummy-served/row/11111111-1111-1111-1111-111111111111 | zprint
```

The response for this dataset looks like this:

```clojure
{:dataset "dummy-served",
 :dataset-id #uuid "5ddc6b92-ec4c-46e6-828d-1c5069cdcf11",
 :expires-at #nu/time "2019-11-27T23:59:59Z",
 :serving-layer-expiration-timestamp #nu/Int 183267472027,
 :identifier "11111111-1111-1111-1111-111111111111",
 :prototype "global",
 :schema-id #uuid "5dc98514-491a-452a-ad6d-4e66eb111727",
 :target-date #nu/date "2019-11-26",
 :transaction-id #uuid "91848d54-c42c-5d77-b1d6-d51cc3d11f3b",
 :value {:example-boolean true,
         :example-booleans [true false],
         :example-date #nu/date "1970-01-01",
         :example-dates [#nu/date "1970-01-01" #nu/date "1970-01-01"],
         :example-decimal 0E-18M,
         :example-decimals [1.000000000M 2.000000000M],
         :example-double 0N,
         :example-doubles [1N 2N],
         :example-enum "enum-1",
         :example-enums ["enum-1" "enum-2"],
         :example-integer 0,
         :example-integers [1 2],
         :example-keyword :keyword-1,
         :example-keywords [:keyword-1 :my-ns/keyword-2],
         :example-string "aaa",
         :example-strings ["aaa" "bbb"],
         :example-timestamp #nu/time "1970-01-01T00:00:00Z",
         :example-timestamps [#nu/time "1970-01-01T00:00:00.001Z"
                              #nu/time "1970-01-01T00:00:00.002Z"],
         :example-uuid #uuid "11111111-1111-1111-1111-111111111111",
         :example-uuids [#uuid "22222222-2222-2222-2222-222222222222"
                         #uuid "33333333-3333-3333-3333-333333333333"],
         :id #uuid "11111111-1111-1111-1111-111111111111",
         :prototype "global"}}
```

## Plumatic Schemas

The [Sarcophagus](https://github.com/nubank/sarcophagus) project publishes the Plumatic schemas of the serving layer datasets as artifacts to the `nu-maven` repository. You can use theses schemas as a dependency in your service if you don't want write them yourself. Take a look at this [guide](https://github.com/nubank/sarcophagus#how-can-i-use-a-dataset-artifact) to learn more about how to use those artifacts.

## Conrado

`conrado` is a service that runs in the prod environment. It serves data out the DynamoDB table that `tapir` loaded data into, via an HTTP interface, described below. To hit said endpoints from a service, please add the service and the dataset it will use on this [scopes list](https://github.com/nubank/conrado/blob/master/src/conrado/logic/auth.clj#L11). If you need to hit the service from NuCLI you'll need to set up a dedicated scope for yourself and your team, and add it in the same way to that scopes list file.

### Bookmarks & Sachem

When declaring bookmarks to consume a dataset from Conrado, please DO
NOT add the `:dataset` parameter into the URL of the bookmark, because
otherwise Sachem will use a very generic schema to check against and
not the schema of the dataset.

If you are going to consume 2 datasets, `my-dataset-1` and
`my-dataset-2`, please add 2 bookmarks for them, like in the following
example:

```
"bookmarks": {
  "my-dataset-1" : {"url": "{{services.conrado}}/api/dataset/my-dataset-1/row/:id", "service": "conrado"},
  "my-dataset-2" : {"url": "{{services.conrado}}/api/dataset/my-dataset-2/row/:id", "service": "conrado"}
}
```

💣 Please DO NOT add the `:dataset` parameter to the URL like in the
following example:

```
"bookmarks": {
  "my-datasets" : {"url": "{{services.conrado}}/api/dataset/:dataset/row/:id", "service": "conrado"},
}
```

### GET /api/dataset/:name/row/:id

Gets a single row of a dataset given the `:name` of the dataset and
the `:id` of a row in the path parameters in the URL. Use this
endpoint if the `:id` is not PII data, and you don't mind that it
shows up in logs (Splunk for example). This endpoint supports Sachem
and schema coercion.

```shell
nu ser curl GET global conrado --accept application/edn /api/dataset/dummy-served/row/11111111-1111-1111-1111-111111111111 | zprint
```

#### POST /api/dataset/:name/row

Gets a single row of a dataset given the `:name` of the dataset in the
path, and the `:id` of the row in the body parameters of the
request. Use this endpoint if the `:id` is PII data and should NOT
show up in any logs. This endpoint supports Sachem and schema
coercion.

```shell
nu ser curl POST global conrado --accept application/edn /api/dataset/dummy-served/row -d '{"id": "11111111-1111-1111-1111-111111111111"}' | zprint
```

##### POST /api/dataset/:name/rows

Gets multiple rows of a dataset given the `:name` of the dataset in
the path, and the `:ids` of the rows in the body parameters of the
request. The `:ids` will not show up in the logs, so it is also safe
to use for PII data. This endpoint supports Sachem and schema
coercion.

```shell
nu ser curl POST global conrado --accept application/edn /api/dataset/dummy-served/rows -d '{"ids": ["11111111-1111-1111-1111-111111111111", "22222222-2222-2222-2222-222222222222"]}' | zprint
```

##### GET /api/dataset/:id/:name (deprecated soon)

Gets the row of a dataset given the primary key id. This endpoint does
not support Sachem, nor schema coercion.

```shell
nu ser curl GET global conrado  --accept application/edn /api/dataset/11111111-1111-1111-1111-111111111111/dummy-served | zprint
```

##### GET /api/dataset/:id (deprecated soon)

Gets the results for all datasets loaded into `conrado`'s table with
the provided id/entry primary key (i.e. customer ID or account
ID). This endpoint does not support Sachem, nor schema coercion.

```shell
nu ser curl GET global conrado  --accept application/edn /api/dataset/11111111-1111-1111-1111-111111111111 | zprint
```

## Kafka

When a dataset is declared to be propagated, Tapir serves the rows of
a dataset through a dedicated Kafka topic for each dataset. The name
of the Kafka topic is derived from the dataset name suffix, and is
called `SERVING-<DATASET-SUFFIX>`. If the name of your dataset is
`dataset/dummy-served`, the name of the Kafka topic would be
`SERVING-DUMMY-SERVED`.

The messages in the dedicated Kafka topics conform to an extended
version of Tapir's dataset row schema. The row of a dataset lives
under the `:value` key of Tapir's dataset `Row` schema and is coerced
and checked against the schema declared in Itaipu.

The `SERVING-<DATASET-NAME>` Kafka topics have Sachem integration and
data types are coerced to their schema types.

## Monitoring

[Splunk Dashboard for ETL Serving Layer](https://nubank.splunkcloud.com/en-US/app/search/etl_serving_layer_tapir)

This provides visibility as to whether data has been loaded and propagated today or over the last few days.
