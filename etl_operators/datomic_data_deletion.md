---
owner: "#data-infra"
---

# Datomic data deletion

This documents describes part of the process to fulfill a data deletion request from a data subject to the ETL. In particular, it ensures that all the data subject data that was deleted from our Datomic data sources is propagated to the ETL.

This process was implemented in the context of the Data protection regulations enforced in each of the countries in which Nubank operates.

This process is meant to be automated in future iterations, but this is our first and minimal solution to the problem.

[comment]: <> (TODO: An explanation of the entire data deletion process for Datomic sources is missing.)

It is composed by 3 manual steps:

1. Find the Datomic transactions (Ts) affected by a completed excision request stored in Malzahar
2. Re-extract the Datomic log segments containing the affected Ts in Correnteza
3. Recompute the Datomic log caches for the affected databases in Castor

[comment]: <> (TODO: Add detailed step-by-step guide)

## Find the Datomic transactions affected by an excision request

We use a manual process to find the datomic transactions containing the
entities that are excised by malzahar. The process involves executing this
[databricks notebook](https://nubank.cloud.databricks.com/#notebook/2862587).
The notebook does the following:

1. Join malzahar contracts for `excise_requests` and `excise_fields` to get
   a dataframe with information about entities and attributes that have been
   excised in the production databases, as well as a list of the affected
   database-prototype combinations where the excisions happened.
2. Load all the relevant raw logs of these database-prototype combinations and
   union them into another dataframe.
3. Join these two dataframes with an inner join over `attribute_name` (which
   contains `database` information as well), `prototype` and `e` (entity id). If
   the resulting data frame has rows, group the `t`'s by database-prototype.
   Those are the `t`'s that correnteza needs for re-extraction (see next step).

A few notes:

1. If the extraction has been propagated successfully, the join will not yield
   any results anymore. Hence, the notebook can be executed repeatedly each day
   without any worries and without having to mark any excisions as having been
   propagated already. This step is idempotent. By virtue of this, it can also
   be used to check if a re-extraction worked: The resulting join here should
   be empty.
2. This notebook cannot be executed mindlessly. Paths to datasets change
   depending on country, cluster permissions for country and environment need
   to be chosen correctly, metapod communication does not work everywhere.
   These issues could be remedied over time, but we are blocked by other teams
   and by our own prioritization. So for now the relevant choices that one has
   to take are documented within the notebook and need to be respected when
   executing it.

## Re-extract the Datomic log segments in Correnteza

[Correnteza](https://github.com/nubank/correnteza) is the service at
Data Infra that extracts datoms from Datomic databases and stores them
in segments on S3. When data got deleted from a Datomic database, the
segments on S3 that have been extracted before the deletion, still
contain the data. Those segments need to be re-extracted.

Correnteza has HTTP endpoints that can be used to re-extract Datomic
log segments. To re-extract these segments you need to know the
database, the prototype and a list of Ts. This information comes from
the Notebook in the previous step. For each (database, prototype, Ts)
tuple the following steps need to be followed.

#### Setup environment variables

First, setup environment variables for a tuple you obtained from the
previous step. In this example we are going to re-extract the segments
that contain the transactions that happened at the database times
`95599,95764` from the `customers` database on the prototype `s0` in
the `staging` environment.

```shell
export ENV="staging"
export DATABASE="customers"
export PROTOTYPE="s0"
export TS="95599,95764"
```

#### Re-extract Datomic log segments

Next, send an HTTP request to Correnteza that schedules the
re-extraction of the segments for a given database, prototype and a
list of Ts. Correnteza will look up the segment for each T, and send a
message to a Kafka consumer that does the actual re-extraction in the
background.

```shell
nu ser curl POST $PROTOTYPE correnteza /api/admin/extractions/$PROTOTYPE/$DATABASE/reextract/ts --env $ENV -d "{:ts [$TS]}" -t application/edn
```

Correnteza should answer with a list of segments that are going to be
extracted. The output is a list of segments affected by those Ts. For
each T there should be segment that contains it. Also, notice the S3
paths of those segments. When the paths of these segments have
changed, Correnteza has finished the re-extractions.

```clojure
[{:database "customers",
  :initial-t 95599N,
  :last-batch-t 95595N,
  :last-t 95599N,
  :path "s3://nu-spark-datomic-logs-staging/logs/new-extractor2/br/s0/customers/ea25e93e-e14a-473b-b09a-83934ef2cd2a-95595-95599.avro",
  :prototype "s0",
  :requested-range [95599N 95600N],
  :timestamp 1585060243481N}
 {:database "customers",
  :initial-t 95764N,
  :last-batch-t 95763N,
  :last-t 95764N,
  :path "s3://nu-spark-datomic-logs-staging/logs/new-extractor2/br/s0/customers/3b0df555-794d-4ccf-89b7-a7152ba5d538-95763-95764.avro",
  :prototype "s0",
  :requested-range [95764N 95765N],
  :timestamp 1585060243760N}]
```

If this step fails, there's something wrong with Correnteza or the
list of Ts. If a segment for a T could not be found, Correnteza will
return an error message with the Ts in question and will not schedule
re-extractions for any of the Ts.

#### Verify that Correnteza has re-extracted the segments

To re-compute the Datomic log caches in the next section, you need to
wait until Correnteza has finished the re-extraction of the affected
segments. There's another endpoint on Correnteza that can be used to
resolve the segments for a database, prototype and a list of Ts. This
endpoint only resolves the Datomic log segments, but does not schedule
any re-extraction.

```shell
nu ser curl POST $PROTOTYPE correnteza /api/admin/extractions/$PROTOTYPE/$DATABASE/resolve --env $ENV -d "{:ts [$TS]}" -t application/edn
```

The output of the command lists all the segments affected by the given
database, prototype and list of Ts. It should return the same segments
as the command above, but with some fields updated.

```clojure
[{:database "customers",
  :initial-t 95599N,
  :last-batch-t 95595N,
  :last-t 95599N,
  :path "s3://nu-spark-datomic-logs-staging/logs/new-extractor2/br/s0/customers/1dfe311c-0a94-459b-851a-f305f5ea1f58-95595-95599.avro",
  :prototype "s0",
  :requested-range [95599N 95600N],
  :timestamp 1585067042508N}
 {:database "customers",
  :initial-t 95764N,
  :last-batch-t 95763N,
  :last-t 95764N,
  :path "s3://nu-spark-datomic-logs-staging/logs/new-extractor2/br/s0/customers/42cd74d0-2c3a-45be-89a1-1612ce9cbc82-95763-95764.avro",
  :prototype "s0",
  :requested-range [95764N 95765N],
  :timestamp 1585067042734N}]
```

When the `:path` and `:timestamp` fields of the segments are different
than the ones from the previous step, you know that Correnteza has
finished the re-extraction of the segments and you can proceed to the
next section.

## Recompute the affected Datomic log caches

[comment]: <> (TODO: Add detailed step-by-step guide)
