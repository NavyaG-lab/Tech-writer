---
owner: "#squad-analytics-productivity"
---

# Contribution Workflow

## How to create a core dataset
> The general workflow for contributing to Itaipu can be found [here](https://data-platform-docs.nubank.com.br/how-tos/itaipu/workflow/). The
following workflow has complementary information specific to core datasets.

In order to maintain the quality and reliability of the data on the core namespace, some additional steps are required (compared to contributing to a normal dataset at Itaipu).

All core datasets should follow a release processes of: <br />

* **Alpha Release**
  - In this phase, the dataset is blocked from having other datasets depending on it in Itaipu. Also, the dataset shouldn't be available on BigQuery/Looker, only being accessible through Databricks
  - This step is useful to check the logic and to share between stakeholders, guaranteeing agreement on definitions.
* **General Release**
  - In this phase, the core dataset is mature and ready for production. It has good documentation, monitoring and reliable data.
  - As soon as a core dataset reaches the general release, no breaking change should be introduced (modifications on existing columns or grain changes)

## Checklist

In order to have your PR merged on the core namespace, you should follow this checklist:

**Alpha Release**
- [ ] Core dataset candidate only depends on contracts/other core datasets
- [ ] No core dataset with the same grain <sup>1</sup>
- [ ] At least 2 teammate reviews, preferably from the dataset stakeholders
- [ ] At least 1 review from the Analytics Productivity Squad
- [ ] Defined owner squad
- [ ] Dataset is blocked from being used as input in Itaipu
- [ ] Dataset is NOT loaded into Data Warehouse (BigQuery)

**General Release**
- [ ] Core dataset candidate only depends on contracts/other core datasets
- [ ] No core dataset with the same grain <sup>1</sup>
- [ ] Dataset documentation updated (in case of modifications) / created (in case of new dataset). See [example](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/core/docs/account-requests.md)
- [ ] Monitoring in place with at least one alert (row count)
- [ ] Difference Analysis between core candidate and old dataset (in case of a core candidate replacing a old common dataset). _See [difizinho](https://github.com/nubank/difizinho)_
- [ ] Roll-out plan (in case of a core candidate replacing a old common dataset)
- [ ] At least 1 week running under Alpha namespace
- [ ] At least 2 teammate reviews, preferably from the dataset stakeholders
- [ ] At least 1 review from the Analytics Productivity Squad
- [ ] Dataset is removed from usage restriction in Itaipu
- [ ] Dataset is loaded into Data Warehouse (BigQuery)
- [ ] Column names and definitions are coherent with columns that have the same name on the core namespace

_[1] E. g.: If there is a core dataset with the grain `One row per bill__id`, you shouldn't submit a new dataset with the same grain, but rather add new columns to the existing core dataset_

Keep this checklist in your pull requests. After gathering the necessary teammate reviews, you can add the tag `-PR Core Dataset Review` in order to have a review from Analytics Productivity. Also, you can reach us in #squad-analytics-productivity in case of any doubts.

## Design Recommendations

Besides the requirements on the checklist, you should also follow this design recommendations for your core dataset:
- Add as many columns as you can. We should thrive for **denormalization** in the core namespace, meaning that you should add all columns that could be used for analysis
  - For instance, if you are joining account information with something else, bring all account related columns as well
  - Denormalization helps with query performance on ad-hoc analysis through tools such as Databricks, BigQuery and Looker. Also, it facilitates analysis hence it avoids the need of joins by the end user
- Invest time on **sanity checking** your dataset
  - Look for null values, id uniqueness, max/min of columns to guarantee your dataset makes sense. Attaching a databricks notebook with your investigation on the PR increases the chance of a successful review
  - Also, your discoveries (e. g., column A should not have any null value) could be implemented as alerts, so you guarantee the stability for the future
- Seek **agreement** between stakeholders
  - More often than not, we have things with the same name but different meanings in Nubank. One of the objects of the core namespace is to have canonical definitions for company-wide metrics
  - Always make sure that the column names and definitions of your dataset are coherent with columns that have the same name on the core namespace.
  - Try to be as specific as you can in column names. E. g., if you have a "transaction" column for debit card, name it `debit_transaction` instead of just `transaction`
  - Raise awareness about the core dataset you are building so stakeholders get involved. Seek consensus and when it's not possible, name things differently so they represent their difference in meaning
