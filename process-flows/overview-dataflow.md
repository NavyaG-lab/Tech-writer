---
owner: "#data-infra"
---

# Overview of Data flow in ETL environment

Data flows through different services, and transformation throughout these services converts the raw input into the required transformed dataset. This guide helps you to understand the data sources, how a data from data sources is ingested and transformed, and lifecycle of user-defined datasets.

## What you'll know

This guide is structured around,

- [How the data from datasources is ingested into ETL environment and transformed](data-transformation.md) - This topic describes how the data from data sources is ingested into the ETL environment, auto-genration of contracts, and transformation of SparkOp into a dataset.
- Lifecycle of a user defined dataset - This topic describes how the user-defined dataset is made available in the ETL environment for data transformation.

**What is a Dataset?**

A Dataset is an output of the daily run, computed by specific SparkOps. It essentially consists of a set of metadata associated with the set of files (partitions).

**What is a SparkOp?**

SparkOps are predominantly the functions that takes input from metadata stores (S3) i.e Correnteza incase of Datomic data and Ouroboros incase of Dataset series data, then transforms the data, and produces a dataset as an ouput. This transformed dataset is available on S3 in Metapod.

!!! **Note:** A dataset life starts at the time SparkOp is being computed.

Before you dive into every phase that the data goes through during its lifetime, you must be familiar with the data sources at Nubank and services involved in data ingestion layer:

### Data sources

There are two types of data sources from where the data is captured.

- **Nu Prod databses**: Data stored by the Microservices at Nubank on the production database (Datomic). The data which contains EAVT attributes are considered as the Datomic data.
- **Dataset series data**: Any data from sources other than Nubank's Production services (such as manually ingested data, data from external providers/partners, events/instrumentation, click-stream).

### Lifecycle of a user defined dataset

The user-defined datasets uses the existing contract datasets as the base datasets and define the necessary transformations that should run during the Itaipu daily run.

1. User creates a dataset by following the steps defined in the [Creating a Dataset](https://github.com/nubank/data-platform-docs/blob/4364d66520fde5b30d03ad89a5bf7b3a5fe080ea/how-tos/itaipu/create_basic_dataset.md) documentation and merges it into Itaipu.
1. During the run, Itaipu evaluates the dataset and checks when this dataset should run. It query Metapod to find the input data needed, run the transformations, and then commits the dataset i.e it writes to S3 and then also sends a message to Metapod about the S3 path and commited status.
1. After the dataset is successfully committed, it then goes through the steps involved in Serving layer, if necessary flags are set on the dataset. For more information, see the documentation on [serving-layer](https://github.com/nubank/data-platform-docs/blob/4364d66520fde5b30d03ad89a5bf7b3a5fe080ea/services/data-serving/serving-layer.md)
