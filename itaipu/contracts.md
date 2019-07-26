# Contract datasets

There are currently three kinds of datasets inside the contract layer:

- Entity datasets
- Attribute history datasets
- Entity history datasets (as of [2019/07/25][1] these datasest still
  do not exist in production)

## Entity datasets

Entity datasets represent the pivoted, current version of an entity from a Datomic database.
[The grain of the dataset](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/grain/) is one row per unique primary key of the entity.
This means it is a unified version across prototypes.

**Name template**: `contract-$database/$pluralizedEntityName`

**Sample name**: `contract-feed/transactions`

**Primary key columns**: primary key attribute of the entity (e.g. `transaction__id`)

Example:

| `transaction__id` | `prototype` | `transaction__status` | `transaction__amount` |
| --- | --- | --- | --- |
| `9b0f2622-0bb0-47b5-b5d5-ea08ccaa6555` | `s0` | `settled` | `10.54` |
| `211f5cfc-7cb1-4436-8cae-c8cfd5893170` | `s1` | `unsettled` | `5.50` |
| `7845d1ec-34ed-4f92-aeee-ac20ee60fc73` | `s0` | `waiting` | `42.24` |

## Attribute history datasets

Attribute history datasets represent the evolution of a given attribute from an entity from a Datomic database.
The grain of the dataset is one row per attribute update per entity per prototype.
This means it includes information from all prototypes.

**Name template**: `contract-$database/$attributeName-history`

**Sample name**: `contract-feed/transaction-status-history`

**Primary key columns**: primary key attribute of the entity, prototype and update timestamp (e.g. `[transaction__id, prototype, db__tx_instant]`)

Example:

| `transaction__id` | `prototype` | `transaction__status` | `db__tx_instant` |
| --- | --- | --- | --- |
| `9b0f2622-0bb0-47b5-b5d5-ea08ccaa6555` | `s0` | `waiting` | `2017-12-01 10:00:00` |
| `9b0f2622-0bb0-47b5-b5d5-ea08ccaa6555` | `s0` | `unsettled` | `2017-12-01 15:00:00` |
| `9b0f2622-0bb0-47b5-b5d5-ea08ccaa6555` | `s0` | `settled` | `2017-12-02 02:00:00` |
| `211f5cfc-7cb1-4436-8cae-c8cfd5893170` | `s1` | `waiting` | `2017-12-10 20:00:00` |
| `211f5cfc-7cb1-4436-8cae-c8cfd5893170` | `s1` | `unsettled` | `2017-12-10 22:00:00` |

## Entity history datasets

Entity history datasets represent the evolution of a given entity from an entity from a Datomic database.
The grain of the dataset is one row per versionf of the entity across time per prototype.
This means it includes information from all prototypes.
Each row represent a point-in-time snapshot of an entity: this means this is a superset of the entity dataset, i.e. all rows from the entity dataset are included in the snapshot dataset.

**Name template**: `contract-$database/$pluralizedEntityName-snapshot`

**Sample name**: `contract-feed/transactions-snapshot`

**Primary key columns**: primary key attribute of the entity, prototype and update timestamp (e.g. `[transaction__id, prototype, db__tx_instant]`)

Example:

| `transaction__id` | `prototype` | `transaction__status` | `transaction__amount` | `db__tx_instant` |
| --- | --- | --- | --- | --- |
| `9b0f2622-0bb0-47b5-b5d5-ea08ccaa6555` | `s0` | `waiting` | `10.54` | `2017-12-01 10:00:00` |
| `9b0f2622-0bb0-47b5-b5d5-ea08ccaa6555` | `s0` | `unsettled` | `10.54` | `2017-12-01 15:00:00` |
| `9b0f2622-0bb0-47b5-b5d5-ea08ccaa6555` | `s0` | `settled` | `10.54` | `2017-12-02 02:00:00` |
| `211f5cfc-7cb1-4436-8cae-c8cfd5893170` | `s1` | `waiting` | `5.50` | `2017-12-10 20:00:00` |
| `211f5cfc-7cb1-4436-8cae-c8cfd5893170` | `s1` | `unsettled` | `5.50` | `2017-12-10 22:00:00` |
| `7845d1ec-34ed-4f92-aeee-ac20ee60fc73` | `s0` | `waiting` | `42.24` | `2017-12-13 05:00:00` |

[1]: https://nubank.slack.com/archives/CFGDGFU78/p1564043751035800?thread_ts=1564040968.034100&cid=CFGDGFU78
