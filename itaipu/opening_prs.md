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


* <b>-PR Changes Requested</b>
    * Description: Someone requested for changes
    * When to add:
        * "Request changes" In the review; or
        * Comment asking for changes
    * When to remove:
        * When the person who chose "Request changes" approved; and
        * Comments were addressed
    * Who should add:
        * Anyone

* <b>-PR Hold</b>
    * Description: Don't merge the PR
    * When to add:
        * There are blockers 
    * When to remove:
        * There are no blockers
    * Who should add:
        * Anyone

* <b>-PR Old</b>
    * Description: PR is some days old
    * When to add:
        * Nothing happens in the PR for many days
    * When to remove:
        * Activity is restored in the PR
    * Who should add:
        * Maintainers

* <b>-PR Ready For Merge</b>
    * Description: PR is ready to be merged by the maintainers 
    * When to add:
        * PR is approved by the maintainers and possibly by teammates; and
        * Tests pass; and
        * There are no blockers; and
        * No more changes are going to be made
    * When to remove:
        * To replace with another label, but this should be an exception.
    * Who should add:
        * Anyone

* <b>-PR Review Requested</b>
    * Description: PR needs reviewing
    * When to add:
        * No more changes;
        * Tests pass
    * When to remove:
        * PR approved or changes requested;
        * Update with master makes tests fail or create merge conflict
    * Who should add:
        * Commiter

* <b>-PR Teammate Review Requested</b>
    * Description: PR needs reviewing by teammate
    * When to add:
        * 
    * When to remove:
        * 
    * Who should add:
        * Anyone

* <b>-PR WIP</b>
    * Description: Work in progress
    * When to add:
        * Tests are not passing; or
        * There are conflicts with master; or
        * Changes are still being made
    * When to remove:
        * No more changes; and
        * Tests pass
    * Who should add:
        * Commiter

### Label workflow

1. -PR WIP
2. -PR Review Requested
    * -PR Ready For Merge; or
    * -PR Changes Requested → -PR Ready For Merge

In addition to the labels above, use -PR Hold and/or -PR Old when necessary.

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

## Opening a Github Pull Request

* Follow instructions in the [PR Template](https://github.com/nubank/itaipu/blob/master/.github/PULL_REQUEST_TEMPLATE.md)

