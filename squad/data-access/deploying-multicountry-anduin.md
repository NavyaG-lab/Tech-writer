# Deploying Anduin in a new country

Table of Contents
=================

* [GCP Setup](#gcp-setup)
  * [Create Projects for prod and staging](#create-projects-for-prod-and-staging)
  * [Setup Billing](#setup-billing)
  * [Setup Project IAM](#setup-project-iam)
  * [Setup BigQuery Datasets](#setup-bigquery-datasets)
  * [Setup Service Accounts](#setup-service-accounts)
* [AWS](#aws)
* [Itaipu](#itaipu)
* [Splunk](#splunk)
* [You're done](#youre-done)

## GCP Setup

### Create Projects for prod and staging

You can create new projects in [this page](https://console.cloud.google.com/projectcreate). This will define where the table and the data will be stored. They should be named `nu-<country-code>-streaming` and `staging-nu-<country-code>-streaming`

### Setup Billing

You can follow [these steps](https://cloud.google.com/billing/docs/how-to/modify-project) to setup billing if you are a Billing Admin. Currently, only @leonardo.matsuura and @astrid are Billing Admins, so ask them to do this step.

### Setup Project IAM

The IAM for the whole project can be setup by entering the project, clicking the hamburger menu on the top left, and going to IAM & Admin > IAM. An alternative is going into this link, but replacing `nu-br-streaming` with your desired project: https://console.cloud.google.com/iam-admin/iam?project=nu-br-streaming

- (Prod and Staging) Grant the following roles at the Project Level for data-access@nubank.com.br: BigQuery Data Editor, BigQuery Resource Admin, Private Logs Viewer, Viewer
- (Prod Only) Create the `Custom BigQuery User` Role: use [this](https://console.cloud.google.com/iam-admin/roles/details/projects%3Cnu-co-streaming%3Croles%3CCustomRole368?project=nu-co-streaming) role as base. Grant this role at the project level to everyone@nubank.com.br
- (Prod and Staging) Give Project Owner to another member of Data Access besides yourself, so if you're ever on vacation we have other people who have admin powers on the project

### Setup BigQuery Datasets

Look for the values inside the *dataset-names keys* in [Anduin's config](https://github.com/nubank/anduin/blob/master/resources/anduin_config.json.base):

- (Prod and Staging) For the `raw` dataset, set the default partition expiration the same value as days-to-data-expiration, this ensures that we delete the data after a while and comply with customers' right to be forgotten. This cannot be done through the UI. For instructions check the [docs](https://cloud.google.com/bigquery/docs/updating-datasets#partition-expiration).
  - Example using BQ cli for Mexico Prod and 7 days: `bq update --default_partition_expiration 7 nu-mx-streaming:entity_snapshot_history`
- (Prod Only) Grant the BigQuery Data Viewer Role at the dataset level:
  - `contract`: everyone@nubank.com.br
  - `contract-history`: everyone@nubank.com.br
  - `pii`: bigquery-basic-pii@nu.com.\<country-code\>
  - Other datasets: They are used only by Anduin and users shouldn't have access to them, leave them as they are.

### Setup Service Accounts

Create service accounts by entering the project, clicking the hamburger menu on the top left, and going to IAM & Admin > Service Accounts. An alternative is going into this link, but replacing `nu-br-streaming` with your desired project: https://console.cloud.google.com/iam-admin/serviceaccounts?project=nu-br-streaming
- Name: anduin-\<country-code\> for Prod, anduin-\<country-code\>-staging for staging. The service accounts should be created *in the project they will act on*.
- Create the Anduin Role: use [this](https://console.cloud.google.com/iam-admin/roles/details/projects%3Cnu-co-streaming%3Croles%3CCustomRole?project=nu-co-streaming) role as base. Grant the role to the service account at both the project level on the streaming project and on the batch project.
- Update the offboarding credentials document with the new service accounts: [example PR](https://github.com/nubank/data-access/pull/188)
- Generate json keys for the service accounts and upload them to the S3 Secrets Config path: `s3://nu-secrets-<country-code>-<env>/anduin_secret_config.json`
  - Copy and Paste the key's contents on a json that [allows the BigQuery Component to read it](https://github.com/nubank/anduin/blob/40d459a/src/anduin/components/bigquery_streaming_table_manager.clj#L48), i.e: `{"bigquery":{"credentials": <key-content>}}`
- (Prod Only) Audit Logs
  - [Create two BigQuery sinks](https://cloud.google.com/logging/docs/export/configure_export_v2#creating_sink), one for the all of the logs and one for the bigquery logs. You can use these sinks as base: [audit](https://console.cloud.google.com/logs/router/sink/projects%2Fnu-co-streaming%2Fsinks%2FEverything?project=nu-co-streaming) and [audit_bigquery](https://console.cloud.google.com/logs/router/sink/projects%2Fnu-co-streaming%2Fsinks%2FBigQueryAuditMetadata?project=nu-co-streaming)

## AWS

 - Deploy Anduin: [Example PR](https://github.com/nubank/definition/pull/13406)

## Itaipu

 - Add the serving layer dataset: [Example PR](https://github.com/nubank/itaipu/pull/19085)

## Splunk

Update Dashboards to consider new indexes by editing the Source dropdown:
 - [Data Access - Anduin Data Insertion](https://nubank.splunkcloud.com/en-US/app/search/data_access__anduin_data_insertion?form.index=main&form.prototype=&form.search=)
 - [Data Access - Anduin Views](https://nubank.splunkcloud.com/en-US/app/search/data_access__anduin_views?form.index=main&form.table_id=)

# You're done

If [barragem](https://github.com/nubank/barragem/) is up and running in the env already, the `raw` dataset should appear soon, and once the itaipu PR is done, the contracts should appear once a new transaction is run. Be aware for large amounts of lag, as anduin has to consume any messages barragem has already produced, and deadletters that may appear because of the new dbs. They can simply be replayed and will be processed normally.

