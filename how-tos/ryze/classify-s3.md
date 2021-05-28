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
- `:category` - in order to better understand the use of the bucket and be able to handle the access and deletion of data in the bucket, we have defined some categories: **:ad-hoc, :backup, :etl, :infra, :log, :machine-learning, :metric, :secrets, :service, :site and :thrid-party-sharing** - [for more details](#bucket-categories)
- `:squad` - the squad who owns the bucket
- `:metadata :services` - contains the services that use given bucket. Services are the ones defined in [definition](https://github.com/nubank/definition/tree/master/resources/br/services)
- `:countries` - countries that uses the bucket - **accounts that are worldwide does not belong to a specific country. By default all the countries will be shown here, and you should remove or add countries based on your usage**
- `:accounts-alias` - the account alias where the bucket was created
- `:validated` - define if someone has validated all the information from the bucket
- `:paths` - One bucket may store data with different use cases. To enhance the usage of a bucket, you are allowed to define the use cases based on the path
  - `:path` - path inside the bucket
    - `:description` - description about the data is being stored
    - `:compliance :tags` - the classification itself, what kind of data (tags) we have, tags are defined for each country and you can find the tags for Brazil at https://github.com/nubank/ryze/blob/master/resources/br/compliance/tags.edn.

### Bucket categories

In order to be compliant with data protection laws, we must have a data inventory. We also need to provide some rights to the customers/prospects over their personal data, for instance, access to their data and deletion. Because S3 may store both structured and unstructured data, and Nubank has different use cases, we could not define a single solution to provide access and deletion for all the buckets. Therefore, we decided to break into different categories so that we could have a different solution for each one. 
We also want to use some tool to analyse bucket's content and look for personal/sensitive data. However, as the tools are of high cost and depends on the amount of data analysed, we chose to use categories that help us configure frequency and depth for analysis better.

Current categories:
- `:backup` - buckets used for backup
- `:etl` - buckets used by data-infra on our ETL/data lake
- `:infra` - buckets that store data related to infrastructure
- `:log` - buckets where we store logs
- `:machine-learning` - buckets used by machine learning engineers to train models
- `:metric` - buckets where we store metrics
- `:secrets` - buckets used to store secrets
- `:service` - buckets that belongs to a service, and knows how to write and read
- `:site` - buckets for sites
- `:third-party-sharing` - buckets used for sharing/exchanging data with third-parties
- `:ad-hoc` - other cases like buckets owned by squad to store/share some data in the squad

When we talk about deletion for the `:service` category, we will delegate the responsibility to the owner of the service and for the `:etl` category, data-infra has provided some solutions already.

We may have different cases that are tricky, and we have some samples that may help yours:

- [ryze's buckets](https://github.com/nubank/ryze/blob/master/resources/accounts/br/s3/nu-ryze-br-prod/classification.edn) (the repository that you are working on) that contains our data inventory and `ryze` is responsible to write in this bucket and `thresh` just reads from it, and these buckets are in the `:service` category.
- nu-morpheus stores data that comes from `etl` and it has a service (`morpheus`), which does not belongs to `data-infra` (has it own business). Since nu-morpheus has a service that may store it's own data, the category would be service `:service`.

## What should be done?

So far, Nubank has not much control over the use of S3. We do not have a predefined way to create buckets or an easy way to know the bucket owner or the use cases for them. We have tried to use some sources like `definition` and IAM-policies to automatically fulfill the required information related to the bucket. However, we do not have all the information required, and we may have some errors. So we need people that own the bucket to help us check and fulfill them.

Please, double-check all information, and once everything is correct, update `:validated` to `true`.

In `:paths`, we may have different use cases; it would be good to have a path here for each of them. If there is just one use case, keep the default `"*"`.

### Tags

Tags that are used in `:paths :compliance :tags` may have [personal data](../data-deletion/pii_and_personal_data.md) or some information we must add in our [data access report](https://honey.is/home/#post/849562).

We have a file that contains all available tags in each country([BR](https://github.com/nubank/ryze/blob/master/resources/br/compliance/tags.edn), [CO](https://github.com/nubank/ryze/blob/master/resources/co/compliance/tags.edn) and [MX](https://github.com/nubank/ryze/blob/master/resources/mx/compliance/tags.edn)). Because we do not have a good governance over s3, we may have a lot of different use cases for it. As the discussion about personal data is recent, our tags may be ambiguos (we are working on it), therefore, we have created a tag that will be validated in `s3` classification: `:unknown-pii`. If you have personal data in your bucket, but do not have a clear vision of what exists, then there you can use it (if the effort to know it is not that high, please try to use the right tags). In the future, when we change our tags, we are going to need to have the right personal data definition.

## What if the bucket is not from my squad?

We have tried to set the squad based on what was defined in iam-policies/definition, but we may have some errors. If you encounter any issues, please reach out to us at #s3-data-classification slack channel.

## What if we do not use the bucket anymore?

Currently we are not enforcing the deletion of buckets that are no longer used, but we plan to work on this in the future. If you are not using the bucket, delete it and then do not classify it. If you don't classify, then the bucket will be removed from Ryze. Incase you are not planning to delete it, please do the classification. In any case send us a message on #s3-data-classification Slack channel, so we can be aware of these cases :).

## What if I have a use case that may have a different category?

The categories were based on our current knowledge and discussions we had with some squads. If you have any special cases that require access, deletion or any security concern, please send us a message on #s3-data-classification Slack channel explaining your use case so that we can evaluate.

## What if I have a bucket with multiple categories?

If your bucket has a service that is responsible to store/read data from a bucket, then the given bucket falls under `:service` category. If your bucket stores general data from `infra` and `secret` then the given bucket falls under  `:secret` category.
If you're not finding the right category or have further questions, please send us a message on #s3-data-classification explaining your use case.

## Help
If you need some help about the classification that was not covered by the questions above, for instance "which tag should I use?", send a message on #data-classification Slack channel. 
