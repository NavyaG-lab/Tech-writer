# Data Infra Documentation

This repository is the canonical place to put all documentation related to how to understand and operate in our analytical environment.

## Data Infra Overall

<object data="https://github.com/nubank/data-infra-docs/blob/master/images/DataInfraOverview.pdf" type="application/pdf" width="700px" height="700px">
    <embed src="https://github.com/nubank/data-infra-docs/blob/master/images/DataInfraOverview.pdf">
        This browser does not support PDFs. Please download the PDF to view it: <a href="https://github.com/nubank/data-infra-docs/blob/master/images/DataInfraOverview.pdf">Download PDF</a>.</p>
    </embed>
</object>

![Image of our infra](images/DataInfraOverview.png)

* [Primer](primer.md)
* [Slack channel guide](squad/channels.md)
* [Data Infra Glossary](glossary.md)
* [General Glossary](https://github.com/nubank/playbooks/blob/master/docs/glossary.md)

## ETL User references

* [FAQ](etl_users/FAQ.md)
* [Dataset Series](etl_users/dataset_series.md)
* [Manual Dataset Series](etl_users/manual_dataset_series.md)
* [Archived Datasets](etl_users/archived_datasets.md)

## ETL Operations

* [Hausmeister](squad/hausmeister.md) (a.k.a on-call rotation)
* [Monitoring the nightly run](monitoring_nightly_run.md)
* [On Call Runbook](on-call_runbook.md)
* [Ops How To](ops_how_to.md)
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
* [Bumping Itaipu on Databricks](itaipu/databricks_bump.md)
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
