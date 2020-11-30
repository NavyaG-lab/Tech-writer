---
owner: "#data-infra"
---

# Inventory

## Services

### Clojure services in the prod stack

These are "normal" Clojure services that get deployed in our main infrastructure for production services.

- [barragem](https://github.com/nubank/barragem)
- [castor](https://github.com/nubank/castor)
- [conrado](https://github.com/nubank/conrado)
- [correnteza](https://github.com/nubank/correnteza), ([overview](/primer.md#correnteza-overview))
- [curva-de-rio](https://github.com/nubank/curva-de-rio)
- [cutia](https://github.com/nubank/cutia)
- [escafandro](https://github.com/nubank/escafandro)
- [metapod](https://github.com/nubank/metapod), ([overview](/primer.md#metapod-overview))
- [ouroboros](https://github.com/nubank/ouroboros)
- [alph](https://github.com/nubank/alph)
- [tapir](https://github.com/nubank/tapir)
- [veiga](https://github.com/nubank/veiga)

### Context on why services are sharded, shard-aware, or just global

At nubank we have this notion of sharding our customer-base into horizontal instances of our production stack.
This is to allow us to tune scaling needs to a fixed size and when we run out of space, we create a new shard.
Squads that deal with customers almost exclusively have sharded services, where service `mango` is deployed on all `X` shards and none of `mango`'s logic needs to know about the shard abstraction or other deployments of `mango`.

Data-infra is a little unique because we have sharded services, global services, and global services that are shard-aware

#### sharded services

##### alph

`alph` consumes from the `EVENT-TO-ETL` topic on the shard it deployed on. It sorts those messages into their respective dataset-series, batches them up as AVRO files on s3, and sends a commit message to the `NEW-SERIES-PARTITIONS` topic.

`alph` substituted the service `riverbend`. `Riverbend` solved the same problem as `alph`, however due to its faulty implementation it used to frequently lose events that it was processing.

##### correnteza

`correnteza` connects to datomic database and extracts change logs, storing them as AVRO files on s3, and registers metadata for those files in a docstore. It is a service sharded service that only extracts from databases within its shard.

`correnteza` was previously a shard-aware service in global that would extract from datomic databases across all shards. This was problematic because we needed more liberal security policies to allow `correnteza` to read from all databases. Additionally, scaling was a bit trickier because with `N` shards, every new service would add `N` new databases.

Note that `correnteza` collects input data for the datomic contracts layer of the ETL. When the ETL starts it needs to read this data. For whatever reason, the ETL reads directly from `correnteza`'s extraction metadata docstore. Given `correnteza` used to live on global, the ETL would just read from this one table. When we sharded `correnteza`, we left all the different shards still writing to the single global extraction metadata docstore.

##### conrado

`conrado` is an HTTP front-end to the serving layer docstore. The docstore holds data for all customers, across all shards.

`conrado` was previously a service global that services across all shards would access. We decided to shard it after a bad crash. By sharding `conrado` we reduced the blast radius of outages. For instance, we had some issues with pods auto-scaling and coming up and back when `conrado` lived in global it brought down functionality for the entire customer base.

#### global services

##### cutia

Consumes from the `DATASET-COMMITTED` and for every archive dataset that is computed sends it as an input to an archive dataset-series on `ouroboros`. It talks with the global instance of `ouroboros`, so it doesn't need to know about shards.

##### metapod

Tracks metadata for the ETL run.

Currently lives in the global shard in brazil account but is being migrated to the global shard of the data account.

##### veiga

A HTTP-to-Kafka proxy for sending kafka data between AWS accounts. This is needed to get around some cross-account communication limitations and allow `metapod` to send `DATASET-COMMITTED` messages to all the different countries.

Will reside in every country and be hit by the data account `metapod`.

#### global shard-aware services

##### tapir (shard-aware kafka production)

`tapir` does two things, it loads data into the single serving layer docstore shared by all shards and it publishes dataset rows to kafka. When publishing rows to kafka, we need to be sure to send the row to the relevant shard, where the customer or loan or whatever lives. Hence, `tapir` is shard-aware: it doesn't have one kafka producer component, it has `N`, where `N` is the number of shards. It uses the appropriate shard producer to send the message only to that kafka cluster.

##### ouroboros (shard-aware kafka consumption)

`ouroboros` keeps track of input data for dataset-series and serves it to the ETL when it starts. Since a lot of input data for dataset-series comes from `alph` serializing events to s3, and `alph` is sharded, `ouroboros` either needs to be sharded or shard-aware. On the other hand, since it talks to the ETL, it is nicer to have `ouroboros` serves this dataset-series metadata to the ETL, so it is nice to have

### Front-ends

#### Clojurescript

- [eye-of-mauron](https://github.com/nubank/eye-of-mauron)
- [sonar](https://github.com/nubank/sonar): **DEPRECATED** in favor of sonar-js

#### Javascript

- [sonar-js](https://github.com/nubank/sonar-js), ([overview](/primer.md#sonar-overview))

#### 3rd-party

- [Looker](https://nubank.looker.com/)
- [Databricks](https://nubank.cloud.databricks.com/login.html)
- [Google BigQuery Console](https://console.cloud.google.com/bigquery?project=nubank-data-access)

### Python services in the prod stack

These are Python services to support online machine learning models in production.

- [charlotte](https://github.com/nubank/charlotte)
- [lusa](https://github.com/nubank/lusa)

### Deprecated services not currently running

- [weissman](https://github.com/nubank/weissman)

## Accessing data

- [belomonte](https://github.com/nubank/belomonte), ([overview](/primer.md#belo-monte))
- [imordor](https://github.com/nubank/imordor)

## Common libraries

- [common-etl](https://github.com/nubank/common-etl), moved into the `itaipu` repo
- [common-etl-spec](https://github.com/nubank/common-etl-spec)
- [metapod-client](https://github.com/nubank/metapod-client)
- [common-etl-python](https://github.com/nubank/common-etl-python)

## Daily batch-related projects

- [itaipu](https://github.com/nubank/itaipu), [primer](../../services/data-processing/itaipu/itaipu.md), [dev workflow](../../how-tos/itaipu/workflow.md), [overview](/primer.md#itaipu-overview)
- [scale-cluster](https://github.com/nubank/scale-cluster)
- [deploy-airflow](https://github.com/nubank/deploy-airflow)
- [aurora-jobs](https://github.com/nubank/aurora-jobs), ([overview](/primer.md#aurora-overview))

## Other projects

- [sabesp](https://github.com/nubank/sabesp), ([overview](/primer.md#sabesp-overview))
- [data-tribe-go-scripts](https://github.com/nubank/data-tribe-go-scripts)
- [data-infra-adr](https://github.com/nubank/data-infra-adr)

## Infrastructure

- Mesos clusters (`stable`, `test`, `dev`, `dev2`)
- Databricks
- Google BigQuery (`nubank-data-access`, `staging-nubank-data-access`)
- Airflow, ([overview](/primer.md#airflow-overview))
