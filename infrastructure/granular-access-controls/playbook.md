---
owner: "#data-protection"
---

# How to work with ACGs

Due to the release of Granular Access Controls (GAC), we now have fine(r) grained access controls in the analytical environment.
For example, Nubank uses GAC to subdivide its personally identifiable information ([PII](https://nubank.atlassian.net/l/c/01hcn8cD)) data into smaller chunks, thereby reducing risk of [PII exposure](https://nubank.atlassian.net/l/c/zhkUw32f).
The atomic unit of access control is called an Access Control Group (ACG).
ACGs contain datasets and Nubankers can request access to them individually.

Your squad can use GAC to restrict access to any kind of dataset, not only PII data.
Check out the section on 'Use cases' below for details.
The goal of this document is to show all the steps necessary to restrict access to a non-PII dataset.

GAC uses AWS' IAM system to manage access.
To get access to an ACG, is to be granted an IAM policy to your AWS data account role.
For more information about the architecture, go [here](/infrastructure/granular-access-controls/index/).

## Use cases

- 'Chinese Wall' information barrier within an organization to prevent exchanges or communication that could lead to conflicts of interest.

## Current limitations
- A dataset can be part of at most one ACG.
- ACG name changes are not graceful: everyone with access to the old name needs to request access again for the new name.
  Get in touch with Privacy Tech squad to coordinate this if necessary.

## Instructions

The steps to create a new ACG or to update an existing one are equal, except for the first step.
When changing an existing ACG, instead of creating a new object in step 1.i, you change the name of it.
Alternatively, if you start using an ACG that hasn't been used before, begin with the 'Gaining access to the ACG' section.

!!! info "Getting help"
  Please get in touch with us by creating a ticket in `#data-help` on Slack and react with `:privacy-tech-ticket:` when you're planning to make changes to ACGs so we can support you with the steps below.
!!!

1. Preparing the dataset
    1. Create a new object in [this file](https://github.com/nubank/itaipu/blob/eb8a6f63a20377dc28027e0384d0facd588056ca/subprojects/contrib/access-control-metadata/src/main/scala/access_control_metadata/AccessControlGroup.scala#L1), name it however you want.
    1. Link the ACG to your dataset ([example](https://github.com/nubank/itaipu/blob/eb8a6f63a20377dc28027e0384d0facd588056ca/subprojects/contrib/kpitao-planeta/src/main/scala/nubank/kpitao_planeta/infra/ops/KPIsModels.scala#L24)).
    1. As of writing, GAC is not implemented on BigQuery yet.\
    If you don't want your ACG restricted data to go to BigQuery and be visible by (legacy) blanket PII access, be sure to set the [`WarehouseMode`](https://github.com/nubank/itaipu/blob/f5eec8594afa993b2ac31ea2b822cbbbc15c397b/common-etl/src/main/scala/common_etl/operator/WarehouseMode.scala#L20-L21) to `NotUsed`.
    1. Also, set up a [`DatasetUsage`](https://github.com/nubank/itaipu/blob/f5eec8594afa993b2ac31ea2b822cbbbc15c397b/src/it/scala/etl/itaipu/dataset_usage/DatasetUsage.scala#L71) to avoid downstream datasets from using yours as an input.\
    Currently, ACGs do not automatically prevent this from happening.
1. Gaining access to the ACG
    1. Add your ACG to the [ACG allowlist](https://github.com/nubank/itaipu/blob/eb8a6f63a20377dc28027e0384d0facd588056ca/subprojects/contrib/access-control-metadata/src/main/scala/access_control_metadata/IAMPolicyGenerator.scala#L17).
    (TODO GAC team: move allowlist to a separate file to avoid frequent git hash changes affecting all the ACG policies).
    1. Generate the IAM policies by running `sbt access-control-metadata/run` within itaipu's working directory.\
    This will generate the files in the `iam-policies` repo, so make sure you have a branch there and it's up to date.
    1. Open a PR in https://github.com/nubank/iam-policies.
    1. Privacy Tech needs to update the list with ACGs in Jiraya to make your ACG show up in the Slack request flow.\
    Get in touch with us for this (see instructions above).
    1. Once the Jiraya list is updated, request access in #acg-access-request on Slack.
