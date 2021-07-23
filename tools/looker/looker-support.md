---
owner: "#data-access"
---

# Looker Support

Looker is a BI Tool that Data Access maintains and provides support. The main areas of support of Looker are:

## General Support

Data Access is the one who is responsible for Looker's stability. In case a user has problems using the tool we should provide the first level support. Some examples of these cases are:

- People can't schedule dashboards even with the right permissions
- People can't use SQL Runner even with the right permissions
- Looker throws `Internal Server Error` when trying to deploy LookML
- Looker internal dashboards throw invalid SQL errors
- People want to try out a new Looker feature that must be enabled by Admins beforehand

For cases that are not related to access, that we don't know how to proceed, or that are more generic questions, we can:

- Point the user to the specific [Looker documentation](https://docs.looker.com/)
- Enter in contact with Looker support ourselves for instance wide problems
- Help the user enter in contact with [Looker support](https://help.looker.com/hc/en-us/articles/360025685933-Looker-Support-Details)
- For SQL Runner 2.2 questions enter contact with Looker through our [Slack channel](https://sqlrunner.slack.com)

## Access

People need access to Looker in order to use it. Due to third parties using Looker and budget restrictions we cannot create users or open the tool for anyone.

We have a [lambda](https://github.com/nubank/lambda-automation/tree/master/python/lambdas/looker-user) that [runs periodically](https://github.com/nubank/definition/blob/master/resources/br/tasks/batch-looker-user-lambda.edn) giving people access based on some rules:

- People in [google groups](https://github.com/nubank/lambda-automation/blob/master/python/lambdas/looker-user/config.yml#L9)
- [Xpeers](https://github.com/nubank/lambda-automation/blob/56b3ae009080d1435f2bd1bca51d4fdc2023143e/python/lambdas/looker-user/looker.py#L76)

Those that are not covered by this lambda must ask this access on [#access-request](https://nu-itops.atlassian.net/servicedesk/customer/portal/5). ITOps takes care of this process and what they do is run the same lambda but for single user only. The lambda will add people to the `Basic User` group with the exception of Xpeers, that are subject to the same rules as defined above.

In case the person still doesn't have access after going to #access-request, Data Access will have to manually intervene. These are the most common requests and how to proceed:

### Xpeers

Due to budget restrictions on Looker, and the amount of people on this chapter, we give Viewer Licenses to certain people and Developer Licenses to others. The Viewer Licenses are cheaper and allow people to only view Dashboards.

This logic is based on the Xpeer level, but there are cases when this doesn't work:

- A person changes level
- A new Xpeer level is created and it [isn't on Proximo](https://github.com/nubank/proximo/blob/2d16ed90a8c03e73ba48aa5d31e8aedd7f3c6915/src/proximo/models/actor.clj#L104)
- A person doesn't have their level information on Proximo
- A person is an exception to the Viewer User rule

These cases require manual intervention. The `looker-xpeer-basic-user@nubank.com.br` was created for these cases. People that are added to this group automatically are added to the `Basic User`.
XManagers have the permission to add people to this group and Data Access should redirect Xpeers with this situation to them (they should know how to get in touch with their respective XManagers).

### Third Parties and BPOs

Nubank hires contractors to perform certain tasks, and these contractors have access to Looker in order to check their own performance.
In order for them not be able to see the data that's not related to their own work Data Access created separated Looker models for these use cases:

- [Third Party](https://nubank.looker.com/projects/third_party/files/README.md): People that perform tasks for the Collections squad
- [BPOs](https://nubank.looker.com/projects/bpo/files/bpo.model.lkml): These are contractors that help Xpeers with customer support

The contractors access to these models is controlled by the Looker Lambda. For Nubankers that need to work on these models we have these settings:

- Third Party: People in the `Basic User` group on Looker have edit permissions on this model
- BPOs: People on the `BPOs Management` group on Looker have edit permission on this model. People on the `bpo-managers@nubank.com.br` google group are added to the Looker group through the lambda.

For Third Parties there's usually no need to give access to people since most of them are already on the `Basic User` group. For BPOs the Spacecrafters squad has manage permissions on the google group and access can be granted through [this jira form](https://nubank.atlassian.net/servicedesk/customer/portal/86/group/515/create/1770).

### Permission to view Dashboards

The default setting for Nubankers is for them to be allowed to view any dashboard. In case someone doesn't have permission, it could be due to:

- The dashboard owner has selected to grant permission to a subset of Nubankers
- The dashboard was built on a [Looker Model](https://docs.looker.com/data-modeling/getting-started/how-project-works#parts_of_a_project) that's not the default one. Examples: BPOs, Internal Audit, BigQuery Audit.

In this case the person should reach out to the Dashboard owner and ask them to give permission to the person. In case that doesn't work Data Access needs to grant further permissions. These permissions can be:

- Access to view or edit a different Looker model
- Access to a folder that has restricted permissions
- The user must have a specific [UserAttribute](https://docs.looker.com/admin-options/settings/user-attributes) set to properly view the dashboard

There's a [playbook](https://github.com/nubank/playbooks/blob/master/squads/data-access/looker/common_tasks.md#user-doesnt-have-access-to-a-specific-explore-or-dashboard) on how to proceed in these cases.

### Permission to schedule Dashboards

This permission is granted only to people on the `Power User` group. Before giving the user access to this group, ask the person if someone in their squad is from the following chapters:

- Business Analyst
- Business Architect
- Data Analyst
- Product Manager

If there are no people from these chapters in the person's squad, then add the person to the `Power User` group.

ps: For the current list of chapters on the `Power User` group, check the [lambda configuration](https://github.com/nubank/lambda-automation/blob/master/python/lambdas/looker-user/config.yml).
