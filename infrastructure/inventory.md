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
- [riverbend](https://github.com/nubank/riverbend)
- [tapir](https://github.com/nubank/tapir)
- [veiga](https://github.com/nubank/veiga)

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

- [itaipu](https://github.com/nubank/itaipu), [primer](/itaipu/primer.md), [dev workflow](/itaipu/workflow.md), [overview](/primer.md#itaipu-overview)
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
