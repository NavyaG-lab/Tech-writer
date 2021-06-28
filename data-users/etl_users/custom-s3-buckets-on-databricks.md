---
owner: "#data-access"
---

# Using custom S3 buckets on Databricks

## Table of Contents

  - [Background](#background)
  - [Requisites](#requisites)
  - [Overview](#overview)
  - [Caveats](#caveats)
  - [Setup](#setup)
    - [Bucket Permissions](#bucket-permissions)
    - [Data Account permissions](#data-account-permissions)
    - [Databricks](#databricks)

## Background

Databricks is used at Nubank for different things, from developing ETL datasets, to monitoring business metrics and automating processes. For most use cases, Databricks already has the necessary access to S3 buckets, but there are cases people want to use Databricks to access custom S3 buckets.

For these custom buckets, people relied on [mounting them using aws keys](https://docs.databricks.com/data/data-sources/aws/amazon-s3.html#mount-a-bucket-using-aws-keys), which allowed all users read and write access to all the objects in the mounted S3 bucket. While this process is simple and allows people to easily access buckets it poses certain risks:

- There are no user level access logs to these buckets
- Anyone on Databricks can use the mount regardless of the cluster being used. If the bucket was mounted with write credentials someone could delete the entire bucket by mistake

After [Nubank moved from AWS IAM roles to users](https://nubank.slack.com/archives/C20GTK220/p1623443610111000), the existing mounts using aws keys stopped working. Databricks also doesn't support mounting buckets using the IAM role keys. To continue accessing these custom buckets on Databricks users have the following options:

- Move the data to one of the supported buckets, like `s3://nu-tmp` or `s3://nu-data-br`. **Important**: Only do this if the data is not sensitive or PII.
- Move the data to the ETL as a [Manual Dataset Series](manual_dataset_series.md)
- Use Kubeflow
- Use Single User clusters

This document will focus on the last option, and the necessary steps to make it work.

## Requisites

Before going any further make sure you have:

- A working SU cluster. If you don't have one ask on #data-help that you need one in order to access a custom S3 bucket.
- A data account IAM role. If you don't have one ask on [this Jira form](https://nubank.atlassian.net/servicedesk/customer/portal/53/group/241/create/880)
- A data account IAM role that's part of the `databricks-general` group. If you are not in this group ask on [this Jira form](https://nubank.atlassian.net/servicedesk/customer/portal/53/group/241/create/882)
- For Nubank owned custom buckets:
    - The ability to sign commits on GitHub (verified tag). Check the [documentation](https://docs.github.com/en/github/authenticating-to-github/managing-commit-signature-verification) on how to configure it.
    - Be part of the `prod-eng` IAM group. Ask for permission on #tribe-infosec that you need this permission to sync bucket policies.

## Overview

The solution involves using a Single User cluster on Databricks to access the custom buckets. Single User clusters allow Databricks to assume the Nubanker's IAM role in the Data Account. This allows us to grant Nubankers granular permissions without touching Databricks infrastructure and settings.

By granting access to the bucket to the Nubanker's Data Account IAM role, the Single User cluster will be able to access data from any bucket as long as the Nubanker has access to it.

## Caveats

The solution detailed bellow will only work for commands that accept full s3 paths instead of mounts. Some examples of supported commands:

- Reading files from S3 into Spark/Pandas DataFrames
- Writing Spark/Pandas DataFrames to S3

Non supported commands:

- Installing internal python packages from mounts. To install python packages you'll need to move the files to `/mnt/nu-tmp/` or [make the package available in Nubank's PyPi](https://github.com/nubank/playbooks/blob/master/data-science/guides/python-projects/README.md)
- Opening files like there were from the local file system, like Python's `open()` command. For a workaround check [this notebook](https://nubank.cloud.databricks.com/#notebook/11642152/command/11642244)


## Setup

### Bucket Permissions

If the custom bucket is owned by Nubank, a PR on [iam-policies](https://github.com/nubank/iam-policies) will need to be created. The PR will have two main aspects:

1. Allow the Data Account, account number `877163210394`, to access the bucket
1. An inline policy or group that grants access to the bucket
1. **Optional**: If you want to access the data written by Databricks outside of Databricks you will need make sure that Databricks is writing files to the custom bucket using the `bucket-owner-full-control` canned ACL. To make sure Databricks is writing data with this flag you can reject uploads without the ACL.
1. **Optional**: If you want for the files written by Databricks to be owned by the bucket owner, to enforce uniform object ownership across all files, you'll will need to change the bucket settings via a [lambda function](https://github.com/nubank/iam-policies/blob/master/bucket-ownership-controls.edn)

The choice between inline policy or group depends on the access patterns of the bucket. If people need only temporary permissions on Databricks prefer using inline policies, as those are automatically revoked after a certain amount of time. If people need permanent access to the bucket consider using groups.

If the bucket is not owned by Nubank, you'll need to implement bucket policies similar to the one below on the AWS account that owns the bucket.


#### Example

This is an example of the necessary files to support reading and writting to the `nu-risk-br` bucket

##### Step 1

This bucket policy grants both the BR and the DATA account read, write and delete permissions on the nu-risk-br bucket.

```
{
  "Version": "2012-10-17",
  "Id": "NuRiskBrPolicyDatabricks",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::103528554969:root",
          "arn:aws:iam::877163210394:root"
        ]
      },
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:GetObjectAcl"
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nu-risk-br/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::103528554969:root",
          "arn:aws:iam::877163210394:root"
        ]
      },
      "Action": [
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "arn:aws:s3:::nu-risk-br"
    }  
  ]
}
```
It's important that the Data Account, account number `877163210394`, has the right permissions. Depending on your bucket requirements, like versioning, you might need to grant extra permissions. For a full list of actions check the [AWS documentation](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazons3.html)

##### Step 2

IAM Group

This grants members of the risk-management group read and write permissions to the nu-risk-br bucket:


```
{
  "PolicyName": "risk-management",
  "Description": "risk-management",
  "PolicyDocument": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ],
        "Resource": [
          "arn:aws:s3:::nu-risk-br"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        "Resource": [
          "arn:aws:s3:::nu-risk-br/*"
        ]
      }    
    ]
  }
}
```

Inline Policy. This grants roles with this policy attached read and write permissions to the nu-risk-br bucket:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
     "Action": [
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": [
        "arn:aws:s3:::nu-risk-br"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::nu-risk-br/*"
      ]
    }    
  ]
}
```
**Important**: The file path where the policy is written will affect who's able to grant it.
If the policy is written at `inline-policies/<squad-name>/policy.json`, only members of the squad's IAM group and the `permissions-admin` group will be able to grant this policy. To find out the IAM group for a certain squad look at [iam_policies/ownership/squads.clj](https://github.com/nubank/iam-policies/blob/master/src/iam_policies/ownership/squads.clj#L3)

##### Step 3 (Optional)

The following condition needs to be added to the bucket policy:

```
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::877163210394:root"
  },
  "Action": [
    "s3:PutObject",
    "s3:PutObjectAcl"
  ],
  "Condition": {
    "StringEquals": {
      "s3:x-amz-acl": "bucket-owner-full-control"
    }
  },
  "Resource": "arn:aws:s3:::nu-risk-br/*"
}
```

This means that the Data Account will only get permissions to write objects in the nu-risk-br bucket in case it gives ownership of the object to the bucket owner. Following the previous example, the rest of the bucket policy will need to be changed to remove the previous permission from the Data Account. The final policy will look like:

```
{
  "Version": "2012-10-17",
  "Id": "NuRiskBrPolicyDatabricks",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::103528554969:root",
          "arn:aws:iam::877163210394:root"
        ]
      },
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:GetObjectAcl"
        "s3:ListMultipartUploadParts"
      ],
      "Resource": "arn:aws:s3:::nu-risk-br/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::103528554969:root",
          "arn:aws:iam::877163210394:root"
        ]
      },
      "Action": [
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "arn:aws:s3:::nu-risk-br"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::877163210394:root"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      },
      "Resource": "arn:aws:s3:::nu-risk-br/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::103528554969:root"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nu-risk-br/*"
    }
  ]
}

```

##### Step 4 (Optional)

Add the bucket to [this list](thttps://github.com/nubank/iam-policies/blob/master/bucket-ownership-controls.edn). After the PR is merged, request #ds-productivity permissions to run the following command:

`nu serverless invoke bucket_obj_ownership --account-alias <ACCOUNT-ALIAS> --env prod --invoke-type sync --payload '{"bucket-name":"<BUCKET-NAME>"}'`

The `BUCKET-NAME` parameter should ommit the `s3://` prefix.

These are the account aliases for each account:

- Brazil account: `br`
- Mexico account: `mx`
- Colombia account: `co`
- Data account: `data`

### Data Account permissions

The next step is to grant the Data Account IAM role the necessary permissions to access the custom bucket. How the access is given depends on how the permissions were created in the Bucket Permissions section.

#### Group 

Ask on [Jira](https://nubank.atlassian.net/servicedesk/customer/portal/53/group/241/create/882) for your Data role to be added to the group.

#### Inline policy

Find out someone that's a permission admin on the Data Account (`nu-data sec iam show group permissions-admin`) and also part of the squad that owns the inline policy [according to its path](https://github.com/nubank/iam-policies/blob/master/src/iam_policies/ownership/squads.clj#L3)

Assuming that the:

- The squad that owns the policy is called `cool-squad`
- The Nubanker that needs the permission has a AWS role called `name.surname`
- The inline policy file is called `cool-policy.json`
- The Nubanker needs this access for 5 days

The permissions admin will need to run `nu-data iam allow name.surname generic cool-squad cool-policy --account-alias data --until=5days`

### Databricks

Attach a notebook to the Single User cluster and run `dbutils.credentials.showRoles()` in a notebook cell. The output should show: `arn:aws:iam::877163210394:role/name.surname-data-role`, where `name.surname` is the Nubanker's name. If this doesn't show up ask for help in #data-help with the :data-access-ticket: custom emoji.

Assume the personal data role by running `dbutils.credentials.assumeRole("arn:aws:iam::877163210394:role/name.surname-data-role")`, `name.surname` is the Nubanker's name.

After this step, access to the custom bucket should work.

To schedule jobs using these credentials check [this documentation](https://docs.google.com/document/d/1cXhBKDGzUpnGEkboDrSVHeYWbsvms6fHoRH8zxYzMBQ/edit#heading=h.o97s9bc0vr3y).

#### Writing files

If you are writing files from Databricks and desire to access these files outside of Databricks you'll need to pass the `bucket-owner-full-control` ACL flag everytime you write files. For Spark commands such as `sparkDataFrame.write.parquet("s3://custom-bucket/path/")` nothing needs to be done, as at the time Single User clusters are created, this is configured as a Spark setting. 

If you are not using Spark to interact with S3 you'll need to change your writing functions to pass this flag. You can do this by using the [boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html?highlight=put#S3.Object.put) python library with `acl="bucket-owner-full-control"`

If one of the alternatives above work you'll need to change the file ACL after it has been written. You can do this by running the following command on Databricks to change the ACL of a single file:

```
%sh
aws s3api put-object-acl --bucket <custom-bucket> --key <file-path> --acl bucket-owner-full-control
```

If you have written a lot of files it's also possible to bulk change the ACLs for a given S3 path.

```
%sh
aws s3 cp --recursive --acl bucket-owner-full-control s3://<custom-bucket>/<folder-path> s3://<custom-bucket>/<folder-path> --metadata-directive REPLACE
```
Note: This command might be slow to run depending on the number of files and their size, as this command needs to move data.
