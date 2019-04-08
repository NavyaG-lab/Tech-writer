## Service Level Agreement (SLA)

Data access squad will review PRs in [itaipu](https://github.com/nubank/itapu) during business days, from 9 am until 7 pm, except on days when the squad is not in the office. Some PRs may take up to 2 business days to be reviewed. On Fridays, we will avoid merging changes that may have a negative effect in the ETL run.

If you expect to open a PR after that time, but need it to be merged on the same day, post a message on #guild-data-eng with reasonable notice (e.g., before 4 pm).

Examples of behavior you should avoid:
* Open a PR at 7:30 pm, and send a direct message or message in `#guild-data-eng` (maybe with `@here` or `@channel`), asking for an urgent review and approval, so that the PR can be merged in the same day.
    * What we expect. During the morning or early in the afternoon you post a message on `#guild-data-eng` explaining that you are working on a code change that will need to be merged on that day, and telling the reasons why you didn't do it before. When you open the PR, you can notify `@data-access` in the thread of the PR on `#guild-data-eng`.
* Messages such as:
    * "Can you merge?"
    * "It's only a small change"
    * "It's a simple PR"
    * "Please review"
    * "It's urgent”

## GitHub Labels

### Issues

0 to 4 scale of priority:
* 0 very low priority
* 1 low priority
* 2 medium priority
* 3 high priority
* 4 very high priority

### Pull Requests

Label names start with "-PR" to make the labels appear on the top of the list.

### Label workflow
1. -PR WIP
2. -PR Review Requested
    * -PR Ready For Merge; or
    * -PR Changes Requested → -PR Ready For Merge

In addition to the labels above, use -PR Hold and/or -PR Old when necessary.

## Communication

### Direct messages on Slack

Don't send.

### Slack Channels

#### Description

* `#data-access-alarms:`
    * Alarms for squad data-access: aws-cloud-watch-alarm (mordor), MetaBot, Promotion (go), Security Bot, Service cycler/scale (metabase, mordor), Tio Patinhas
    * Mostly for internal use (data-access and data-infra squads)
* `#data-announcements`:
    * Announcements about ETL runs, Mordor, Belomonte, Metabase, Databricks, etc.
* `#data-crash`:
* For issues in the ETL (failure, updates and actions taken)
* https://github.com/nubank/data-infra-docs/blob/master/squad/hausmeister.md#visibility
* `#data-help`:
    * Questions about Python, Scala, SQL, Datalog, Belomonte, Metabase, Databricks, Mordor, Spark
* `#etl-updates`:
    * Automated updates regarding the ETL pipeline
* `#guild-data-eng`:
    * Where you can ask or request about your PRs (???)
* `#guild-data-eng-prs`:
    * Mostly PRs opened and merged in GitHub repositories related to the ETL (e.g., itaipu and common-etl)
* `#guild-data-support`:
    * Specific discussions of the guild, whose interest is share knowledge related to accessing data and writing code
* `#learn-code`:
    * Announcements and requests for classes related to programming and data access
* `#squad-data-access`:
    * Squad specific discussion (dailies, OKRs, presentations, etc)
    * Ask for access to specific S3 buckets
    * Integration with GitHub repositories owned exclusively by data-access
* `#squad-data-infra`:
    * Questions, requests, comments, issues, … related specifically with data infra, such as cantareira's runtime environment and the ETL serving layer
* `#squad-di-alarms`:
    * Alarms for squad data-infra: aws-cloud-watch-alarm (Redshift), Databricks Loader, OpsGenie, Promotion (go), Service cycler (mesos-master), Splunk
    * Mostly for internal use (data-infra squad)

#### How to use

* You have a question: post on `#data-help`
* You want your PR to be reviewed and merged: wait
* You want to see if there is a problem with the ETL run: check on `#data-announcements`
* You want to see if there is any change in the ETL or in the tools: check on `#data-announcements`
* You want to check the status of the DAG (when it started to run, which datasets were computed and loaded already): check on `#etl-updates`
* You want to see if there is something wrong with the data infrastructure: check on `#data-access-alarms` and `#squad-di-alarms`
* You don't exactly a question, but want some advice, want make a comment, a suggestion, .... If you know it's related to the data access squad, post on `#squad-data-access`; if it's related to the data infra squad, post on `#squad-data-infra`; if you're not sure, post on `#squad-data-access`, and someone will redirect the message to the adequate channel.
* You want to see what the plans are for new classes: check on `#guild-data-support`
* You want to see what classes related to programming and data are being taught: check on `#learn-code`



