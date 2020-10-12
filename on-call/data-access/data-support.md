---
owner: "#data-access"
---

# Data Support

Data Support is an Opsgenie daily rotation schedule for helping support users on Data Tribe channels.

Slack channels you should monitor for questions:

- `#data-help`
- `#squad-data-access`
- `#data-announcements`
- `#help-databricks-su-clusters`
<<<<<<< HEAD:on-call/data-access/data-support.md
=======
- `#databricks-su-cluster-requests`

## Responsibilities

Over the course of the week our customers, Nubank's data users, often encounter issues while using our services. To support their effectiveness, the Data Support is responsible for communicating with these users.

The main focus of the Data Support should be on triaging user support requests to see if they are possible problems on the Data Platform and writting effective documentation for future requests. Questions on how to use the Data Platform can be answered in a best effort basis.

Things the Data Support *should* do:

- Look if user requests could be related to issues on the Data Platform and escalate the problem to the on call engineer if so
- Point users to the right documentation
- Solve user issues if they are simple enough
- Pull in the right team/person to solve non simple issues
- Improve/create documentation on common issues faced by users and how to debug or fix them

Things the Data Support *shouldn't* do:

- Help users with every kind of issue, i.e. issues outside of the Data Access scope
- Solve issues for users that are not simple
- Be the permanent solution for lack of user facing documentation
- Answer all user questions as soon as they are posted

## FAQs

Here's a list of FAQs that the Data Support can point users to:

- [BigQuery FAQ](https://docs.google.com/document/d/1_49Uk9y5Sj0W9tgkuXMJN3sovDsxLa_sf1Ujxc6E-H4/edit#heading=h.hy1tecvonb9f)
- [Looker FAQ](https://docs.google.com/document/d/1XPz-UT4IMKFnnl_b8gkplSXw-3CaecIY4wtRhNnEGTo/edit#heading=h.hy1tecvonb9f)
- [Databricks SU FAQ](https://docs.google.com/document/d/1u25N1zjsxrffLN5-Ea21tNzpKy7GBg9O36lhImRwQ_4/edit)
>>>>>>> master:squad/data-access/data-support.md

## Schedule

Data access schedules can be found [here](https://nubank.app.opsgenie.com/teams/dashboard/7dd354df-4fdf-4b26-8ae1-f4726948afe4/main).

Other way to find who is the Data Support is to use Slack Opsgenie Integration, just run the command anywhere on Slack:

`/genie whoisoncall Data Access Support`
