---
owner: "#data-access"
---

# How to add a new S3 path to be accessible by Databricks

Before you add this bucket access to S3, you need to be sure that presence of this bucket in Databricks is really necessary. If this access is for one-time use only you should consider moving your data to nu-tmp bucket. If this data is a recurring requirement, then this data should exist on the ETL if possible.

Another important thing is to know whether the S3 path that you're adding contains any PII data. [Here](https://data-platform-docs.nubank.com.br/data-users/FAQs/pii-data/#what-is-considered-as-pii-and-personal-data) you can find what is PII data or not.

Follow the following steps:

1. For each bucket that needs to be accessed, you need to have a bucket policy on the [iam-policies repository](https://github.com/nubank/iam-policies). Allow the Databricks root account id `arn:aws:iam::552767473918:root` to be able to perform only the necessary S3 operations. [Example PR](https://github.com/nubank/iam-policies/pull/6269). In case there's no bucket policy for that bucket existing you need to create one.

2. Once the PR is approved and merged, you need sync the bucket policy to the AWS account. It's a manual step and the command for this can be found on the [iam-policy repo readme](https://github.com/nubank/iam-policies#s3-bucket-policies).

3. Depending on whether your data is PII or not, you need to update databricks access policies allow the most appropriate role databricks policy to only have access to this data.

For non-pii data - [databricks-general.json](https://github.com/nubank/iam-policies/blob/master/groups/databricks-general.json)

For br-pii data - [databricks-br-pii.json](https://github.com/nubank/iam-policies/blob/master/groups/databricks-br-pii.json)

For mx-pii data - [databricks-br-pii.json](https://github.com/nubank/iam-policies/blob/master/groups/databricks-mx-pii.json)

For data scientist specific pii data -  [databricks-ww-general-ds.json](https://github.com/nubank/iam-policies/blob/master/groups/databricks-ww-general-ds.json)

For data scientist specific non-pii data - [databricks-ww-pii-ds.json](https://github.com/nubank/iam-policies/blob/master/groups/databricks-ww-pii-ds.json)

4. Once this PR is also merged, you need to logout and login from databricks and try accessing the bucket.

5. If this is a new bucket for databricks, this also needs to be mounted. Contact Data Access on #data-help channel for this.

Tip - You can create an [IAM PR Review ticket](https://nubank.atlassian.net/servicedesk/customer/portal/1) for #tribe-infosec to look into along with their support ticket.
