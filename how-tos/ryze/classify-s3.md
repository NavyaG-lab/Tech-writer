---
owner: "#data-protection"
---

# S3 classification

 ***Abstract***:
[Ryze (inventory)](https://github.com/nubank/ryze) is a repository responsible for storing information about all data sources that Nubank uses and mainly to know where there is PII data. This guide walks you through the classification of data in S3.

## S3 structure

Ryze contains all S3 buckets from all accounts mapped. They are located in [`resources/accounts/:account/s3`](https://github.com/nubank/ryze/tree/master/resources/accounts). Each bucket has a folder named with its name, and inside it, there is a `classification.edn` containing information related to the bucket.

Full path sample: `resources/accounts/br/s3/acquisition-tribe/classification.edn`.

The `classification.edn` will look like the following samples:

```clojure
{:name           "nu-babel"
 :category       :service
 :squad          :credit-strategy
 :metadata       {:services ["nu-babel"]}
 :countries      [:br :co :mx]
 :accounts-alias :dev
 :validated      false
 :paths          [{:path        "smiles-conciliation"
                   :description "bla ble"
                   :compliance  {:tags #{:cpf}}},
                  {:path        "serasa-scores"
                   :description "bla ble"
                   :compliance  {:tags #{:cpf :name}}}
                  {:path        "boavista-scores/processed"
                   :description "bla ble"
                   :compliance  {:tags #{:cpf :score}}}
                  {:path        "*"
                   :description "bla ble"
                   :compliance  {:tags #{}}}]}
```

```clojure
{:name           "www.nu.bank"
 :category       :site
 :squad          :marketing
 :metadata       {:services []}
 :countries      [:br :co :mx]
 :accounts-alias :dev
 :validated      true
 :paths          [{:path        "*"
                   :description "bla ble"
                   :compliance  {:tags #{}}}]}
```

**Details about each key:**

- `:name` - bucket's name
- `:category` - in order to better understand the use of the bucket and be able to handle the access and deletion of data in the bucket, we have defined some categories: **:ad-hoc, :backup, :etl, :infra, :log, :machine-learning, :service and :site** - [for more details](#bucket-categories)
- `:squad` - the squad who owns the bucket
- `:metadata` - contains data related to the category, like services data in service buckets
- `:countries` - countries that uses the bucket - **accounts that are worldwide does belongs to a specific country and all the countries that uses buckets are available here**
- `:ccounts-alias` - the account alias where the bucket was created
- `:validated` - define if someone has to validate all the information from the bucket
- `:paths` - One bucket may store data with different use cases. To enhance the usage of a bucket, you are allowed to define the uses cases based on the path
  - `:path` - path inside the bucket
    - `:description` - description about the data is being stored
    - `:compliance :tags` - the classification itself, what kind of data (tags) we have, tags are defined for each country and you can find the tags for Brazil at https://github.com/nubank/ryze/blob/master/resources/br/compliance/tags.edn.

### Bucket categories

In order to be compliant with data protection laws, we must have a data inventory. We also need to provide some rights to the customers/prospects over their personal data, for instance, access to their data and deletion. Because S3 may store both structured and unstructured data, and Nubank has different use cases, we could not define a single solution to provide access and deletion for all the buckets. Therefore, we decided to break into different categories so that we could have a different solution for each one.

- `:backup` - buckets used for backup
- `:etl` - buckets used by data-infra on our ETL/data warehouse
- `:infra` - buckets that store data related to infrastructure services
- `:log` - buckets where we store logs
- `:machine-learning` - buckets used by machine learning engineers to train models
- `:service` - buckets that belongs to a service, it knows how to write and read
- `:site` - buckets for sites
- `:ad-hoc` - other cases like buckets owned by squad to store/share some data in the squad

For instance, for the `:service` category, we will delegate the responsibility to the service that owns it.
For the `:etl` category, data-infra has provided some solutions already.

## What should be do?

So far, Nubank has not much control over the use of S3. We do not have a predefined way to create buckets or an easy way to know the bucket owner or the use cases for them. We have tried to use some sources like definition and IAM-policies to automatically fulfill all information related to the bucket. However, we do not have all the information required, and we may have some errors. So we need people that own the bucket to help us to check and fulfill them.

Please, double-check all information, and once everything is correct, update `:validated` to `true`.

In `:paths`, we may have different use cases; it would be good to have a path here for each of them. If there is just one use case, keep the default `"*"`.

### Tags
Tags that are used in `:paths :compliance :tags` may have [personal data](../data-deletion/pii_and_personal_data.md) or some information we must add in our [data access report](https://honey.is/home/#post/849562).
