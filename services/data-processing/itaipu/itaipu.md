---
owner: "#data-infra"
---

# Itaipu

* [Itaipu](https://github.com/nubank/itaipu) is where we compute data, including everything from raw -> contract -> dataset -> dimension / fact, declaring the dependencies as inputs to each SparkOp (aka dataset). It's basically a mini-DAG within the broader Airflow DAG
  * Raw & contract - see: <https://github.com/nubank/data-infra-docs/blob/master/services/data-processing/itaipu/itaipu.md#structure>
    * Converts from Datomic's data model to a tabular SQL data model (a subset of what Datomic is capable of)
    * Users generally access contracts as the lowest level of abstraction which already eliminates sharding-related fragmentation
  * Dataset (SparkOp)
    * We want people at Nubank to be able to create new tables as a function of existing tables
    * The contracts are the source for all downstream datasets (and the contract definitions are hardcoded and statically checked within Itaipu)
    * SparkOps are pure - they don't control how they are run, in what order, where their inputs are stored, or where their outputs will be stored. Itaipu orchestrates this to ensure that dependencies are scheduled in the correct order (and optimized). Itaipu also manages how many partitions to use when writing dataset output to metapod and S3.
  * Itaipu's mini-DAG
    * Because datasets depend on contracts and other datasets, this produces a directed acyclic dependency graph. Confusingly, this is a mini-DAG. The overall DAG is a superset of the Itaipu mini-DAG.
  * Dimensions & fact tables
    * [Kimball principles](../../../tools/iglu/kimball.md)
  * Unit testing approach
    * [Unit tests in Itaipu](../../../how-tos/itaipu/styleguide.md#unit-test-style) are designed to [test any non-trivial transformation step in isolation](../../../how-tos/itaipu/styleguide.md#transform-test-granularity). Generally we do not test the entire SparkOp on a unit basis.
  * Integration test
    * The Itaipu integration test is able to statically check the entire Itaipu mini-DAG and raise errors if there are any broken column references, incorrect type signatures, unconventional names, etc. This allows us to catch errors sooner (which is important, because catching an error after the nightly run has been running for 5 hours is very high cost).
  * Workflow for building a new dataset
    * <https://github.com/nubank/data-infra-docs/blob/master/how-tos/itaipu/workflow.md#creating-a-new-dataset>

## Structure

| Name            | Raw               | Contract               | Dataset                            |
|:---------------:| ----------------- | ---------------------- | -----------------------------------|
| Metapod name    | `raw-$db/$entity` | `contract-$db/$entity` | `dataset/$name`                    |
| Redshift name   | N/A               | `contract.$db_$entity` | `origin.$name`                     |
| Databricks name | `raw.$db_$entity` | `contract.$db_$entity` | `dataset.$name`                    |
| Description     | Datomic entities  | References resolved    | Customer dataset                   |
| Sharding?       | Sharded           | Unsharded              | Unsharded                          |
| Schema type     | Operational       | Contract layer         | Analytical                         |
| Rawness         | Raw               | Slightly opinionated   | Opinionated                        |
| Level           | Single shard      | Single database        | Multi database                     |
| Owner           | Service squad     | Service squad          | Dataset writer                     |
| Code            | Attribute mapping | SparkOp                | SparkOp, Redshift schema           |
| PII             | Exposed           | Encrypted (hashed)     | Depends on the dataset<sup>1</sup> |

1. One must not expose PII in datasets destined for "public" consumption such as Redshift.

### Raw

A direct mapping of Datomic data to a flattened relational format, respecting Datomic's data model and its underlying
organization as much as possible.

Example (`raw.billing_s0__bills`):

|  e<sup>1</sup> | bill__status<sup>2</sup> | bill__id                               | bill__close_date |
|----------------|--------------------------|----------------------------------------|------------------|
| 17592186104411 |                       88 | `543d1730-e239-495a-a516-d0843e1d6aed` |       2014-10-13 |

1. Entity ID.
2. This is the entity ID of an ident.

### Contract

A view of the data that respects Datomic's data model as much as the raw level, but providing the minimal
transformations to abstract away the notion of sharded datasets, corrupted rows, and deprecated attributes. Also
provides documentation for each attribute and renames some attributes.

Example (`contract.billing__bills`):

| bill__status<sup>1</sup> | bill__id                               | bill__close_date | prototype<sup>2</sup> |
|--------------------------|----------------------------------------|------------------|-----------------------|
| `bill_status__paid`      | `543d1730-e239-495a-a516-d0843e1d6aed` |       2014-10-13 | s0                    |

1. The entity ID is now resolved to a string value.
2. The raw datasets are unioned into one contract and the prototype column show what shard this row is from

Examples:

- [`precise_amount` is renamed to `amount`](https://github.com/nubank/itaipu/blob/e08071693b5a416b1dfcc31bf4cf1e7abd45e42a/src/main/scala/etl/contract/feed/Transactions.scala#L57)
- Invalid entities are dropped...
  - [because data is corrupted upstream](https://github.com/nubank/itaipu/blob/e08071693b5a416b1dfcc31bf4cf1e7abd45e42a/src/main/scala/etl/contract/feed/Transactions.scala#L34)
  - [because data is missing](https://github.com/nubank/itaipu/blob/e08071693b5a416b1dfcc31bf4cf1e7abd45e42a/src/main/scala/etl/contract/feed/Transactions.scala#L31)
- [Datomic idents are resolved](https://github.com/nubank/itaipu/blob/e08071693b5a416b1dfcc31bf4cf1e7abd45e42a/src/main/scala/etl/contract/feed/Transactions.scala#L35)
- [consistent naming between primary keys and foreign keys](https://github.com/nubank/itaipu/pull/36/files#diff-6a9ae1da21068f4fad302be909a97b7dR20)

The definition for any given contract is hardcoded first in a Clojure model (which generates a Datomic schema).  From these models, Scala classes are generated, and they are hardcoded both in production services and in Itaipu.

* [Credit Card Account Model Example](https://github.com/nubank/credit-card-accounts/blob/master/src/accounts/models/account.clj#L44)
* [Generated Scala file for Credit Card Account in production](https://github.com/nubank/credit-card-accounts/blob/master/resources/nu/data/br/dbcontracts/credit_card_accounts/entities/Accounts.scala)
* [Generated Scala file for Credit Card Account pasted in Itaipu](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/dbcontracts/credit_card_accounts/entities/Accounts.scala)

### Dataset

Dataset is a table. Derived from the contract-level data, there is a need to have a alternative, better structured table to satisfy the needs of a customer (e.g. analyst). It's a view of the data, which can be used to make business decisions. Requires minimal transformations or calculations for the end user.

Synonym: _materialized view_

More specifically, it's usually a Parquet file on AWS S3.

#### How datasets are generated

Via `SparkOp`. It's a function over some data. Itaipu allows a declarative definition of dependencies, and does scanning via static analysis (contract definitions) to create filtered runs.

## See also

- [Contracts](../../../how-tos/itaipu/contracts.md)
- [Create basic dataset](../../../how-tos/itaipu/create_basic_dataset.md)
- [Datasetseries compaction](../../../how-tos/itaipu/dataset_series_compaction.md)
- [Datomic raw cache](../../../how-tos/itaipu/datomic-raw-cache.md)
- [Deploying new DAG](../../../how-tos/itaipu/deploying_new_dag.md)
- [Reviewing and merging a PR on Itaipu](../../../how-tos/itaipu/itaipu_reviewer.md)
- [Pii and personal data](../../../how-tos/itaipu/itaipu_reviewer.md)
- [Pororoca](../../../how-tos/itaipu/pororoca.md)
