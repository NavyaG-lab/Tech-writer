# Runbook

- [How to provision new clusters](#How-to-provision-new-clusters)
   - [Troubleshooting](#Troubleshooting) 
- [How to enable IAM passthrough for a new country?](#How-to-enable-IAM-passthrough-for-a-new-country)
- [How to add new bucket permissions?](#How-to-add-new-bucket-permissions)
- [How to create a lambda to evolve the environment?](#How-to-create-a-lambda-to-evolve-the-environment)

---

## How to provision new clusters
This notebook covers everything related to provisioning and administering single user cluster: [SU creation notebook](https://nubank.cloud.databricks.com/#notebook/5445086)

For more options and applying changes in groups refer to this notebook: [SU options notebook](https://nubank.cloud.databricks.com/#notebook/5222538/)

### Troubleshooting

#### A cluster was created with the wrong options

If any kind of option was wrong at the cluster creation, manually delete the cluster and create the cluster again. 

#### A user already has a SU cluster and requested PII access again

The notebook already has a check in place preventing multiple clusters for the same person. In this case tag the person who requested the access on [#help-databricks-su-clusters](https://nubank.slack.com/archives/C016QUF63JB) and paste this message:
>
>Hello @person-slack-handle
>
>Your single user cluster already has access to PII data. In case you are having problems please check:
>
>- Check on the Jira support ticket if the period you requested for PII access hasn't expired
>- If that's not the problem run `dbutils.credentials.showRoles()` on a notebook of your SU cluster and post the results on this thread.



## How to enable IAM passthrough for a new country?

1. Create the general and PII policies inside iam-policies repo that will contain the bucket access permissions. For example - [this](https://github.com/nubank/iam-policies/blob/master/groups/databricks-br-pii.json) and [this](https://github.com/nubank/iam-policies/blob/master/groups/databricks-br-general.json)
The policies are additive in nature so keep no overlap between general and pii policies.
2. Create the roles by running [this lambda](https://github.com/nubank/okta-aws/blob/master/src/okta_aws/databricks/create_role.clj): 
```shell
nu serverless invoke okta-aws-databricks-create-role --invoke-type sync --payload-path edn-path
```
Payload containing the edn:
```edn
{
  :role-name "prod-[general/pii]-[country]"
}
```
Follow the naming convention - `databricks-federated-prod-[general/pii]-[country]-role`

3. Attach the policies to the roles by running this lambda: 
```shell
nu serverless invoke okta-aws-databricks-attach-policy --invoke-type sync --payload-path edn-path
```

Payload containing the edn:
```edn
{
  :role-name "prod-[general/pii]-[country]"
  :policy-name "[policy-name-as-in-step-one]"
}
```

Databricks-general is the base policy that should be attached to each role. For example, see [here](https://console.aws.amazon.com/iam/home?region=sa-east-1#/roles/databricks-federated-prod-pii-br-role) and [here](https://console.aws.amazon.com/iam/home?region=sa-east-1#/roles/databricks-federated-prod-pii-mx-role).

4. Reach out to ITOps to create an Okta group where the PII users from the new country will be added. The general access is assumed based on the User's okta profile and requires no setup.
5. Update the Okta expression [here](https://nubank-admin.okta.com/admin/app/databricks/instance/0oa1ihag8m5EU9dRf0h8/#tab-signon) (under Attributes) to include the PII rolename if the user belongs to the Okta group. For more help on writing the expression refer to the [okta documentation](https://developer.okta.com/docs/reference/okta-expression-language/).

## How to add new bucket permissions?

1. Update the policies in iam-polcies repo.
2. Invoke the lambda to update the roles that contain the changed policy. We use inline policies in AWS for automated roles that is why the lambda has to be run for each of the roles.
```shell
nu serverless invoke okta-aws-databricks-attach-policy --invoke-type sync --payload-path edn-path
```


## How to create a lambda to evolve the environment?

Any changes we need to make outside of what we created (AWS IAM roles, attaching policies and configuring the IdP) will need a new lambda for its own purpose.

We created lambdas here: https://github.com/nubank/okta-aws
But we could have our own lambda repository for this part of the domain in future.

To deploy the changes you have to ensure that the pipeline of your lambda with the name - `lambda_okta_aws_[lambda-name]` has been successfully run. For anything more related to debugging your lambda, find your lambda inside AWS Lambda and check the runtime logs.


https://github.com/nubank/playbooks/blob/master/docs/clojure-lambdas/creating-a-clojure-lambda.md

