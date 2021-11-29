---
owner: "#data-infra"
---

# Data Platform Documentation Hub

[![CircleCI](https://circleci.com/gh/nubank/data-platform-docs.svg?style=svg&circle-token=0d7949cdca982ceb84320b0184c1f529d52df53e)](https://circleci.com/gh/nubank/data-platform-docs)

Data Platform Docs is a central documentation hub for Data platform Engineers and Data users. It is a one-stop store that contains the detailed documentation for developers to understand and work on the internal microservices and collaborate to create new services. This platform helps developers and data users to focus on a single documentation source, instead of hunting down several individual guides for different services.

The knowledge base comprises a comprehensive list of all microservices and its details, information on thought-through architectures, step-by-step guides, Incident response guides, Dataset series guides, FAQs, and more. 

<br/>

|![](images/data-infra-icon.png)Data Infrastructure|![](images/data-infra-icon.png)Analytics Productivity|
:--------------------------------------------:|:------------------------------:
|[Dataset series on ETL](data-users/etl_users/dss-on-etl.md)|[About Analytics Productivity](https://playbooks.nubank.com.br/squads/analytics-productivity/)|
|[Manual Dataset Series](data-users/etl_users/manual_dataset_series.md)|[Optimize your SparkOp](data-users/etl_users/optimizing_your_sparkop.md)|
|[Archive Dataset series](data-users/etl_users/archived_datasets.md)|[Core Datasets](datasets/core-datasets/README.md)|
|[Services](services/data-ingestion/intro.md)|[Frozen Suite](https://docs.google.com/document/d/1tJx9ifOhscM7P4MtFifblbtDUoGTk-JqkDN9DXCqPsI/edit#heading=h.h1dr4jt5gg6g)|
|[Overview of Itaipu](services/data-processing/itaipu/itaipu.md)|[Iglu](tools/frozen_suite/iglu/README.md)|
|[Opening PRs on Itaipu](how-tos/itaipu/opening_prs.md)|[Ice mold](https://github.com/nubank/itaipu/tree/master/src/main/scala/etl/warehouse/ice_mold)|
|[Reviewing and merging PR on Itaipu](how-tos/itaipu/itaipu_reviewers.md)|[IceQL](tools/frozen_suite/iceql/README.md)|


<br/>

|![](images/data-users.png)Data Access|![](images/data-users.png)Data users - FAQs|
|:----:|:---------------------------:|
|[Databricks](tools/databricks/README.md)|[Dataset series](data-users/FAQs/dataset-series.md)|
|[Looker](tools/looker/README.md)|[PII Data](faqs/pii-data.md)|
|[Airflow](tools/airflow.md)|[Compilated failed - Itaipu](data-users/etl_users/FAQ.md)|

<br/>

## Data Infra Architecture

![Image of our infra](images/DataInfraArchitecture.png)

### Documentation site structure

- **About** - Contains all Data BU Squads overview, services owned and slack channels.
- **How-tos** - contains all the service related how-tos / cookbooks
- **Services** - contains all service related concepts.
- **On-call** - contains documentation set required for on-call engineers.
- **Onboarding** - contains all squads onboarding material.
- **Tools** - contains all squads tools that are used to generate and view dashboards.
- **Infrastructure** - contains all squads infrastructure - clusters, monitoring tools, tech stacks.
- **Troubleshooting** - contains all service related troubleshooting topics.


## Contributing

If you are contributing to the data-platform-docs, please be mindful of the following things:

* Make sure every .md file contains the owner on top and an empty line on bottom. Refer existing files.

Before creating a PR, check locally if all the required tests are passed by running the following commands:

- ./bin/run-tests
- ./bin/local-build.sh
- ./bin/run-lint.sh

## Preview Data Platform Documentation

1. If you want to render just a file or directory: `nu bookcase preview --path path/you/want/preview`.
1. If you want to preview all the documentation, run `nu bookcase preview data-platform-docs`.
1. Wait until the Serving on http://0.0.0.0:8000 message is displayed on Terminal. It is the confirmation that the playbooks have been rendered. Due to the large amount of documents to be loaded, this operation takes several minutes.
1. On the browser, go to http://localhost:8000 to access the generated preview.

<!-- markdownlint-disable-file -->
