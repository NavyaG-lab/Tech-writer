---
owner: "#data-infra"
---

# Data Infra release engineering, i.e. how we run stuff in production

_NB. This is a work in progress, filling out the parts we need in a
**very** lazy fashion. See [this ticket][1] for the overall status._

## How Itaipu is deployed to the Dagao

One of the main tenets of this deployment process is: ensure we use
the same version of Itaipu for a given transaction. There are several
reasons for that:

  * Usually different versions have different graph topologies and
    changing it after it has started isn't really possible.
  * New versions may change dataset relationships in ways not covered
    by the integration tests.
  * Downstream services such as databricks-loading assume a single tx
    per day.

On the other hand, we also need to:

  * Avoid blocking the PR workflow to apply changes and contributions
    to `master`.
  * Allow Data Infra operators to apply hot fixes to the version
    currently running in production, without including all the changes
    that have being landed on `master` in the meantime.

So how do we fulfill these constraints?

  * Each batch of pull requests landed on `master` by Bors triggers a
    build job that creates a new image. That same job makes also sure
    to publish this information on S3.
  * The `config_poller` Airflow job, running at regular intervals,
    reads from the same S3 path and refreshes the version for the
    _next_ day.
  * When the new run starts, the `etl_run_versions` node inside Dagao,
    will use the versions prepared by the `config_poller`.

## How Docker images are chosen for a given run

Idealized version:

  * At regular times, the DAG `config_poller` in Airflow updates a
    json file containing a map with the following shape `{ <image
    name>: <version> }`. This is the file that is going to be used in
    the _next_ run.
  * When the ETL starts, i.e. when either `dagao` or `daguito` are
    triggered at midnight UTC, we simply name-swap the current file
    with the new, maintained by the step above.
  * After that we read the contents from that file and create the
    corresponding Airflow variable for that specific run.


Current reality. Even though the steps above are really happening,
there are several nasty and important details worth mentioning:

  * Until the migration to Tekton is completed, we will actually have
    to maintain more than one “DAS file”[^1] -- one coming from GoCD
    and the other one built at run time -- and we need to merge them
    approprietly.
  * The versions are “overlayed” with the contents from
    `custom_itaipu_versions`

## About `hot_deploy_itaipu`

The purpose of this DAG in Airflow is twofold:

1. Update the contents of the `DAS.json` file
2. Update the Airflow variable for the _current day_


## About `custom_itaipu_versions`

This is an Airflow variable, manually maintained at the moment, that
we can use to specify a custom Docker image for Itaipu. It’s map with
the following shape: `{ <itaipu_job_name>: <image version> }`.

To enable the feature, you simply add the name of the node as it
appears in the DAG and the desired version.

**IMPORTANT** At the moment this feature is mainly for testing
purposes because once a given override is in place, every subsequent
run will use it, eventually breaking the node because it will drift
from the new builds used for the rest of the nodes in the run. At the
moment, there are no plans to have proper support to keep a custom
version -- a fork, really -- aligned with the official one.

[1]: https://nubank.atlassian.net/browse/DIEP-2330

[^1]: The origins of the “DAS” name are lost in the mist of the past.
