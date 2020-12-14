---
owner: "#data-infra"
---

# Data Platform Documentation Hub

[![CircleCI](https://circleci.com/gh/nubank/data-platform-docs.svg?style=svg&circle-token=0d7949cdca982ceb84320b0184c1f529d52df53e)](https://circleci.com/gh/nubank/data-platform-docs)

Data Platform Docs is a central documentation hub for Data platform Engineers and Data users. It is a one-stop store that contains the detailed documentation for developers to understand and work on the internal microservices and collaborate to create new services. This platform helps developers and data users to focus on a single documentation source, instead of hunting down several individual guides for different services.

The knowledge base comprises a comprehensive list of all microservices and its details, information on thought-through architectures, step-by-step guides, Incident response guides, Dataset series guides, FAQs, and more.

<table>
  <tr>
  <td>
    <p><img src="images/data-users.png" width="40" height=""/><b>Data Users</b></p>
    <p>
     <ul>
     <li><a href="https://data-platform-docs.nubank.com.br/data-users/etl_users/dss-on-etl/">Dataset series on ETL</a></li>
     <li><a href="https://data-platform-docs.nubank.com.br/data-users/etl_users/optimizing_your_sparkop/">Optimizing your SparkOp</a></li>
     <li><a href="https://data-platform-docs.nubank.com.br/how-tos/itaipu/itaipu_reviewer/">Reviewing and merging a PR on Itaipu</a></li>
     <li><a href="https://data-platform-docs.nubank.com.br/data-users/etl_users/manual_dataset_series/">Manual Dataset series<a></li>
     <li><a href="https://data-platform-docs.nubank.com.br/data-users/etl_users/ingestion/archives/">Archive Dataset series<a></li>
     </ul></p>
     </td>
  <td>
    <p><img src="images/data-infra-icon.png" width="40" height=""/><b>Data Infrastructure</b></a>
     <ul>
      <li><a href="https://data-platform-docs.nubank.com.br/infrastructure/data-infra/inventory/">Services</a></li>
      <li><a href="https://data-platform-docs.nubank.com.br/on-call/data-infra/on_call_runbook/">Hausmeister / On-call runbook</a></li>
      <li><a href="https://data-platform-docs.nubank.com.br/services/data-processing/itaipu/itaipu/">Overview of Itaipu</a></li>
        <li><a href="https://data-platform-docs.nubank.com.br/how-tos/itaipu/contracts/">How-tos</a></li>
        <li><a href="https://data-platform-docs.nubank.com.br/onboarding/data-infra/introduction/">Onboarding</a></li>
        <li><a href="https://data-platform-docs.nubank.com.br/tools/databricks/">Tools</a></li>
    </ul></p>
     </td>
  </tr>

</table>

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

If you are contributing to the data-platform-docs please be mindful of the following things:

* Make sure every .md file contains the owner on top and an empty line on bottom. Refer existing files.
* If a new file is added, make sure its relative path is added in `mkdocs.yml`, under `nav`.
* If a file is deleted make sure the relative path is deleted as well.
* If a file is renamed, make sure it's updated in the `nav` in the `mkdocs.yml`.

If you don't want to go through the above list, then before merging your PR,
use the following commands to check if all the required tests are passed

./bin/run-tests
./bin/local-build.sh

<!-- markdownlint-disable-file -->
