# Data Platform Documentation [![CircleCI](https://circleci.com/gh/nubank/data-platform-docs.svg?style=svg&circle-token=0d7949cdca982ceb84320b0184c1f529d52df53e)](https://circleci.com/gh/nubank/data-platform-docs)

Data Platform Docs is a central documentation hub for Data Infra, Data Access Engineers and Data users.  It is a one-stop store that contains the detailed documentation for developers to understand and work on the internal microservices and collaborate to create new services. This platform helps developers and data users to focus on a single documentation source, instead of hunting down several individual guides for different services.

The knowledge base contains a comprehensive list of all microservices and its details, information on thought-through architectures, step-by-step guides, Incident response guides, Dataset series guides, FAQs and more.

## Data Infra Overall

* [Primer](primer.md)
* [Slack channel guide](squad/channels.md)
* [Data Infra Glossary](glossary.md)
* [General Glossary](https://github.com/nubank/playbooks/blob/master/docs/glossary.md)

![Image of our infra](images/DataInfraArchitecture.png)

## ETL User references

* [FAQ](etl_users/FAQ.md)
* [Dataset Series](etl_users/dataset_series.md)
* [Manual Dataset Series](etl_users/manual_dataset_series.md)
* [Archived Datasets](etl_users/archived_datasets.md)
* [How to optimize your SparkOp](etl_users/optimizing_your_sparkop.md)

## ETL Operations

* [Hausmeister](hausmeister/hausmeister.md) (a.k.a on-call rotation)
* [Monitoring the nightly run](monitoring_nightly_run.md)
* [On Call Runbook](hausmeister/on_call_runbook.md)
* [Ops How To](hausmeister/ops_how_to.md)
* [Incident Response Checklist](./etl_operators/incident_response_checklist.md)
* [Getting help from other squads](./etl_operators/getting_help_from_other_squads.md)
* [CLI usage examples](cli_examples.md)
* [GraphQL clients](ops/graphql_clients.md)
* [Airflow](airflow.md)
* [Metapod](metapod.md)

## Itaipu

* [Primer](itaipu/primer.md)
* [Styleguide](itaipu/styleguide.md)
* [Workflow](itaipu/workflow.md)
* [Bumping Itaipu on Databricks](databricks/library_bump.md)
* [Updating the Log Cache](itaipu/log_cache_update.md)
* [Dataset Series Compaction](itaipu/dataset_series_compaction.md)
* [Pororoca](itaipu/pororoca.md)

## Infrastructure

* [Inventory](infrastructure/inventory.md)
* [Multi-country pointers](infrastructure/multi-country.md)
* [Guide to the runtime environment (Mesos & Aurora)](infrastructure/guide-to-the-runtime-environment.md)
* [Query Engines used/considered at Nubank](infrastructure/query_engines.md)
* [Testing models in staging](infrastructure/testing-models.md)
* [The Serving Layer](infrastructure/serving_layer.md)

## Squad

### Working groups

* [Index of working groups and their outputs](squad/working_groups/index.md)

### Onboarding

* [Introduction and setup](onboarding/introduction.md)
* [Exercise Part I: Creating a dataset](onboarding/dataset-exercise.md)
* [Exercise Part II: Creating a service to expose a dataset via API](onboarding/service-exercise.md)

## Dimensional Modeling (Data Access)

* [Kimball on Dimensional Modeling Quotes](dimensional_modeling/kimball.md)
* [Contribution Margin (and how to update static inputs)](dimensional_modeling/contribution_margin.md)
