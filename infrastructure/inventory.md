# Inventory

## Services

### Clojure services in the prod stack

These are "normal" Clojure services that get deployed in our main infrastructure for production services.
- [metapod](https://github.com/nubank/metapod), ([overview](/primer.md#metapod-overview))
- [curva-de-rio](https://github.com/nubank/curva-de-rio)
- [warehouse](https://github.com/nubank/warehouse)
- [conrado](https://github.com/nubank/conrado)

### Front-ends
#### Clojurescript
- [eye-of-mauron](https://github.com/nubank/eye-of-mauron)
- [sonar](https://github.com/nubank/sonar): **DEPRECATED** in favor of sonar-js
#### Javascript
- [sonar-js](https://github.com/nubank/sonar-js), ([overview](/primer.md#sonar-overview))
#### 3rd-party
- [metabase](/primer.md#metabase)

### Python services in the prod stack

These are Python services to support online machine learning models in production.
- [charlotte](https://github.com/nubank/charlotte)
- [lusa](https://github.com/nubank/lusa)

### Clojure services in production, but outside of the prod stack

- [correnteza](https://github.com/nubank/correnteza), ([overview](/primer.md#correnteza-overview))
- [capivara](https://github.com/nubank/capivara), ([overview](/primer.md#capivara-clj-overview))

### Deprecated services not currently running
- [weissman](https://github.com/nubank/weissman)

## Accessing data

- [belomonte](https://github.com/nubank/belomonte), ([overview](/primer.md#belo-monte))
- [imordor](https://github.com/nubank/imordor)

## Common libraries

- [common-etl](https://github.com/nubank/common-etl)
- [common-etl-spec](https://github.com/nubank/common-etl-spec)
- [metapod-client](https://github.com/nubank/metapod-client)
- [common-etl-python](https://github.com/nubank/common-etl-python)

## Daily batch-related projects

- [itaipu](https://github.com/nubank/itaipu), [primer](/itaipu/primer.md), [dev workflow](/itaipu/workflow.md), [overview](/primer.md#itaipu-overview)
- [capivara](https://github.com/nubank/capivara)
- [scale-cluster](https://github.com/nubank/scale-cluster)
- [deploy-airflow](https://github.com/nubank/deploy-airflow)
- [tapir](https://github.com/nubank/tapir)
- [aurora-jobs](https://github.com/nubank/aurora-jobs), ([overview](/primer.md#aurora-overview))
- [parsa](https://github.com/nubank/parsa)
- [truta](https://github.com/nubank/truta)

## Other projects

- [sabesp](https://github.com/nubank/sabesp), ([overview](/primer.md#sabesp-overview))
- [datomic-backup-restore](https://github.com/nubank/datomic-backup-restore)
- [data-infra-adr](https://github.com/nubank/data-infra-adr)

## Infrastructure

- Mesos clusters (`stable`, `test`, `dev`, `dev2`)
- Redshift clusters (`stable`, `dev2`)
- Databricks
- Airflow, ([overview](/primer.md#airflow-overview))
