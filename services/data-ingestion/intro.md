---
owner: "#data-infra"
---

# ETL - Data Layers

## Data Ingestion

A layer that ingests data into the ETL system. It is the process of ingesting data for use in the analytical environment.

 **Data Ingestion Services**

- [Correnteza](./correnteza.md)
- [Alph](./alph.md)
- [Curva-de-rio](./curva-de-rio.md)
- [Ouroboros](https://github.com/nubank/ouroboros)
- [Cutia](https://github.com/nubank/cutia)

## Data Processing

It usually includes data cleansing, standardization, transformation, and aggregation.

- **Batch processing services**

  - [Itaipu](/services/data-processing/itaipu/itaipu.md)
  - [Metapod](/services/data-processing/metapod.md)

- **Streaming service**

  - [Barragem](https://github.com/nubank/barragem/blob/master/doc/architecture.md)

## Data Serving

It is the layer that provides access to the results of calculations performed on the master datasets.

- [Tapir](/services/data-serving/serving-layer.md)
- [Veiga](/services/data-serving/serving-layer.md)
- [Conrado](/services/data-serving/serving-layer.md)
- [Monsoon](/services/data-serving/serving-layer.md)

## Data Analysis and Monitoring

It is the layer where computed data is available in the Analytical environment, in Data Access tools.

- **Monitoring**

  - [Escafandro](https://github.com/nubank/escafandro)
  - [Looker](https://nubank.looker.com/login)

- **Analysis**

  - [Databricks](../../tools/databricks/README.md)
  - [Google BigQuery]
- **Performance**
- [Castor](https://github.com/nubank/castor)
- [Pollux](https://github.com/nubank/itaipu/tree/master/src/main/scala/nu/data/infra/pollux)
