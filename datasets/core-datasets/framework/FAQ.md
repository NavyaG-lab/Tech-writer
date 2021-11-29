---
owner: "#squad-analytics-productivity"
---


# Frequently Asked Questions

## `Understanding`

### Why should I use a core dataset

Core datasets are meant to be trustable sources of truth for important metrics in Nubank. So, if you want to use the same high quality data that is being used by many processes in Nubank, they're here for you!

### Why should I trust core datasets

They're built and maintained using the following steps that assure their quality such as:

- All definitions are agreed among important stakeholders
- The code follows best practices to provide performance and transparency
- Every information surrounding each core dataset is documented
- The core namespace have a contribution flows that guarantees stability and reliability
- Core datasets are actively monitored to ensure their quality in each and every run

### What distinguishes a core from a regular dataset

A core dataset is created and maintained following a more [rigorous process](contribution-workflow.md) than regular datasets, and, apart from that, they have a different namespace called `core`.

### What makes a dataset eligible to become core

First of all, it's important to clarify that not every dataset must become a core dataset. Since it takes more effort then regular datasets, the eligible datasets are the ones that, for example, contain critical information that supports multiple business processes, products or financial reports. This list is not exhaustive and we'll expect to gain more clarity over time on what should be, and what should not be, core datasets at Nubank.

### Do core datasets have regular datasets as dependencies

No, core datasets sources are either data directly from services (contracts) or other core datasets. Non-core datasets cannot be used because since they are not subject to the same quality requirements. There could be notable exceptions for this rule (such as the `date dimension` dataset).

### How often new data is added to a dataset

New data is added on demand, but in order to guarantee backwards compatibility, every new information should be added as a new column. Check [here](#how-can-i-be-sure-changes-wont-break-my-logic) to learn more.

### Are the core datasets conciliated with accounting statements

For datasets where it is applicable, conciliation with accounting statement is a trust goal. After this is checked, it will be documented on the core dataset's manual.

### How can I be sure changes won't break my logic

Changes made to core datasets are made in the following way:

- If a column has a transformation logic that does not satisfy or does not correspond to a squad specific concept or business logic, a new column must be created instead of changing the current one, with exception of clear bug fixes.

- If the granularity of a core dataset do not satisfy a squad specific need, a new core dataset should be created instead of changing the current one.

Given that, changes to existing core datasets must be approved by every impacted squads.

<br />

## `Discovering`

### Do we have a core dataset with the information I need

In order to find whether there is a core dataset with the information you need, you can search for it in the list of core datasets.

### Where do I find information about a core dataset

Every core dataset is created and updated with an accompanying documentation in a common format that is found in the [[core datasets doc repo]]. The manuals contain a summary, information on context of creation and inclusion in core datasets and links to further information and sources, as well as the squad responsible for maintaining the dataset.

### What is the definition of a column

The documentation of each core dataset contains the definitions agreed among stakeholders. Please visit the playbook of the core dataset of your interest and access the `Columns description` item, right at the beginning of the playbook.

### How do I know what are the columns in the dataset

Every playbook in [[core datasets doc repo]] links to the full column description of the core dataset and details the concepts used in its creation. Please visit the playbook of the core dataset of your interest and access the `Columns description` item, right at the beginning of the playbook.

### Who is the owner of this dataset and its dependencies

The owner of each core dataset is described in the core dataset documentation.

## `Sources and Services`

### How do I know what are the sources of a core dataset

Every playbook in [[core datasets doc repo]] lists the data sources used in building the core dataset. Please visit the playbook of the core dataset of your interest and access the `Sources` item.

<br />

## `Using`

### How do I query a core dataset

You can find released core datasets both in Databricks and BigQuery searching for the `core` namespace

### How I can start using a core dataset in my own dataset

Core datasets can be used the same way you would use a normal dataset as an input in your SparkOp

<br />

## `Contributing`

### What is the process of creating a core dataset

The process is described [here](contribution-workflow.md).

### Can I have a regular dataset as input for a core dataset

Core datasets must use only contracts, series contracts and other core datasets as inputs.

### What can be changed in an existing core dataset

Changes made to core datasets are made in the following way:

- If a column has a transformation logic that does not satisfy or does not correspond to a squad specific concept or business logic, a new column must be created instead of changing the current one, with exception of clear bug fixes.

- If the granularity of a core dataset does not satisfy a squad's specific need, a new core dataset should be created instead of changing the current one.

Given that, we highly recommend that if your squad has a need to make a transformation on a core dataset, instead of creating a dataset to do that on your squad only, contribute to the core dataset. This will help for all Nubankers to have access to information on a concentrated, stable, reliable and traceable way.

<br />
