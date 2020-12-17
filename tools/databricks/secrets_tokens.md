---
owner: "#data-access"
---

# Using tokens inside Databricks

A secret is a key-value pair that stores secret material. This is useful to securely store a token
to be used in a Databricks notebook. Inside the notebook, the value will be used normally as a
string, but if you try to view it, you will see `'[REDACTED]'`.

## Instructions

1. Install `databricks-cli` (<https://docs.databricks.com/dev-tools/cli/index.html>). For example,
using `conda` environment:

   ```bash
   conda create -yn databricks-cli python=3.9
   conda activate databricks-cli
   python -m pip install databricks-cli
   ```

1. Generate a Databricks user token at <https://nubank.cloud.databricks.com/#setting/account>.

1. Set up `databricks-cli` authentication (<https://docs.databricks.com/dev-tools/cli/index.html#set-up-authentication>):

   ```bash
   $ databricks configure --token
   Databricks Host (should begin with https://): https://nubank.cloud.databricks.com
   Token: <insert the token from the previous step>
   ```

1. Check the current secret scopes (<https://docs.databricks.com/security/secrets/secret-scopes.html#list-secret-scopes>):

   ```bash
   databricks secrets list-scopes
   ```

1. Create a Databricks-backed secret scope (<https://docs.databricks.com/security/secrets/secret-scopes.html#create-a-databricks-backed-secret-scope>)
if you want a new one. Use the list above of current scopes to see if there is any naming convention.

   ```bash
   databricks secrets create-scope --scope <scope-name>
   ```

1. Create a secret (<https://docs.databricks.com/security/secrets/secrets.html#create-a-secret>)
using the `scope` above:

   ```bash
   databricks secrets put --scope <scope-name> --key <key-name>
   ```
   
   For example, use `<key-name>` = `github-token`.

1. Use the secrets in a Databricks notebook (<https://docs.databricks.com/security/secrets/example-secret-workflow.html#secret-example-notebook>).
For example:

   ```python
   GITHUB_TOKEN: str = dbutils.secrets.get(scope='itaipu-reviewers', key='github-token')
   ```
