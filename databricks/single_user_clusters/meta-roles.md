# IAM Roles in Databricks

Currently we use Okta as our Identity Provider, in which the list of IAM roles an user can assume in Databricks is configured. This list gets applied to Databricks internal state every time a user logs in via SAML. This state is used to enforce which roles can be assumed via Databricks by that user. That entire flow is handled internally by Databricks as feature on their side called "auto-sync role entitlement", inside the greater IAM Passthrough set of features.

So, whenever someone is added to an Okta group (and re-authenticates), the role will be available to be assumed inside Databricks. In case of interactive clusters, if the user has only one role then it will be assumed automatically when the first command runs.

Here is a table that shows the role and the respective Okta groups:

| role-name                                     | okta-group                        |
|-----------------------------------------------|-----------------------------------|
| databricks-federated-prod-general-br-role     | databricks-br-prod                |
| databricks-federated-prod-general-mx-rol      | databricks-pii-prod               |
| databricks-federated-prod-pii-br-role         | databricks-pii_su-br-prod         |
| databricks-federated-prod-pii-mx-role         | databricks-pii_su-mx-prod         |
| databricks-federated-prod-ds-role             | databricks-pii_ds-ww-prod         |
| databricks-federated-prod-admin-br-role       | databricks-admin_su-br-prod       |
| databricks-federated-prod-hausmeister-ww-role | databricks-hausmeister_su-ww-prod |

## Meta roles

For automated jobs, since there is no interactive element to it, and therefore no SAML flow allowing STS tokens to be assumed by the federated user, we need to use a **[meta instance profile](https://docs.databricks.com/dev-tools/api/latest/instance-profiles.html#id2)** in order to assume the underlying IAM roles, acting on the users' behalf.

The **meta role** is called: `databricks-jobs-meta-role` and lives inside `nubank-databricks` account. We also had to set it up [here](https://nubank.cloud.databricks.com/#setting/accounts/instanceProfiles) giving permissions to all users be able to use it.

The other IAM roles for data access live inside `nubank`'s prod account.

## Adding a new role

There is a [lambda](https://github.com/nubank/okta-aws/tree/master/src/okta_aws/databricks) for that! So in case we need to add another role, [check the Runbook](runbook.md#how-to-add-a-new-role).
