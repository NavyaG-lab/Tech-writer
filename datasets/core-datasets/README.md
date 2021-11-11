---
owner: "#analytics-productivity"
toc: false
---

# Core Datasets Documentation

## Table of contents

<!--ts-->
* [Core Datasets Documentation](#core-datasets-documentation)
* [Table of contents](#table-of-contents)
* [Context](#context)
* [For consumers](#for-consumers)
  * [What is a core dataset?](#what-is-a-core-dataset)
    * [What are the advantages of using a core dataset?](#what-are-the-advantages-of-using-a-core-dataset)
    * [How do I discover a core dataset?](#how-do-i-discover-a-core-dataset)
    * [General requirements for core datasets](#general-requirements-for-core-datasets)
* [For producers](#for-producers)
  * [What are the advantages of creating a core dataset?](#what-are-the-advantages-of-creating-a-core-dataset)
    * [When/why should I create a core dataset?](#whenwhy-should-i-create-a-core-dataset)
    * [How can I contribute to core?](#how-can-i-contribute-to-core)
      * [Contribution guidelines](framework/contribution-workflow.md).
      * [Possible scenarios before going to core](#possible-scenarios-before-going-to-core)
        * [Moving an existing dataset to core](#moving-an-existing-dataset-to-core)
          * [What is a shim?](#what-is-a-shim)
            * [How do I know if I need a shim?](#how-do-i-know-if-i-need-a-shim)
            * [Steps to move a dataset to core](#steps-to-move-a-dataset-to-core)
            * [Detailed FAQ](framework/FAQ.md) and [other docs](https://drive.google.com/file/d/1z0adUG6lqGqkBZX8sbyz17rCVB-90QaQ/view?usp=sharing)
        * [Creating a dataset in the core layer from scratch](#creating-a-dataset-in-the-core-layer-from-scratch)
    * [Additional rules to contributing](#additional-rules-to-contributing)
* [Troubleshooting](#troubleshooting)
<!--te-->

## Context

In a collaborative data environment where anyone can design their own data assets without much friction, understanding the most reliable source for a specific data need may not be trivial. Core datasets are an initiative whose main goal is to provide an official source of truth for the main business needs, across several business domains and products.

The following sessions are split into Consumer and Producer content to better suit your use cases

## For consumers

### What is a core dataset?

Basically, it is a dataset that shares a common documentation format, design pattern and testing convention. By following core datasets design requirements,  it becomes more stable, reliable and traceable. Further details on how to reach these requirements can be found [here](#general-requirements-for-core-datasets). 

### What are the advantages of using a core dataset?


On the consumer side, these are the advantages of using a core dataset:

1. The code follows best practices to provide performance and transparency, with the Analytics Productivity being responsible for reviewing and assuring good standards
2. Reduce the struggle of understanding the logic and concepts behind datasets, since having a clear documentation is among the requirements
3. As all core datasets have an assigned ownership, consumers can refer to the person if the documentation isn't enough or if any issues are found
4. The dataset is monitored by row count alerts, also any changes made must be communicated in #data-announcements

### How do I discover a core dataset?

You can find released core datasets in Databricks, Compass and BigQuery, searching for the core namespace.

The following links can help you find them on compass:
[BR core](https://backoffice.nubank.com.br/compass/#search/nu-br%20core?search-category=dataset&offset-start=0)
[MX core](https://backoffice.nubank.com.br/compass/#search/nu-mx%20core?search-category=dataset&offset-start=0)
[CO core](https://backoffice.nubank.com.br/compass/#search/nu-co%20core?search-category=dataset)

### General requirements for core datasets

The following rules should be followed in order for a dataset to become core:

1. Core dataset candidate only depends on contracts/other core datasets
2. At least 2 teammate reviews, preferably from the dataset stakeholders
3. At least 1 review from the Analytics Productivity Squad
4. Have a defined owner squad
5. Playbook with dataset details updated (in case of modifications) / created (in case of new dataset). See [example](https://github.com/nubank/playbooks/blob/master/core-datasets/content/facts/credit-card-bills.md)
6. Monitoring in place with at least one alert (row count)
7. Difference Analysis between core candidate and old dataset (in case of a core candidate replacing an old common dataset). See [difizinho](https://github.com/nubank/difizinho)
8. Roll-out plan (in case of a core candidate replacing a old common dataset)

For further details, one can find [this documentation](framework/contribution-workflow.md) useful.

## For producers

### What are the advantages of creating a core dataset?

The advantages brought by moving a dataset to core are a consequence of following the guidelines the Analytics Productivity team defined to promote quality standards in a few topics. These advantages include:

1. Your dataset and namings will become a source of truth for the company, boosting its visibility
2. Reduce the struggle on the consumer side of understanding the logic and concepts behind datasets, by providing a clear documentation
3. You get row count monitoring alerts that can give visibility and help the owner to react to any issues, in each and every run. More alerts can be implemented the same way
4. The core namespace have a contribution flows that guarantees stability and reliability

### When/why should I create a core dataset?

First of all, it's important to clarify that not every dataset must become a core dataset. Eligible datasets are the ones that, for example, contain critical information that supports multiple business processes, products or financial reports.

Also, the following list contains some situations where one could benefit from moving a dataset to core:

- There are some critical or important information of the company that doesn't have a quality dataset available, and you have the knowledge to build that source-of-truth
- Data consumers are struggling to discover the dataset and giving more visibility to it could help
- Documentation lacks details and it's hard to understand business rules behind each dimension, by moving to core it would have to go through better quality standards
- Consumers are facing data quality issues and having more control over it could help increase the quality
- When monitoring is needed. There is a compulsory row count monitoring for core and its possible to add other controls with controlinho
- Too many datasets with the same grain, one should become "official"


### How can I contribute to core?

#### Possible scenarios before going to core

There are 2 scenarios where one can put a dataset in the core layer:

1. The dataset already exists, and one would like to move it to core
2. The dataset was created from scratch and will be put into the core layer

The following sections provide details for the user to deal with both situations.

Also, the process of moving a dataset to core consists of 2 phases:

- Alpha release (optional)
  * Advisable for bigger datasets that may have performance issues or when feedback regarding business rules is required from stakeholders
- General release

These steps are planned as such to provide a smooth rollout and prevent any issues on sharing new data. Each phase has its own requirements. For more information on that, one can find [this documentation](framework/contribution-workflow.md) useful.

#### Moving an existing dataset to core

When moving an existing dataset to core, one must keep in mind that its successors should not be impacted by the change. Depending on the amount and importance of successors the dataset has, it may require a shim or not, in order to not break anything.

##### What is a shim?

Basically, a shim is a term adapted to represent the process of integrating the old dataset with the new core version. It enables us to propagate the core data, without having to deal with the issue that successors would lose the reference to the original dataset. The sparkop of the original dataset then becomes a simple select and rename columns of the core version.

![Shim Picture](/images/shim-example-picture.png)

##### How do I know if I need a shim?

There is no hard rule, but the higher the amount of successors the dataset has the more likely you would think of shimming it, given that the impact of removing it increases. Shimming can be seen as a technical debt, you would only go for shimming if you want to move something to core but you are not willing to spend the time to migrate all successors.

Communicating with the stakeholders that consume from your dataset is recommended to understand the possible impacts of moving it to core.

##### Steps to move a dataset to core

1. Create a sparkop under the core folder, in a similar path of where the original dataset is. This sparkop's name must follow a core naming convention, such as "nu-br/core/dataset-xpto"
2. Decide on whether it will be necessary to shim the dataset or not. Keep in mind that some extra steps are needed in case of shimming, such as:
    - Deciding which columns should be kept in the original dataset and which should go to core (ideally everything should go to core, but for instance in case of deprecated columns this can not be the best solution)
    - After defining where the functions should stay, migrate or adapt their respective unit tests
3. Validate the new core sparkop in databricks and check if it is consistent with the already existing dataset. See [difizinho](https://github.com/nubank/difizinho)
4. Migrate the unit tests to the core namespace or reimplement if necessary
5. Add the new core dataset to the CoreData file as an userDefinedFactTable. In order to do this, the dataset needs to extend "DeclaredDimensionalModel", implement the "grain" field and the "factToDimensionConnections". See [example](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/core/crebito/CreditCards.scala)
6. Before deleting the dataset from its original location, remember to communicate with stakeholders and migrate spreadsheets, notebooks and visualizations to the core dataset


#### Creating a dataset in the core layer from scratch

When creating a dataset in the core layer, keep in mind that it will become a source of truth for stakeholders and ensuring it is aligned with business rules and stakeholders is essential. An alpha release phase is recommended in this case to avoid any precocious issues.

These are the steps recommended to create a core dataset from scratch:

1. Create a sparkop under the core folder
2. Execute sanity checks in the dataset logic and check if it makes sense with stakeholders
3. Validate the new core sparkop in databricks with opToDataFrame
4. Implement the unit tests for the sparkop in the core namespace
5. Add the new core dataset to the CoreData file as an userDefinedFactTable. In order to do this, the dataset needs to extend "DeclaredDimensionalModel", implement the "grain" field and the "factToDimensionConnections". See example
6. Align with stakeholders and check if this dataset is the most reliable source for the business needs and processes involved
7. Check if the attribute names are clear, following the standardized convention (i.e. entity__attribute_name) and if they already exist in the core layer, as they can be present in other core datasets. In the case of already existing, the new and previous definitions should match.
8. Check if the documentation is clear, ideally the business rules and logic should be explicit, the table description should contain the dataset grain and be easily readable (paragraphs resembling bullet points are a plus!
Examples of good documentation:
[customer_current_snapshot](https://console.cloud.google.com/bigquery?authuser=0&project=nu-mx-data&pli=1&d=core&p=nu-br-data&t=customer_current_snapshot&page=table)
[credit_card_bills](https://console.cloud.google.com/bigquery?authuser=0&project=nu-mx-data&pli=1&d=core&p=nu-br-data&t=credit_card_bills&page=table)


### Additional rules to contributing

One must keep in mind that If any data schema and value changes are made, the stakeholders and consumers should be alerted. It is recommended that the owner announces those changes in #data-announcements, and also the Analytics Productivity team will be responsible for reviewing and helping to guarantee a safe process.

## Troubleshooting

If you are experiencing Out of Memory (OOM) errors with your dataset, check out [our documentation](../../tools/frozen_suite/iglu/troubleshooting.md) for dealing with it.
