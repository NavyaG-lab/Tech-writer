# Cookbook

## What this book covers

This playbook shows you how to set up data infra related parts of personally
identifiable information (PII) deletion from datomic databases. This includes
the mechanism to remove such information from the ETL as well as monitoring for
the removal process.

More specifically, it lists what you have to do in order to set this up for a
new country.

## Context: How datomic deletion works (in a nutshell)

First and foremost: Data infra does not delete PII data. Data protection has a
service called _Malzahar_ that creates excision requests for the datomic
databases. Once the excisions are performed on the production databases they
are not reflected in the ETL though. This is because in going with the normal
rationale of datomic where the database only ever grows and nothing is ever
lost, we already extracted the past of the database as logs and only extract
newer parts under normal circumstances. Until we re-extract the old logs after
the excisions have happened, the data will still be in the etl. Hence data
infra's part in the deletion is about _re-extraction_ in the case of datomic
databases.

Here is the flow:

* Malzahar does the excision requests
* Malzahar contracts give us information of what was scheduled for excision in
    which database and when
* We combine this information with our raw database logs which are used to
    create datomic contracts. As the deleted entities are still in those logs,
    the join with the malzahar contracts succeeds.
* We take the datomic `t` values from that join and send them to correnteza
    (our log extractor service). Correnteza figures out what needs to be
    reextracted and performs the reextractions.
* We update our log caches that merge older logs into larger parts and compute
    a recent snapshot of the database against which only new changes are
    computed each day.
* We get monitoring information about the entire process as described below.


## Getting ready

This playbook assumes that:

* The malzahar service already exists in your country and that its contracts
    are available
* You are comfortable with the process of contributing to itaipu: Adding a
    sparkOp and dataset series (DSS) contracts

Glossary of what needs to be known:

1. _Malzahar_: Data Protection Service that performs the excisions (datomic
   deletion) on the production databases.
2. _Correnteza_: Data Infra service that (re-)extracts datomic logs from the
   production databases.
3. _JoinOp_: Op that joins Malzahar contracts to our datomic raw logs to find
   which logs contain data that is supposed to be deleted and hence need to be
   reextracted. This op is archived to retain a history of what was found to be
   reextracted in the past.
4. _ServingOp_: Aggregation of the JoinOp that is sent to correnteza so that it
   can figure out which log parts to reextract.
5. _ReextractionDSS_: Dataset series about when correnteza reextracted what log
   parts and based on what serving layer information.
6. _MonitoringOps_: Ops that combine info from the JoinOp, the JoinOpArchive,
   the ReextractionDSS and Malzahar contracts to see if everything is working
   as expected.


## How to do it

Note: You can do all of these steps within a single PR. If you want to split it
into multiple smaller steps, you can do the last step separately. But the first
three steps need to be executed in the same PR, otherwise tests will fail.

### 1. Create the JoinOp

The op needs to know its country and a quality assessment, nothing more of the
normal attributes as they are all set in the abstraction.

Then the main task is to get the malzahar contract names and the raw logs of
the db's you are looking for. Here is a minimal example of the op that is
needed for `mx`:

```scala
object DatomicReextractions extends DatomicReextractOp {

  override def country: Country                     = Country.MX
  override def qualityAssessment: QualityAssessment = QualityAssessment.Neutral(asOf = LocalDate.parse("2020-08-26"))

  override lazy val exciseRequestsName: String = DatabaseContractOps.lookup(ExciseRequests).name
  override lazy val exciseFieldsName: String   = DatabaseContractOps.lookup(ExciseFields).name
  override lazy val exciseEntitiesName: String = DatabaseContractOps.lookup(ExciseEntities).name
  override lazy val rawDbs: Set[String] = Seq(Acquisition, Customers, KarmaPolice, BureauMX)
    .map(DatabaseContract.fromV1)
    .map(RawDatabase.fromDatabaseContract)
    .flatMap(_.effectiveShards)
    .map(Naming.datomicRawLog)
    .toSet
}
```

Don't forget to add your op to the package file: Unlike normally, this time you
add it to an attribute called `pii_deletion_datasets` instead of `all`:

```scala
def pii_deletion_datasets: Seq[DatomicReextractOp] = Seq.empty[DatomicReextractOp]
// currently still empty
```

For a new country, this attribute still needs to be created.

### 2. Add DSS for JoinOpArchive

Next we need to add a DSS contract for the archive we are creating in the step
above.

To add an archive DSS you can use the automated archive creation tool _Squish_.
All you need to do is go to the [archive package file](https://github.com/nubank/itaipu/blob/0c0a4758f087932d131e9069fb11c9f4570d1b8b/src/main/scala/nu/data/br/dataset_series/archived/package.scala)
for your country (example is from `br`) and add this entry to the
`archivedDatasetSeries` list:

```scala
SparkOpToSeries(DatomicReextractions)
```

That's it. Squish will do the rest.

### 3. Add ReextractionDSS

This step creates a dataset series contract for the data that correnteza
ingests about the reextractions it performs. This one you need to add
completely by hand for now. The goal is to automate it in the future.

TODO: update the link here after PR merge!!!!!!!!!!!!!!!!!!!!!!!
Luckily, you can take the
[contract](https://github.com/nubank/itaipu/blob/a88e98273fb03b385575fa507ec79925a4d5ca2c/src/main/scala/nu/data/br/dataset_series/CorrentezaReextractions.scala)
from `br` and adjust it to your needs:
TODO: update the link here after PR merge!!!!!!!!!!!!!!!!!!!!!!!

1. Put it in the correct folder and change the package declaration accordingly
2. Change the `country` attribute
3. Again, don't forget to add it to the package file

### 4. Add mergulho anomalyChecks

This step can be done in a separate PR but you can also put it into the same
PR. Look for the
[DatasetSelector](https://github.com/nubank/itaipu/blob/69c98a87a082002497749f4b1346516222497bb8/common-etl/src/main/scala/common_etl/evaluator/steps/mergulho/DatasetSelector.scala#L35)
class of Mergulho. In the end you will find a `DefaultAllowList` where you can
add your dataset and the check you want to run. In this case, it should be the
`RowCountEqualTODO` check. Add the three monitoring sparkOps to the list. You
should find the examples from `br` in there already.

In a future step we want to automate this as well, but getting the names in
here automatically isn't trivial for now.


## How it works

The first sparkOp you add in step 1 above is used in our `ManagedOps` section
to create 4 more sparkOps: The ServingOp as well as the MonitoringOps. Ideally,
this op would also create the two DSS that are needed but this is an avenue
for future improvements as it needs some additional wiring in our managedOps
system. Since the MonitoringOps depend on the DSS's, any PR that just does step
1 will fail integration tests.

The monitoringOps are set up in a way that they only contain rows for
errors/concerning information. We use mergulho row counts to check whether new
lines are available since yesterday and alert in our `#integrity-checks` slack
channel in such cases.

## There's more

Here is a picture about the relation between the tables and their columns:

![EntityRelationshipDiagram](DatomicDeletionERD.png)

Legend:
* C: contract (also DSS contract)
* R: raw table
* I: internal table, never materialized. Here to make the flow of data more
    clear
* D: dataset
* A: archive
* Green circles: Primary keys. Red squares are what makes up the primary keys

## See also

[RFC for the monitoring system](https://honey.is/home/#post/865523)
