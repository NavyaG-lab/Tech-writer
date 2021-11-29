---
owner: "#data-access"
---

# Databricks <> Okta PII sync

## Introduction

With the previous SU Cluster release in Databricks, we have hardened the authentication around PII access on Databricks. PII access on Databricks is no longer permanent. It expires based on the validity of PII request. This flow is jointly owned by #data-access, #data-protection and #squad-itops.

## Problem / Why are we doing this

We have SAML integration which syncs the user's IAM roles on Databricks (some of these roles have PII access). But this sync only happens when the users logs into their account. There is no mandate within the SAML specification that enforces the third party tools (Okta and Databricks) to do this sync periodically. Because of this Databricks doesn't always have an updated view of user roles. This is both an imminent risk and a wrong view of state.

This automation fixes this problem by syncing okta group changes on databricks. Databricks has [SCIM APIs](http://www.simplecloud.info/) in it's APIs.

For more information about the setup refer to the guide about [Meta Roles](single_user_clusters/meta-roles.md).

## How it works

This is the flow:

1. A User gets removed from a Databricks PII group
2. [This Okta workflow](https://nubank.workflows.okta.com/app/folders/6526/flows/42533) listens to these group remove events
3. The workflow maps the group to the appropriate IAM role and invokes the lambda `nu-lambda-prod-databricks-lambdas-remove-role` which removes the role form the user on databricks

To manually invoke the lambda use this nucli command:

```bash
nu-br serverless invoke databricks-lambdas-remove-role --env prod --invoke-type sync --payload payload.json
```

Payload contents:

```json
{
    "username": "fistname.lastname@nubank.com.br",
    "role": "full-role-arn"
}
```

If you are in **data-access-ops** group, you already have permission to Invoke this lambda.

## Monitoring

The lambda itself lives [here on AWS](https://sa-east-1.console.aws.amazon.com/lambda/home?region=sa-east-1#/functions/nu-lambda-prod-databricks-lambdas-remove-role?tab=configuration)

If any removal attempt fails, a message is posted on the slack channel #databricks-pii-access-sync-errors.

You can also see the [Cloudwatch logs](https://sa-east-1.console.aws.amazon.com/cloudwatch/home?region=sa-east-1#logStream:group=%252Faws%252Flambda%252Fnu-lambda-prod-databricks-lambdas-remove-role) and [Okta workflow logs](https://nubank.workflows.okta.com/app/folders/6526/flows/42533/history/) (requires admin access on Okta)
