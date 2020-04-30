# Datomic Raw Cache #

The datasets making up the materialized views of entities from the Datomic databases are called the Datomic Contracts. 
The pipeline for creating the Datomic Contracts includes several intermediary datasets, the first two being the Raw 
Log and Raw Materialized Entities datasets.

The Raw Log `nu-br/raw/$dbName-prototype/log` is computed out of the batches of datoms extracted from all the Datomic 
databases by Correnteza. The batches are called Correnteza Extractions and they’re queryable for each (country, 
prototype, db name) since a given time value of `t` from a DynamoDB table that Correnteza writes Extractions to.

The Raw Materialized Entities `nu-br/raw/$dbName-$prototype/materialized-entities`is computed directly out of the Raw
Log.

Given the incremental nature of these two datasets, they are snapshotted frequently and used as starting points 
by Itaipu in the daily runs of the Datomic Contracts instead of building these dataset from scratch.

The first iteration of the snapshotting system relied on manually copying those two datasets from a successful Metapod
Transaction to a permanent S3 bucket where these cache datasets are stored. Metadata about the cached datasets are 
stored in [a JSON file](https://github.com/nubank/itaipu/blob/master/common-etl/src/main/resources/log_cache_map.json)
in the source code of Itaipu.

Updating the cache snapshots manually was a labor-intensive operation, so a more automated self-contained system was
created to manage this process.

The new system relies on a service - called [Castor](https://github.com/nubank/castor) - that stores the metadata about
the cache snapshots dynamically, and a CLI called 
[Pollux](https://github.com/nubank/itaipu/tree/master/src/main/scala/nu/data/infra/pollux) which contains all the 
necessary logic to create new cache snapshots and submits them to Castor.

During the roll-out of the new system, the older system is still in place but no more effort is going into using it to
update the cache snapshots. The old JSON file is still in Itaipu and is relied-upon as a fallback when Itaipu fails to
communicate with Castor to fetch the latest cache information. Castor currently exposes a facility for downloading its 
entire state of cache snapshot metadata to the same JSON format accepted by Itaipu called "Static Cache", so it is 
possible to periodically update the fallback static cache in Itaipu.

## Components of the System ##

### Castor ###
A Clojure service, backed by Datomic for persistence. It owns instances of cache snapshots called `Snapshot`s and the
business logic for manipulating them. It exposes 
[HTTP API](https://github.com/nubank/castor/blob/master/src/castor/service.clj) that facilitates manipulating 
individual `Snapshot` instances, as well as performing administrative tasks.

A `Snapshot` instance is made up of a point in time `t` in the same format used by Datomic, and the paths to the
datasets comprising the snapshot.

An Active Snapshot is the most recent Snapshot stored in the system for a particular (country, prototype, and database
name).

While Itaipu is building the intermediary datasets for a Datomic contract, it queries Castor for the Active Snapshot for
each database instance it's building the contract for.

### Pollux ###
A CLI in Itaipu. It re-uses the same logic for building the Raw Cache datasets from the daily runs in order to build
fresh cache snapshots that Itaipu can use later to speed up its Datomic Contract runs.

The main logic the same as that from the daily run, except that it builds each dataset twice, and asserts their
equivalence before moving forward with using one of each pair for newly created cache snapshots. This is done to
minimize the risk of transient errors in the cache snapshots, since they would be used for longer periods of time and
errors would propagate very far in that time frame.

The Pollux CLI exposes two modes of operation:

**Manual**
Given a database name, Pollux would create fresh cache snapshots for each database instance for that name and submit 
them to Castor.

**Auto**
Pollux would send information about all the statically-defined Datomic Contracts in Itaipu to Castor, and Castor 
would consult its database and its configuration parameters and decide on which databases instances should have new 
cache snapshots created for them. Pollux would use this information and create new cache snapshots for the exact 
database instances and submit them to Castor.


## The Moving Parts ##

### Due-database Selection ##

Pollux Auto runs on Aurora daily to run the due-databases selected for it by Castor. This is triggered by an 
[Airflow job](.https://github.com/nubank/aurora-jobs/blob/master/airflow/pollux_auto.py).

Castor's due-database selection logic is controlled by:
  1. how old the active cache for each database instance in Castor is
  2. what is the expected maximum age for the active snapshot of each database as determined by its configuration 
     parameters
  3. what is the maximum number of database instances allowed in a single Pollux Auto run as determined by a
     configuration parameter

### Handling of Orphaned Datasets ###
Castor contains the logic of scanning its own S3 buckets for datasets partitions that are not owned by any of 
its cache snapshots. There's an HTTP endpoint that triggers this logic, and it's set-up to be 
[triggered periodically](https://github.com/nubank/definition/blob/master/resources/br/tasks/castor-delete-orphaned-datasets.edn).


The orphaned dataset partition deletion logic is set-up to be automatically followed by an integrity checker that
asserts that the datasets from each Snapshot exist on their respective bucket. Once a Snapshot is found to have a
dangling reference to non-existing dataset, it is considered a corrupted Snapshot and is promptly deleted. This
effectively promotes the second-to-most recent Snapshot to become the new active Snapshot.

## FAQ ##

### Corrupted/missing dataset from a Snapshot, how to recover from it? ###
You can ommit the CLI flag `--use-cache` from Itaipu in order to prevent it form making use of the problematic dataset
at the cost of taking the extra time to run the datasets from scratch.

### How can I run Itaipu without Castor integration? ###
There's a global `--disable-castor` CLI flag that disables communication with Castor entirely. Bear in mind that this
wouldn't uncommit/retract any Datomic Raw datasets that have been pre-committed to a Metapod Transaction.

## Alert Playbook ##

### Itaipu <-> Castor failure ###
Itaipu failed to communicate with Castor while fetching information about the active snapshots. It should be a benign 
alert, since Itaipu should use its own static cache as a fall back, but bear in mind that if this alert was raised 
by an Itaipu job running Datomic Contracts and the static cache is fairly old then this run might take longer than 
usual.

Please notify Data Infra (Runtime Pack) for investigation.

### Pollux Auto hasn't ran or finished running today yet ###
Either Pollux Auto hasn't run today or it has run but hasn't finished yet. You should check on the `pollux-auto` job 
on Aurora to distinguish between the two cases.

In the first case it means there's a problem with the system. Notifying Data Infra (Runtime Pack) should be sufficient.

In the second case, it might cause problems with the daily ETL run, as there have been reported instances of failing to
allocate EC2 instances when this is the case. If you notice problems with the ETL run, then killing the long-running 
pollux-auto job might be necessary.

### Castor (Orphaned Dataset Partitions) ###
An orphaned dataset partition has been detected and deleted. Not necessarily actionable but good to be aware of in case
other suspicious problems arise.

### Castor (Corrupted Snapshot) ### 
A corrupted Snapshot has been detected and deleted. Not necessarily actionable but good to be aware of in case other
suspicious problems arise.

