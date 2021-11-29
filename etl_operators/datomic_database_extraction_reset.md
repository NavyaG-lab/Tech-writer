---
owner: "#data-infra"
---

# Datomic Database Extraction Reset

This documents describes how to reset the extracted state of a database in the Analytical Environment. Typical cases when one would wish to do this are when the database in question is rebuilt in some way, whether by having it use a blank new transactor/ddb table, or by migrating its existing data to a different transactor/ddb table. As a rule of thumb, any time a migration is performed on a Datomic database which risks changing the entity ids or t values of its tuples, a full reset should be done for its data in the analytical environment to ensure continued computation of the contracts of this database.

**WARNING: PERFORMING THESE STEPS HAS HIGH POTENTIAL FOR CAUSING A CRASH. THIS SHOULD ONLY BE ATTEMPTED WHEN ABSOLUTELY NECESSARY. IF YOU DO ATTEMPT IT, BE SURE TO REFRESH CACHES FIRST SO THAT THE RUN HAS STALE DATA INSTEAD OF INCOMPLETE DATA.**

## Quick Architecture Primer

In order to understand the process, it's useful to understand, at a high level, what the different components are:

- A datomic transactor is a frontend to a Datomic database which microservices connect to. Each transactor handles persisting and retrieving state from a DynamoDB table. A given database is usually effectively split across as many transactors as there are prototypes the service operates on. Usually, we'll want to perform operations across all those transactors at once to keep the cross-shard view as consistent as possible.
- Correnteza is a service managed by Data Infra which automatically discovers new Datomic transactors, and extracts from them the logs of the underlying Datomic Database. These logs are persisted as they are with almost no transformations other than some light normalisation and annotation of the transactions being extracted. The logs are written to S3, and metadata about the database/prototype they belong to is saved in DynamoDB (in BR: `prod-correnteza-docstore`; note this table is used by all prototypes).
- Itaipu is the name of the daily batch run which takes these extracted logs as an input, and outputs materialised views of the entities for the databases. Data users at Nubank rely heavily on this type of data, and it is at the source of most of the important business sensitive processes that happen on the Data environment.
- Castor is a service which maintains caches of the materialized views of the logs. Since recomputing these materialized views from scratch each day is costly, we pre-compute the bulk of the view and save it to Castor. Then, each day, Itaipu queries both Castor and Correnteza, and merges the existing cached views with the delta of the latest extractions.

In this context, resetting the state of a Database in the analytical environment entails:

- Deleting all existing extraction metadata from the Correnteza docstore
- Invalidating the caches registered in Castor for this database, and generating new ones using the newly extracted data

## Process for resetting the state of a database

### Pre-requisites

- Using the [ITOps Scopes Form](https://nubank.atlassian.net/servicedesk/customer/portal/29), request the `correnteza-extraction-delete` and `castor-admin` scopes. These scopes have to be granted by a Data Infra approver. If you are not in Data Infra, make sure to connect with us at #squad-data-infra prior to attempting any of what's described in this document. If you are only handling a part of the process, make sure to only request the scopes you'll actually need.
- Align with Data stakeholders about the impact of the reset. For bigger databases, the impact is usually one or more runs with incomplete data. This can have important impact on downstream models and reports, and so should be, at a minimum, advertised on #data-announcements. Consider involving a Data PM if needed.

### Process

1. Pause Correnteza extractions for the database that you wish to reset. This can be achieved by adding the name of the database to the `database-blocklist` field in the config branch. Ideally, you should make sure to target the config file which most closely fits the scope of the reset. For example, if you are resetting the state only on BR, change the [`correnteza_br_config.json`](https://github.com/nubank/correnteza/blob/config/src/prod/correnteza_br_config.json) file. If only resetting a prototype, create a prototype-specific file. Also note that the blocklist expects only the unqualified name of the database (i.e. the name of the service), without prototype prefix or `-datomic` suffix.
After merging your config change, you should use the [correnteza grafana dashboard](https://prod-grafana.nubank.com.br/d/A8ULVDTmz/correnteza-datomic-extractor-service) to monitor that no further datapoints are produced for this database on the prototypes you're interested in. You can use the `basis-t & last-t` chart to watch for this.
Finally, once you're confident extractions have finished, you should run the following for each prototype:

```
nu-<country> ser curl DELETE --env prod <prototype> correnteza /api/admin/delete-attempt/<database>
```

This will ensure the `attempt-checker` component which monitors for interruptions in the extraction process, does not alert.

2. **WARNING: POINT OF NO RETURN** Trigger the `extraction-delete` endpoint on correnteza. You'll need the `correnteza-extraction-delete` scope in order to do this. Be very mindful that once you've hit the endpoint, correnteza will start deleting all extractions it has registered for the database in question. From this point on and until the whole process is finished, Itaipu will produce incomplete contract data for this database, whenever a run starts. Recovering from this state is not guaranteed if done by mistake, and so the endpoint should be used very carefully.
**NB: this step should NOT be started between 00:00 and 06:00 UTC when the run actually needs to read from those files. If the deletion is started before the contracts are done, it will crash Itaipu and make the contracts for your database completely unavailable for that day, along with any dataset that depends on them. Confirm with the Data Infra on-call engineer on #di-hausmeister that it is safe to proceed**
The command you'll need to run for each affected prototype is:

```
nu-<country> ser curl DELETE --env prod <prototype> correnteza /api/admin/extractions/<prototype>/<database>
```

Unfortunately, this part of the process has two complications:

- batch deletions from DynamoDB are slow, and the endpoint itself doesn't use an optimised strategy
- the endpoint is not resilient to failures and will sometimes stop the deletion mid-way, due to service restarts or throttling exceptions.
For this reason, this part of the process needs to be watched and monitored closely. You can use the following tools:
- Open a Splunk Search for the last 15 minutes, with the following query (adapt to the country/env/prototype you're performing the operation on):

```
source=correnteza ":correnteza.document-store.extraction/delete-extraction!" | search prototype=global
```

This will allow you to watch the deletions progressing. The `latest-t` field on the log lines will progressively descend towards 0.

- Open the [`prod-correnteza-docstore`](https://sa-east-1.console.aws.amazon.com/dynamodb/home?region=sa-east-1#tables:selected=prod-correnteza-docstore;tab=items) table on DynamoDB, and using the `search` function, look for entries corresponding to your transactor. For example, if deleting `metapod` in `global`, you'd want to search for segments with `db-prototype=metapod-global`.
Using the two tools above, the deletion for a given prototype is considered complete if a) Splunk doesn't record any further deletions when the endpoint is triggered b) a search for segments corresponding to your transactor yields no results in DynamoDB.
If the deletion stops, but there are still segments, you should trigger the endpoint again for the prototype in question, and keep monitoring until the final state described above is reached.
When you've validated that there are no more segments registered for your transactor in Correnteza, you can proceed to the next step

3. Restart extraction of your transactors. For this, you can go back to the config branch of correnteza and remove the databases from the blocklists. **NB**: be mindful of the behaviour of the config branch; if you blocked the database by creating a dedicated config file (usually for a specific prototype), you'll need to make the file an empty JSON; deleting the file will NOT unblock the databse as the config pipeline will leave the previous one as is due to having nothing to replace it with.
After merging and deploying, you can confirm that extractions have resumed via the [correnteza grafana dashboard](https://prod-grafana.nubank.com.br/d/A8ULVDTmz/correnteza-datomic-extractor-service) or Splunk.
Correnteza will take some time to catch up back to the latest state. This can lead to the data being incomplete into the next run. Ensure proper communication with Data stakeholders if this is a risk.

4. Trigger a cache refresh: first, invalidate the existing cache using the endpoint on castor (requires the `castor-admin` scope):

```
nu-<country> ser curl POST --env prod global castor /api/invalidations --data "{\"database\": \"<database>\", \"prototype\": \"<prototype>\", \"country\": \"COUNTRY\"}"
```

Note that the country parameter has to be in _upper case_.
Then, you'll need to trigger the `pollux-invalidated` DAG in the appropriate Airflow. For BR, go to the [DAGs page](https://airflow.nubank.com.br/admin/) and click the play button on the `pollux-invalidated` line. **NB: this step should NOT be started between 00:00 and 06:00 UTC as changing the caches mid-contracts-phase can lead to inconsistent contract data. Confirm with the Data Infra on-call engineer on #di-hausmeister that it is safe to proceed**. The cache refresh can take anywhere between a few minutes to a few hours depending on the size of the database.
