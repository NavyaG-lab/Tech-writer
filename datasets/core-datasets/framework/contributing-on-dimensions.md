---
owner: "#squad-analytics-productivity"
---

# Contributing on Existing Core Dimensions

## When should I add a new attribute to a core dimension?

Core datasets are meant to be a stable, reliable and traceable source of data for the company. We want to avoid data that is too specific to a squad context, instead adding data which definition is agreed upon multiple stakeholders and add value across the company.

Because of that, is important that before adding an attribute to a core dimension, you need to make sure that you reached squads interested on that information and that the proposed attribute is a product of discussion and agreement. You can reach #squad-analytics-productivity if you need help on how to conduct this step.

## What are the guidelines to contribute with attributes?
The guidelines for contributing with new attributes are the same as the ones to contribute with a new core dataset, that you can check [here](contribution-workflow.md)

Here is an adapted version of the checklist, considering the contribution on an already released dimension, considering the tasks that you should complete when adding an attribute:

- [ ] Core dataset candidate only depends on contracts, dataset series or other core datasets
- [ ] Playbook with dataset details updated (in case of modifications) / created (in case of new dataset). 
- [ ] At least 2 teammate reviews, preferably from the dataset stakeholders
- [ ] At least 1 review from the Analytics Productivity Squad
- [ ] Column names and definitions are coherent with columns that have the same name on the core namespace

The [design recomendations](contribution-workflow.md#design-recommendations) defined on the contribution workflow document also apply here

## How attributes are added on dimensions?
Dimensions on the core namespace are built using the **iglu** framework. You can read more about how it works [here](https://github.com/nubank/itaipu/blob/master/iglu/README.md)

That means that, in order to add a column on the dimensional snapshots, you need to create a **resolver**

#### What is a resolver?
A resolver is similar to a SparkOp, in the sense that it is an object that has `inputs` and `definition`. All resolvers output DataFrames in the `EAVT` format, that is latter used to build the current and daily snapshot tables from the dimensions.

The guide on how to implement a new resolver can be found [here](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/inuit/docs/GUIDE.md#adding-an-attribute-to-an-existing-dimension).
