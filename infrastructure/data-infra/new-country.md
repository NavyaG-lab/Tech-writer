---
owner: "#data-infra"
---

# Deployment of data infrastructure in a new country

This document describes the steps required to deploy all components of the current
data infrastructure in a new country.

## Glossary

The following parameters are used through this document:
  * `country`: the country where the data platform is being deployed
  * `env`: the used environment. Normally `staging` or `prod`.
  * `prototype`: logical groups of services that have similar security/deployment requirements. For instance, `global`, or shards (`s0` ... `s14`). Normally, new countries only have `global` and `s0`.


## Permissions requirements

The following AWS IAM groups are required to spin services on the new country AWS account:

- `infra-ops`
- `prod-eng`
- `data-infra`

In addition to the above, the following scopes are also needed:

- `admin`
- `data-infra-admin`

**NOTE***
  * Specific services may require special scopes such as `barragem-admin` or `ouroboros-admin`.

We assume throughout this document that you have the correct AWS IAM groups, scopes and
have setup your AWS role-based authentication locally. For more information, see [multi-country-setup](./multi_country_setup.md).

## Understanding current ETL infrastructure

The ETL infrastructure for countries other than `BR` is deployed on the **DATA** account.
This document briefly explains the ETL infrastructure and its main components.

### Aurora

[Aurora (aurora-scheduler)](https://github.com/nubank/data-platform-docs/blob/master/infrastructure/data-infra/guide-to-the-runtime-environment.md#aurora-overview) a resource manager that schedules and run jobs across a Mesos cluster. It provides access to the Aurora Scheduler UI.

`aurora-scheduler` on the Data account is currently available at [https://prod-foz-aurora-scheduler.nubank.world/](https://prod-foz-aurora-scheduler.nubank.world/scheduler/jobs/)

### Mesos
[Mesos (mesos-master)](https://github.com/nubank/data-platform-docs/blob/master/infrastructure/data-infra/guide-to-the-runtime-environment.md#mesos-overview) a cluster manager that provides access to the Mesos UI and allows you to see lower-level details of the jobs.
It is usually recommended to interface directly with Aurora whenever possible.

`mesos-master` on the Data account is currently accessible at [https://prod-foz-mesos-master.nubank.world/](https://prod-foz-mesos-master.nubank.world/)

### Airflow

[Airflow](https://github.com/nubank/data-platform-docs/blob/master/infrastructure/data-infra/guide-to-the-runtime-environment.md#airflow-overview) on the **DATA** account is accessible at [https://airflow.nubank.world/admin/](https://airflow.nubank.world/admin/)

#### DAGs

`daguito` is a DAG that allows you to schedule, monitor and manage the daily ETL run on the data account, which currently includes the datasets from Mexico and Colombia.

Other DAGs also run in the data account, such as the DAG that sends progress announcements to slack.
Here is an [example of moving a DAG to run on the data account](https://github.com/nubank/aurora-jobs/pull/1125).

**NOTES**:
  * The mesos-master and aurora-scheduler are already isolated on the **DATA** account, and have distinct DNS addresses. Therefore, you don't need to specify the port in their URLs.
  * In Brazil, though the mesos-master and aurora-scheduler are running in isolated instances, but for the time being, you still need to specify the port.```

## Preparing S3 buckets

The creation of the buckets is partially automated, but the automation process is ongoing. Currently, this section outlines only the key requirements. For additional details,
reach out to [DI Infrastructure team](https://nubank.slack.com/archives/C018FC60SQ1).

Here’s the list of S3 buckets:

| Account     | Name                                                     | Region                     |
|:------------|:---------------------------------------------------------|:---------------------------|
| `<country>` | `nu-ds-<country>`                                        | `us-east-1`                |
| `<country>` | `nu-spark-dataset-series-<country>-<env>`                | `nu-data-<env>` equivalent |
| `<country>` | `nu-spark-datomic-logs-<country>-<env>`                  | `nu-data-<env>` equivalent |
| `nu-data`   | `nu-spark-metapod-ephemeral{clearance-<country>-<env>`   | `nu-data-<env>` equivalent |
| `<country>` | `nu-spark-metapod-manual-dataset-series-<country>-<env>` | `nu-data-<env>` equivalent |
| `nu-data`   | `nu-spark-metapod-permanent{clearance-<country>-<env>`   | `nu-data-<env>` equivalent |
| `nu-data`   | `nu-spark-static-<country>-<env>`                        | `nu-data-<env>` equivalent |
| `<country>` | `nu-tmp-<country>`                                       | `us-east-1`                |
| `<country>` | `nu-ds-<country>-artifacts-realtime`                     | `us-east-1`                |
| `<country>` | `nu-ds-<country>-artifacts-batch`                        | `us-east-1`                |
| `<country>` | `nu-ds-kubeflow-<country>`                               | `us-east-1`                |
| `<country>` | `nu-spark-devel-<country>`                               | `us-east-1`                |
| `<country>` | `nu-ouroboros-partition-pointers-<country>`              | `us-east-1`                |
| `nu-data`   | `nu-spark-tmp-raw-<country>-<env>`                       | `nu-data-<env>` equivalent |

**NOTE***
  * `data-<env>` equivalent states that the bucket should be created
    in the same region buckets under the `nu-data` account for that
    environment: `us-east-1` for `prod` and `us-west-2` for `staging`.

Currently, the following Access control list (ACLs) are applied:

```
{
    'BlockPublicAcls': True,
    'IgnorePublicAcls': True,
    'BlockPublicPolicy': True,
    'RestrictPublicBuckets': False
}
```

**NOTE**
  * We block everything except public buckets because we need to access them across different accounts.

Policies that are to be associated with any given bucket are defined in
[iam-policies](https://github.com/nubank/iam-policies) and they are
still a copy/paste affair at the moment. Roughly speaking, you have
to find the policy associated with the corresponding bucket in another
country and create appropriate “variation” of it. Once this is
done, merge your policies in the `iam-policies` repository, and
then apply them with:

```{.shell}
nu-<data or country> serverless invoke iam-policies-put-bucket-policy \
    --account-alias $country \
    --env prod \
    --invoke-type sync \
    --payload "{\"bucket\":\"<bucket-name>\"}"
```

**NOTE**
  * `"data" or <country>` provided the correct one based on where the bucket is defined.

## Preparing Services

1. The first task in order to prepare any data service to be deployed in a new
country, is to modify the list of countries in the
[common-etl-spec](https://github.com/nubank/common-etl-spec) project as
:

``` {.clojure}
(def country #{:metapod.dataset.country/br
               :metapod.dataset.country/mx
               :metapod.dataset.country/co
               :metapod.dataset.country/data})
```

You can find the list of countries at this
[file](https://github.com/nubank/common-etl-spec/blob/c5918614abf6d11abf85772356c00d662f390a52/src/metapod/dataset.clj#L35-L38).

2. After adding the new country, bump this project to a new version.

All services that are to be deployed in the new country must be compatible with
the newly provided version of **common-etl-spec**.

**NOTE:**
  * You will notice on the **sachem** tests, which are the services where this
  dependency needs to be bumped due to this modification.

## Preparing Itaipu

In the ETL world, for the ETL jobs to be compliant with the new country, you'll need to prepare [Itaipu](https://github.com/nubank/itaipu) as well.
prepared in order for the ETL jobs to compliant with the new country. To get started,
you'll need to bump the following libraries to a version that supports the new
country (check on their _CHANGELOG_):

- [common-finance](https://github.com/nubank/common-finance)
- [common-i18n](https://github.com/nubank/common-i18n) (Must match with the version used by `common-finance`)
- [common-etl-spec](https://github.com/nubank/common-etl-spec) (Must match with the version bumped on the step above)

Make sure all tests current are passing when you bump those libraries. Additionally,
try to execute jobs that depend on the `common-finance` library in order to double-check
that everything is still working. One example of those jobs is `dataset/credit-card-financeira-ledger`
which can be launched as follows:

```{.shell}
nu datainfra sabesp -- --aurora-stack=staging-foz jobs itaipu staging nu-finance-bump-test s3a://nu-spark-metapod-ephemeral-1 s3a://nu-spark-metapod-ephemeral-1 15 --itaipu=$YOUR_ITAIPU_VERSION --scale=$SCALE_VERSION --filter dataset/credit-card-financeira-ledger
```

The second step on the `Itaipu` preparation to support a new country, is to create
all the correspondent packages to host contracts, datasets and other entities to be
used in this specific country. Additionally, these packages need to be bound together on the
[Itaipu.scala](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/itaipu/Itaipu.scala) file.

This [PR](https://github.com/nubank/itaipu/pull/14191/files) illustrates which packages
need to be created and which pattern matches need to be adapted in order to include
the case for the new country. Note that, at this point, no connection to external
services (e.g _Correnteza_ or _Ouroboros_) can be created since they are not yet
deployed for the new country infrastructure.

## Preparing Core Services

In order to spin the necessary services for deploying our data infrastructure in
a new country, we will use the [nimbus](https://github.com/nubank/nimbus) project.
From there, it is pretty easy to create data stores or Kubernetes pods, necessary
to host services instances.

In order to start a _Nimbus_ console to launch the data infrastructure deployments
using the target country environment, please run the following command on the _Nimbus_
project root folder:

```{.shell}
./nimbus-deploy/bin/console $env-$country  # Where ENV in (staging|prod)
```

Example:

```{.shell}
./nimbus-deploy/bin/console staging-co  # Starts nimbus console for the staging environment in CO country
```

Note that upon its start, this console will download current definitions for each
service from __s3_. If you want to use local definitions, please refer to _Nimbus_
[documentation](https://github.com/nubank/nimbus/tree/master/nimbus-deploy#using-local-definitions).

Another thing which is important to mention: **please disable any kind of alerts while your service is not yet healthy!!!**
This will avoid disturbing the rest of the team during the deployment phase. Remember to
put them back whenever the deployment is considered done.

### Spin Veiga

_Veiga_ will be needed to route messages from the **DATA** _Metapod_ instance to the
services on the new country. In order to deploy it, please copy and adapt the following
definition for the new country:

- [Service](https://github.com/nubank/definition/blob/master/resources/co/services/veiga.edn)

After creating the new definition, launch the following commands on the **staging**
_Nimbus_ console to spin the service on the `:global` prototype only since _Veiga_
is not sharded:

```{.clojure}
(app/create! :global "blue" :veiga "<image-version-as-string>")
```

You can list the last image version using the ```nu registry list-images nu-veiga```
command.

Once those pods are successfully created, you will need to upsert DNS aliases for
this service in the new country. You can do it by using the following command:

```{.shell}
nu serverless invoke update-canonical-dns --invoke-type sync --account-alias $country --env staging --payload '{"prototype":"global","stack-id":"blue","service":"veiga"}'
```

After running the command above, check if the new service is healthy by running the
following command:

```{.shell}
nu-$country ser curl get global veiga /api/version --env staging
```

If this deployment runs correctly on **staging**, repeat this operation using the
**prod** environment.


### Metapod modifications

There is no need to install __Metapod_ since the one on the **DATA** account will be
used and it is already prepared to do cross-country requests. However, some modifications in its
definition are required.

#### Checking Blueprint interaction

__Metapod_ fetches a list of accessible endpoints from its bookmarks
from the __Blueprint_ service at initialization time. After the
required modifications on the __Metapod_ definition and knowing you
have __Veiga_ up and running in the new country, please check if the
URLs declared on the `services` list on the __Metapod_ initialization
logs. You should find an entry correspondent to this specific instance
of __Veiga_. An example for __Veiga_ in **MX** would be:

```{.json}
    NU_ENV_CONFIG: {
        ...
        "services" : {
            ...
            "veiga-mx" : "https://staging-global-veiga.nu.com.mx/api",
        }
    }
```

#### Updating metapod contracts

On the Metapod root folder, please run the following command in order to
update the contracts with the modifications related to the new country:

``` {.shell}
lein gen-contracts data
```

Those contracts also need to be copied to the correspondent contracts
packages on Itaipu in order to reflect the modifications on the service.

### Testing with a Dataset

In order to test if the communication between __Metapod_ (which lives
in the **DATA** account) and __Veiga_ (which is in the new country), we
would need to commit one dataset on __Metapod_ and check out if it was
propagated in a Kafka topic (**DATASET-COMMITED**) in the new country.
There are different ways to do it but in order to approach ourselves to
a real case scenario, we would need to launch a job which will
commit a dummy dataset.

An adapted copy of `nu-co/dataset/dimension/date` could be a good test since
this dataset is small and it doesn't have any upstream dependencies. We
would then launch a job on the **DATA** account containing your new
country-specific dataset using the following command:

``` {.shell}
nu-data datainfra sabesp -- --aurora-stack=staging-foz jobs itaipu staging new-country-metapod-test s3a://nu-spark-metapod-ephemeral-1 s3a://nu-spark-metapod-ephemeral-1 1 --itaipu=$YOUR_ITAIPU_VERSION --scale=$SCALE_VERSION --transaction-type hotfix --filter-by-prefix=nu-$country/dataset/date
```

Few things to note in this command:

- The staging on the DATA country should be used for this kind of test.
- On manual runs, the transaction type must be set as __"hotfix"__ in
order for Itaipu to propagate the dataset commit message to Metapod.
- You must build the Itaipu version containing your test dataset,
publish as a dev image, and set its version on this command (just
replace __YOUR_ITAIPU_VERSION_). You can use the **scale** version from
the current run.

If this job finishes successfully, we must check on the logs to see if
__Metapod_ indeed propagated the commit event to __Veiga_ on the new
country (since this is an asynchronous action and the job status does
not takes this operation into account). The easiest way to check if this
event was propagated, is to find out the correspondent dataset commit
message on __Metapod_ and then follow its **cid** to check the messages
on __Veiga_. In Splunk, this can be done with the following queries:

```
    index=staging-data source=metapod <dataset-name>
```

After grabbing the **cid** in the body of this event, you can follow up
it in __Veiga_ by doing so:

```
    index=staging-<country> source=veiga cid=<cid>
```

Check in the messages that there are no exceptions and that __Veiga_
correctly handled the commit event.

## Contracts

In order to prepare contracts for the new country, we will need to spin the main
service responsible for ingesting those contracts on the data lake (_Correnteza_)
and adapt _Itaipu_ to talk with this new service. Finally, we are going to test it
by adding infra owned contracts to _Itaipu_.

### Spin Correnteza

_Correnteza_ is a critical service to our data platform since it deals with the
deployment of Datomic logs on our S3 buckets over time. In order to do that,
_Correnteza_ stores the `last-t` (time of currently processed extraction for a
given Datomic log) on a __DynamoDB_, to keep track of its progress when extracting
those logs. For Colombia, we then defined the following configurations for _Correnteza_
service and its data storage:

- [Service](https://github.com/nubank/definition/blob/master/resources/co/services/correnteza.edn)
- [Data storage](https://github.com/nubank/definition/blob/master/resources/co/dynamodbs/correnteza.edn)

Knowing that this datastore is required to exist prior to starting the service, we
will need to create it first, using the following command on the **staging** _Nimbus_ console:

```{.clojure}
(doseq [prototype ["global" "s0"]] ; use more prototypes if needed
    (dynamodb/create-table! (keyword prototype) "correnteza"))
```

```{.clojure}
(doseq [prototype ["global" "s0"]] ; use more prototypes if needed
    (dynamodb/create-table! (keyword prototype) "correnteza-datomic-extraction-attempts"))
```

If the commands above finished successfully, you can try to spin the service, on all
available prototypes (_s0_, _s1_ ... + __global_), using the given command:

```{.clojure}
(doseq [prototype ["global" "s0"]] ; use more prototypes if needed
  (app/create! (keyword prototype) "blue" :correnteza "<image-version-as-string>"))
```

You can list the last image version using the ```nu registry list-images nu-correnteza```
command.

Once those pods are successfully created, you will need to upsert DNS aliases for
this service on the new country. You can do it by using the following command:

```{.shell}
nu serverless invoke update-canonical-dns --invoke-type sync --account-alias <country> --env staging --payload '{"prototype":"<prototype>","stack-id":"blue","service":"correnteza"}'
```

After running the command above, check if the new service is healthy by running the
following command (also, on all prototypes):

```{.shell}
nu-<country> ser curl get <prototypes> correnteza /api/version --env staging
```

If this deployment runs correctly on **staging**, repeat this operation using the
**prod** environment.

### Preparing connection to Correnteza on Itaipu

Once _Correnteza_ is up and running in the new country, we will need to prepare
_Itaipu_ HTTP client to be able to talk with it. This [PR](https://github.com/nubank/itaipu/pull/14627/files)
describes how a new instance of __Correnteza_, on a different AWS account, was
enabled on __Itaipu_. Please note that correct the AWS id needs to be hardcoded,
currently.

### Testing with a Contract

Once _Itaipu_ is configured to use the new instance of _Correnteza_, we will
be able to test it by adding a contract to the correspondent country package
and running a job which will read the deployed files for the given contract
and commit its output on _Metapod_.

Ideally, at this step, you should use contracts which are owned by data-infra or
contracts with some data available currently available on the new country. In the
case of Colombia, we first test it by using the `acquisition` contract, which was
added to the `nu.data.co.dbcontracts.aquisition` package. We test it using the
following command:

```{.shell}
nu-data datainfra sabesp -- --aurora-stack=staging-foz jobs itaipu staging contract-test s3a://nu-spark-metapod-ephemeral-1 s3a://nu-spark-metapod-ephemeral-1 3 --itaipu=$YOUR_ITAIPU_VERSION --scale=$SCALE_VERSION --transaction-type hotfix --filter-by-prefix=nu-co/raw/acquisition-s0/log
```

Check on _Metapod_ if the log was indeed committed on the newly created
transaction, or on __Splunk_ in case of any exceptions.

## Dataset Series

To cover the "dataset series" use case on the new country installation, both _Alph_
and _Ouroboros_ need to be deployed.

### Spin Alph

_Alph__ will be needed to ingest non-datomic data used in the new country.
In order to deploy it, please copy and adapt the following definition for the new country:

- [Service](https://github.com/nubank/definition/blob/master/resources/co/services/alph.edn)}

After creating the new definitions, launch the following commands on the **staging**
_Nimbus_ console to spin the service on all necessary shards, using the given command:

```{.clojure}
(doseq [prototype ["global" "s0"]] ; use more prototypes if needed
  (app/create! (keyword prototype) "blue" :alph "<image-version-as-string>"))
```

You can list the last image version using the ```nu registry list-images nu-alph```
command.

Once those pods are successfully created, you will need to upsert DNS aliases for
this service on the new country. You can do it by using the following command:

```{.shell}
nu serverless invoke update-canonical-dns --invoke-type sync --account-alias $country --env staging --payload '{"prototype":"<prototype>","stack-id":"blue","service":"alph"}'
```

After running the command above, check if the new service is healthy by running the
following command (for all existing prototypes):

```{.shell}
nu-$country ser curl get $prototype alph /api/version --env staging
```

If this deployment runs correctly on **staging**, repeat this operation using the
**prod** environment.


### Spin Ouroboros

_Ouroboros_ will be needed to act as the metadata storage for dataset series in
the new country. In order to deploy it, please copy and adapt the following
definitions for the new country:

- [Service](https://github.com/nubank/definition/blob/master/resources/co/services/ouroboros.edn)
- [Data storage](https://github.com/nubank/definition/blob/master/resources/co/datomics/ouroboros-datomic.edn)

We also need to specialize _Ouroboros_'s configuration in order for it to access
the correct bucket for the given country. On the _Ouroboros_'s `config` branch,
copy and adapt the correspondent configuration file as such:}

```{.json}
    {"valid_input_path_buckets": [
        "nu-spark-metapod-manual-dataset-series-<country>-<env>"
        ]
    }
```

After creating the new definitions and setting the country-specific configuration,
wait until the __definition_ project pipeline is done since it will be the
responsible for creating the datomic transactor.

If the _definition_ pipeline finishes successfully, you can try to spin the service on the
`:global` prototype only since _Ouroboros_ is not sharded, using the given command on the
**staging** _Nimbus_ console:

```{.clojure}
(app/create! :global "blue" :ouroboros "<image-version-as-string>")
```

You can list the last image version using the ```nu registry list-images nu-ouroboros```
command.

Once those pods are successfully created, you will need to upsert DNS aliases for
this service in the new country. You can do it by using the following command:

```{.shell}
nu serverless invoke update-canonical-dns --invoke-type sync --account-alias $country --env staging --payload '{"prototype":"global","stack-id":"blue","service":"ouroboros"}'
```

After running the command above, check if the new service is healthy by running the
following command:

```{.shell}
nu-$country ser curl get global ouroboros /api/version --env staging
```

If this deployment runs correctly on **staging**, repeat this operation using the
**prod** environment.

### Preparing connection to Ouroboros on Itaipu

In order to allow the manual dataset series in the new country, we will need to
modify _Itaipu_ in order for it to talk with the country-specific instance
of _Ouroboros_. This [PR](https://github.com/nubank/itaipu/pull/14769/files)
illustrates how a new _Ouroboros_ client can be defined on _Itaipu_.

### Testing dataset series use-cases

Testing _Alph_ is pretty simple: just by checking if new Avro files are
being deployed on the target bucket is enough to consider the service as up
and running correctly.

In order to test the new instance of __Ouroboros_, we need to append a manual
dataset series successfully. However, when a new country is deployed, there is
currently no manual dataset series to do this test (and so far, we don't have a
dummy one). You are free to copy an existing manual dataset series from another
country, append it, and delete it just afterward.

Supposing that you copied a manual dataset series from another country, and generated
an itaipu version containing this change, run the following command to append it:

```{.shell}
nu-$country> dataset-series --env staging append my-series-name s3://nu-tmp-new-country/myfolder/file.parquet
```

Check if it was correctly appended using the following command:

```{.shell}
nu-$country dataset-series --env staging info my-series-name
```

In order to delete it, please run the following command:

```{.shell}
nu-$country ser curl POST --env staging global ouroboros /api/admin/migrations/delete-record-series -d'{"series-name": "series/my-series-name"}'
```

## Serving Layer

This section describes the deployment of the serving layer components
in a new country.

### Spin Conrado
------------

_Conrado_ acts like a rest interface, backed by a data storage, of part of the
computation on the ETL run which needs to be propagated to other services. Its
data storage is fed by __Tapir_ after the dataset is generated on _Itaipu_. For
that reason, we need to create this data storage prior to spin _Conrado_
and _Tapir_.

In order to create _Conrado_'s data storage and service for the new country,
please copy and adapt the following definitions:

- [Service](https://github.com/nubank/definition/blob/master/resources/co/services/conrado.edn)
- [Data storage](https://github.com/nubank/definition/blob/master/resources/co/dynamodbs/conrado.edn)

After creating the new definitions, launch the following commands on the
**staging** _Nimbus_ console to spin all the required data storage:

```{.clojure}
(doseq [prototype ["global" "s0"]] ; use more prototypes if needed
    (dynamodb/create-table! (keyword prototype) "conrado"))
```

```{.clojure}
(doseq [prototype ["global" "s0"]] ; use more prototypes if needed
    (dynamodb/create-table! (keyword prototype) "serving-layer-schemas"))
```

If the commands above finished successfully, you can try to spin the service, on all
available prototypes (_s0_, _s1_ ... + __global_), using the given command:

```{.clojure}
(doseq [prototype ["global" "s0"]] ; use more prototypes if needed
  (app/create! (keyword prototype) "blue" :conrado "<image-version-as-string>"))
```

You can list the last image version using the ```nu registry list-images nu-conrado```
command.

Once those pods are successfully created, you will need to upsert DNS aliases for
this service in the new country. You can do it by using the following command:

```{.shell}
nu serverless invoke update-canonical-dns --invoke-type sync --account-alias $country --env staging --payload '{"prototype":"<prototype>","stack-id":"blue","service":"conrado"}'
```

After running the command above, check if the new service is healthy by running the
following command (also, on all prototypes):

```{.shell}
nu-$country> ser curl get $prototypes conrado /api/version --env staging
```

If this deployment runs correctly on **staging**, repeat this operation using the
**prod** environment.

### Spin Tapir

Once _Conrado_ data storage is created, we are able to spin _Tapir_. An additional
data storage is required to keep track of the datasets already loaded. Please copy and
adapt the following definitions for the new country:

- [Service](https://github.com/nubank/definition/blob/master/resources/co/services/tapir.edn)
- [Data storage](https://github.com/nubank/definition/blob/master/resources/co/dynamodbs/tapir.edn)

We also need to specialize _Tapir_'s configuration in order for it to access
the correct bucket for the given country. On the _Tapir_'s `config` branch,
copy and adapt the correspondent configuration file as such:

```{.json}

    {
       "partitions-bucket": "nu-spark-metapod-ephemeral-pii-<country>-<env>"
    }
```

After creating the new definitions and setting the country-specific configuration,
launch the following commands on the **staging** _Nimbus_ console to spin
the required data storage:

```{.clojure}
(dynamodb/create-table! :global "tapir")
```

If the commands above finished successfully, you can try to spin the service on the
`:global` prototype only since _Tapir_ is not sharded, using the given command:

```{.clojure}
(app/create! :global "blue" :tapir "<image-version-as-string>")
```

You can list the last image version using the ```nu registry list-images nu-tapir```
command.

Once those pods are successfully created, you will need to upsert DNS aliases for
this service in the new country. You can do it by using the following command:

```{.shell}
nu serverless invoke update-canonical-dns --invoke-type sync --account-alias $country --env staging --payload '{"prototype":"global","stack-id":"blue","service":"tapir"}'
```

After running the command above, check if the new service is healthy by running the
following command:

```{.shell}
nu-$country ser curl get global tapir /api/version --env staging
```

If this deployment runs correctly on **staging**, repeat this operation using the
**prod** environment.

### Preparing serving layer on Itaipu

_Itaipu_ also needs to be modified to support the propagation of datasets to
the serving layer. This [PR](https://github.com/nubank/itaipu/pull/15211/files)
illustrates the required modifications to enable it for the new country.

### Testing serving layer

In order to test the serving layer use cases, we will need to create a dataset to
be propagated by _Itaipu_. The rows of this dataset will then be loaded by
_Tapir_ and exposed by _Conrado_ via its rest interface.

In order to test this, in the case of Colombia, we copied tested by copying
`dataset/dummy-tapir` into `nu.data.co.datasets.infra.DummyServingLayerDataset`.
We then executed the following command to compute and propagate this dataset:

```{.shell}
nu-data datainfra sabesp -- --aurora-stack=staging-foz jobs itaipu staging serving-layer-test s3a://nu-spark-metapod-ephemeral-1 s3a://nu-spark-metapod-ephemeral-1 1 --itaipu=$YOUR_ITAIPU_VERSION --scale=$SCALE_VERSION --transaction-type hotfix --filter-by-prefix=nu-co/dataset/dummy-tapir
```

If everything is working correctly, you can query _Conrado_ by using the id
indicated on the `nu.data.co.datasets.infra.DummyServingLayerDataset` file.

**NOTE:**
* The id used on this request must be in lowercase!

```{.shell}
nu-$country k8s curl GET global conrado --accept application/edn /api/dataset/dummy-tapir/row/d0fe8a94-6375-44df-88ef-b37e0b2ed8d4
```

Please check if the row was found at _Conrado_ and the content matches with
the data indicated on `nu.data.co.datasets.infra.DummyServingLayerDataset`.

## Streaming Contracts

### Spin AuroraDB

We are only in the first stages of automating this part. In
particular:

  * The following commands do not faithfully represent the _current_
    state for two reasons:
      * At the moment, nothing prevents manual changing and there is
        no easy way to detect them
      * Some small details are different
  * They are not complete, yet: The role
    `rds-barragem-aurora-enhanced-monitoring` has been created manually.
    This role contains _only_ the following policy:
    `AmazonRDSEnhancedMonitoringRole`

Prerequisites:
  * You need the following temporary permissions
      * `barragem-aurora-spin`
      * `barragem-aurora-enhanced-monitoring`
  * Your AWS profiles should be correctly set up. This is also why we
    do not use something like `nu aws ctl`: with profiles in place
    there is no need to (plus `nucli` doesn’t actually play well with
    roles, at the moment, forcing you to hard code the region).

#### Security group

```{.shell}
aws --profile $country-$env \
    ec2 create-security-group \
    --group-name $env-$prototype-barragem-aurora \
    --description 'Barragem AuroraDB' \
    --vpc-id <vpc-id>
```

**NOTES:**
  * `<vpc id>` should not be difficult to find. Look for something
    called `<env>-<color>-vpc`. At the time of this writing,
    [2020-11-03 Tue], the color is `blue`.

The command will return the ID of the security group, which you can
then use for the next step:

```{.shell}
aws --profile $country-$env \
    authorize-security-group-ingress \
    --group-id <sg-id> \
    --protocol tcp \
    --port 5432 \
    --source-group prod-long-lived-resources-kubernetes-nodes-sg
```

**NOTES:**
  * `prod-long-lived-resources-kubernetes-nodes-sg` is the name of the
    security group assigned to the instances running Barragem. We
    don’t control it and it should be considered subject to change.
  * As you can see, we could have a single security group for all the
    different shards. For the time being, we still create a dedicated
    security group for each shard.

#### Subnet group

RDS, i.e. the managed database service, adds an additional grouping
mechanism on top of subnets, so we need to create one:

```{.shell}
aws --profile $country-$env \
    rds create-db-subnet-group \
    --db-subnet-group-name barragem-$env \
    --db-subnet-group-description "Barragem AuroraDB" \
    --subnet-ids '[<subnet ids commalist>]'
```

**NOTES:**
  * '[<subnet ids commalist>]' is still poorly defined. In Brazil and
    Colombia we included all the subnets, but it’s probably not
    needed. This shouldn’t be a big security problem, because of the
    security group, but still.

#### Parameter groups

Create the parameter groups, for both the cluster and the single instance:

```{.shell}
aws --profile $country-$env \
    rds create-db-cluster-parameter-group \
    --db-cluster-parameter-group-name $env-barragem-aurora-postgres10-cluster \
    --db-parameter-group-family aurora-postgresql10 \
    --description "Parameter group for Postgres cluster, version 10"

aws --profile $country-$env \
    rds create-db-parameter-group \
    --db-parameter-group-name $env-barragem-aurora-postgres10-instance \
    --db-parameter-group-family aurora-postgresql10 \
    --description "Parameter group for Postgres instance, version 10"
```

#### Cluster and instance

We can now create both the cluster and the instance:

```{.shell}
aws --profile $country-$env \
    rds create-db-cluster \
    --backup-retention-period 7 \
    --db-cluster-identifier $env-$prototype-barragem-aurora \
    --engine aurora-postgresql \
    --engine-version 10.7 \
    --storage-encrypted \
    --no-enable-iam-database-authentication \
    --master-username postgres \
    --master-user-password <password> \
    --db-subnet-group-name barragem-$env \
    --db-cluster-parameter-group-name $env-barragem-aurora-postgres10-cluster \
    --deletion-protection \
    --vpc-security-group-ids <sg-id> \
    --database-name postgres \
    --port 5432 \
    --engine-mode provisioned
```

```{.shell}
aws --profile $country-$env \
    rds create-db-instance \
    --db-cluster-identifier $env-$prototype-barragem-aurora \
    --engine aurora-postgresql \
    --db-instance-identifier $env-$prototype-barragem-aurora-instance \
    --db-instance-class <instance-type> \
    --db-subnet-group-name barragem-$env \
    --db-parameter-group-name $env-barragem-aurora-postgres10-instance \
    --auto-minor-version-upgrade \
    --no-publicly-accessible \
    --storage-encrypted \
    --enable-performance-insights \
    --monitoring-interval 60 \
    --monitoring-role-arn <rds-barragem-aurora-enhanced-monitoring ARN>
```

**NOTES:**
  * The password must be saved under
    `nu-secrets-<country>-<env>/barragem_secret_config.json`. The
    contents has the following shape: `{"rdb-password": "<pwd>"}`.
  * `--no-enable-iam-database-authentication` is needed because
    Barragem still doesn’t support using IAM as an authentication
    mechanism.
  * Some of the flags are repeated with both `create-db-cluster` and
    `create-db-instance` and it’s probably not needed, but it doesn’t
    break anything, either.
  * `<instance-type>` in a production setting should be something
    equivalent to `db.r5.large`.

### Spin Barragem

Once the RDS is created on each prototype, we can start the _Barragem_ service spin.
In order to do that, please copy and adapt the following definition:

- [Service](https://github.com/nubank/definition/blob/master/resources/co/services/barragem.edn)

We also need to specialize _Barragem_'s configuration in order for it to access
the correct bucket and RDS for the given country. On the _Barragem_'s `config`
branch, copy and adapt the correspondent configuration file as such:

```{.json}

    {
       "datomic-logs-bucket": "nu-spark-datomic-logs-<country>-<env>",
       "rdb-unqualified-endpoint-url": "barragem-aurora-instance.<host>-<region>.rds.amazonaws.com"
    }
```

After creating the new definitions and the country specific configuration,
launch the following commands on the **staging** _Nimbus_ console to spin
all the service on all available prototypes (_s0_, _s1_ ... + __global_):

```{.clojure}
(doseq [prototype ["global" "s0"]] ; use more prototypes if needed
  (app/create! (keyword prototype) "blue" :barragem "<image-version-as-string>"))
```

You can list the last image version using the ```nu registry list-images nu-barragem```
command.

Once those pods are successfully created, you will need to upsert DNS aliases for
this service in the new country. You can do it by using the following command:

```{.shell}
nu serverless invoke update-canonical-dns --invoke-type sync --account-alias $country --env staging --payload '{"prototype":"<prototype>","stack-id":"blue","service":"barragem"}'
```

After running the command above, check if the new service is healthy by running the
following command (also, on all prototypes):

```{.shell}
nu-$country ser curl get $prototype barragem /api/version --env staging
```

If this deployment runs correctly on **staging**, repeat this operation using the
**prod** environment.


### Schedule segments processing

In order for _Barragem_ to start processing its segments, it needs to receive
requests from an external scheduler (_Tempo_). In order to do so, you will need
to set up tasks definitions as such:

- [Schedule segments for global prototype](https://github.com/nubank/definition/blob/master/resources/co/tasks/barragem-process-next-segment-global.edn)
- [Schedule segments for sharded prototypes](https://github.com/nubank/definition/blob/master/resources/co/tasks/barragem-process-next-segment-shards.edn)

**NOTES:**
* _Barragem_ will receive one schedule request for each DB specified on the
tasks.
* Make sure _Tempo_ is cycled after the new tasks are merged.


## Troubleshooting

### Country Security Keys/Tokens

In the new country installation, we assume that the _Foundation_ tribe already took
care of copying country-specific security tokens/keys. However, this seems to be a manual
step on their installation playbooks, and thus, prone to error. In this case, you
are going to see the following errors when spinning the services:

(On _Metapod_)
```
Caused by:
clojure.lang.ExceptionInfo: Object pub/auth/sign-pem/2020-06-05T14:39:10.187-skXzvxxdl_wAAAFyhOvfbQ not found on s3 env prod
    at common_crypto.amazon.s3$fn__49986$get_obj_BANG__STAR___49991$fn__49992.invoke(s3.clj:89) ~[metapod-0.1.0-SNAPSHOT-standalone.jar:na]
    at common_crypto.amazon.s3$fn__49986$get_obj_BANG__STAR___49991.invoke(s3.clj:84) ~[metapod-0.1.0-SNAPSHOT-standalone.jar:na]
    at clojure.lang.AFn.applyToHelper(AFn.java:160) [metapod-0.1.0-SNAPSHOT-standalone.jar:na]
```

(On _Tapir_ or _Conrado_)
```
Caused by:
clojure.lang.ExceptionInfo: Object pub/auth/sign-pem/2019-08-08T11:29:17.127-_X3TGFOydo0AAAFscP1_Sg not found on s3 env prod {:type :not-found, :details {:bucket "nu-keysets-co-prod", :key "pub/auth/sign-pem/20
19-08-08T11:29:17.127-_X3TGFOydo0AAAFscP1_Sg", :exception #error {| :cause "The specified key does not exist. (Service: Amazon S3; Status Code: 404; Error Code: NoSuchKey; Request ID: 38FBD2C39CA5A3D5; S3 Exten
ded Request ID: WzC7yOlR4zB9nNVh8JJJGtKfp+/gJcUW3/Oz9myUZmAejUNhZvgZZFZqydH0AJK4LvY8NvgrgbY=)"
```

If any similar error occurs, please contact the _Foundation_ tribe to make sure
[these](https://github.com/nubank/playbooks/blob/master/squads/international/security.md#tokens) steps
of the playbook was executed for the new country. In case of doubt, ask them to
re-execute the following command:

```{.shell}
aws s3 cp --profile sec-$env --recursive /tmp/keysets/$env/pub/auth/sign-pem/ s3://nu-keysets-master-$env/all/pub/auth/sign-pem/
```

## See also

- [Muti-country data infrastructure presentation](https://docs.google.com/presentation/d/17c2l00x6rdO9bt2C3ZD2P_Gn2G1so7BXEyFwY_gaky0/edit#slide=id.g7e12e10c74_0_14)
