---
owner: "#data-infra"
---

# PII monitoring datasets alert playbook

## Context

### Is immediate action required?

First the good news: None of the alerts listed below require immediate action!
There are no time-critical actions that need to be taken. Everything is
idempotent. So reacting to any of the alerts is something that can be done
during the workday when other critical alerts have been sorted out and we are
sure the main run is stable. Then, it is a good idea to investigate what caused
the monitoring datasets to alert. In the short history of alerts in this
domain, none of the alerts actually pointed to something being broken. Still,
it is necessary to double-check. Otherwise we might fail to comply with LGPD
which is a potential big risk for nubank as a whole.

To be able to investigate the failures,
[this](https://github.com/nubank/itaipu/blob/15675780432f7cb73cf82290c6348c46a82b37f9/common-etl/src/main/scala/nu/data/infra/api/pii_data_deletion/package_doc.md)
might help to give you a good understanding of how the system works.

### How are the alerts generated

The alerts are collected in a dataset. Each alert is one row of the data. We
use the mergulho row-count related alerts to alert each time a new row enters
the datasets.

NOTE: That means that old alerts stay around in those datasets.  Don't be
overwhelmed by thousands of old alerts. Just query the data to get the newest
alerts and check those out.


## Timing dataset fires

### What it means

The timing monitoring checks the amount of time it took from Malzahar marking
an excision in one of our production databases to the time when correnteza
re-extracts the corresponding log segment. This latter point is the point which
we define as 'Data infra deleted the data from the ETL'. Currently, this
duration can be maximally 48 hours long. If this time span is exceeded, the
timing monitoring dataset will have a new line which lists the corresponding
laggard.

### What to do

1. Check the dataset:

```sql
SELECT *
FROM `nu-br-data.dataset.monitor_datomic_reextractions_timing`
ORDER BY reextracted_at desc
LIMIT 10000
```

2. Potential quick fix: Check if there is a corresponding alert in the
   [duplication dataset](#duplication-dataset-fires). If so, check when the
   first of the duplicated extractions happened. If that one is on time, the
   problem lies elsewhere (most likely with the
   [caches](#datomic-caches-not-updated).
3. The data was extracted eventually, so the flow itself is working. The most
   probable cause why it is late is the serving layer. Work your way backwards
   through the flow:
   1. Check the `correnteza-reextractions` dataset series for the related
      entries and see if all makes sense.
   2. Check the `datomic-reextract-serve-data` dataset with databricks and the
      `datomic-reextract-base`
3. Else: Escalate


## Duplication dataset fires

### What it means

If a reextraction happens multiple (n) times, it means that the first n-1 times
it was not effectful. The most likely problem are - once again - the
[caches](#datomic-caches-not-updated).

### What to do

1. Check the monitoring dataset itself. It requires unnesting of a bigquery
   array to be done efficiently, so here is the query:

```sql
SELECT join_id, `count`, reextracted_at
  , coalesce(current_base.database, archive_base.database) database
  , coalesce(current_base.prototype, archive_base.prototype) prototype
FROM `nu-br-data.dataset.monitor_datomic_reextractions_duplication`
, unnest(archive_dates) as reextracted_at
LEFT JOIN `nu-br-data.dataset.datomic_reextract_base` current_base
  USING (join_id)
LEFT JOIN `nu-br-data.series_contract.dataset_datomic_reextract_join_history` archive_base
  USING (join_id)
ORDER BY join_id, reextracted_at desc
LIMIT 10000
```

  This will give you the timing of the duplicated reextractions and database
  and prototype.

2. Check when the last caches were updated for the respective database and
   prototype. If it wasn't updated, raise with whoever owns pollux to see if:
   1. As a quick fix we can update the cache now.
   2. As a long term fix, see if it is feasible to update the caches each day.

3. Else: Escalate


## Completeness dataset fires

NOTE: The completeness alerts dataset (BR) always contains 944 rows from an excision
that was made before we had monitoring. This is expected and fine. Nothing to
worry about. Any number above that is reason for concern.

### What it means

There is data that malzahar excised but that was never extracted by us and
cannot be found in our databases at all. In theory, it means that the PII data
isn't in the ETL, so problem solved... But in practice, that probably means
that something about the entire system is broken. An issue we had was that [new
databases are excised](#new-databases-are-excised-from) from. If that's not the
problem, it means we need a thorough investigation what's up.

### What to do

1. Check the dataset with the following query:

```sql
SELECT *
FROM `nu-br-data.dataset.monitor_datomic_reextractions_completeness`
ORDER BY excised_at DESC
LIMIT 10000
```

1. Check the `database` column to see if contracts for all the databases are
   declared as inputs to the `DatomicReextractions` sparkop of that country. If
   that's the case, see [here](#new-databases-are-excised-from).
1. If that's not the problem, check the malzahar contracts for the entities that cannot be reextracted.
2. Try to find those entities 'manually' by running sql queries on the
   contracts or raw logs.
   1. If you can find them, maybe the sparkOp logic to find them automatically
      needs an update.
   2. If you cannot find them, escalate


## Failures we had in the past (which might be recurring)

### Datomic caches not updated

Leads to: Duplication alerts (also timing alerts later)

Recent [example](https://nubank.slack.com/archives/CGBLGLYFK/p1605270266152200)

If correnteza reextracts a log segment, it doesn't mean that it is going to be
used in successive runs. Most older log-segments are combined into one
larger cache of the entire history to speed up processing. A reextracted log
segment needs to enter this cache by recomputing it. Most caches are not
recomputed each day but at longer intervals. The PII relevant databases are
recomputed every day right now. But sometimes the timing isn't working out with
deletions and starting the next run. Hence, the following will happen:

1. On day x we find data in the run to be reextracted. We serve that data to
   correnteza and the reextraction proceeds successfully. However, the cache
   isn't updated.
2. On day x+1, the reextracted log segment doesn't contain the PII data
   anymore. But the cache still does. So it is found in the data again during
   the run and a second duplication runs. We will get a duplication alert.
3. (If - due to some other reason than bad timing - the cache isn't updated
   another day, we will get one more duplication alert, but also a timing alert
   since the third reextraction seems to be 'late'. This timing alert is then
   of no relevance of course since the problem lies elsewhere.)

### New databases are excised from

Lead to: Completeness alerts

Our reextract-op defines the datomic contracts of the databases that excisions
happen on as its' inputs. If we didn't do this explicitly, we'd have to mark
all contracts as inputs which isn't necessary and constrains when the
reextract-op can run too much. Every once in a while, new databases are added
to be excised from. In such cases, we won't find the data that malzahar marked
as excised because we don't join against the contracts from those new
databases yet. If you then inspect the `database` column in the completeness
monitoring table and find any databases that aren't listed as dependencies of
that countrie's `DatomicReextractions` sparkop, then that is the reason we
couldn't find the data. The solution is then to add the respective contracts as
inputs to the reextract-op.
