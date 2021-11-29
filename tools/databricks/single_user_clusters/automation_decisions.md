---
owner: "#data-access"
---
# Single-User cluster provisioning Automation

This document describes a solution for automating the part of creating
Single-User clusters and also touches briefly on other approaches. This does not include managing them afterwards.

The lambda will:

- Receives an user email as a parameter
- Fetch a secret API token from S3 for the Databricks API call
- Fetch the slack token secret for sending a slack notification
- Use the cluster default settings (JSON) from a separate file
- Call the Databricks API endpoints to:
  - Create a cluster if it does not exist
  - Change permissions
  - Warm up the cluster to install libraries
  - Shutdown
- If a cluster does exist, perform no action
- Send a slackbot message to the user with FAQ links
- Return an explicit success/failure or no action state

The reason to use the cluster default settings from a JSON file is
to simplify the process of changing it and giving an easier visibility
into how clusters are configured to people not familiar with the
internals.

We will also stop treating clusters for Data Scientists differently, so
we'll configure the same init scripts for all, to remove some complexity
when managing these clusters. A potential downside is having a slightly
bigger boot up time for clusters, but we plan on removing the need for
these init scripts anyway soon, by allowing our internal PyPI server to
be used to install internal nubank libraries.

We'll also have a nucli command, like:

> nu databricks cluster create

Which will get the username using `nu auth me` and send it as the lambda
payload. This will allow anyone to easily trigger the lambda to
provision a single-user cluster.

### Iterations

**beta**

Have a nucli command that can be run to provision a single-user cluster.

> **Pros:** People will be able to create a cluster, regardless of
> whether they have PII access or not. This solves the problem of people
> needing a cluster for other reasons (performance or isolation).
>
> **Risk:** They could also run the command for anyone else other than
> themselves, but we find this will be obscure enough and low risk to
> not be a big problem, as it doesn't have any effects in security.

**MVP**

Have the lambda be run when the access request is approved. This will
eliminate toil for Data Access, since we won't have to run the lambda
and ensures that the user is going to get a cluster as soon as the
request gets approved.

#### Other approaches considered but will not be pursued

- Daily job to create clusters based on the PII users table
  - **Pro:** Low effort
  - **Con:** There will still be a delay from access granted to cluster creation
  - **Con:** Still not covering few cases for clusters without PII access (eg. experiments)
  - **Con:** either job failing, alarms and maintenance
  - **Con:** one more job in Databricks, harder to maintain than code
- Cluster policy + guide to create clusters (no automation)
  - **Pro:** No development effort from our side
  - **Con:** We will be maintaining the documentation
  - **Con:** Much more toil for users to provision their machines
