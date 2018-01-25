# Data-infra's Hausmeister (aka weekday ops rotation)

"Hausmeister" is the weekly Monday-Friday on-call rotation.

1. _non-work hours_ the hausmeister is on-call to ensure our services and DAG runs operate smoothly.
2. _work hours_ the hausmeister is responsible for triaging issues and customer inquiries during work hours.

_Backstop_: There should always be a secondary engineer with more ops experience backstopping the hausmeister. This is the first person the hausmeister can elevate an issue to if he/she needs assistance.

_Weekend on-call_: similar to the hausmeister role, but only responsible for being on pager duty (see below).

## responsibilities

### pager duty
Outside of work hours you should have a phone with [OpsGenie](http://opsgenie.com/) configured with you at all times. Your work-configured laptop should be readily available to address any alerts you receive from OpsGenie.

If an issue comes up that you cannot handle independently, you should escalate the alert to the backstop and pair with them to resolve the issue.

### support our clients
Over the course of the week our customers, Nubank's data scientists, often encounter platform issues while using our services.
To support their effectiveness, the hausmeister is responsible for communicating with these users; looking into their issues in a timely manner.

Slack channels you should monitor for questions:

* `#squad-data-infra`
* `#guild-data-eng`
* `#data-help`

### address open P4-P3 issues
Hausmeister should work on any open P4-P3 issues. Others should be pulled in to help with any P4 issues.

If there are no open P4-P3 issues, the hausmeister can work on tech-debt or normal work. From a resourcing perspective, they are resourced as hausmeister and nothing else during this week.

### monitoring
Monitor the normal operation of our services via

* the `#squad-di-alarms` slack channel
* the [data-infra riemann dashboard](http://prod-s0-watchtower.nubank.com.br/#data-infra) (check it for each shard by changing the url)

### hand-off

* On Friday at 5pm, the hausmeister shift ends and any pending issues are handed off to the weekend on-call engineer.
* On Monday at 11am, the weekend on-call engineer hands off any open P4-P3 issues to the new hausmeister.

### gain familiarity with new areas
As engineers we tend to specialize. The hausmeister rotation gives us visibility and experience into new parts of the code-base and tech stack.

## triaging

An issue has come to your attention via a slack channel, an alarm, or monitoring dashboards

### user questions
If the issue is with how a client is using the service, point them in the right direction. It isn't necessarily your responsibility to help them do their work, but consider writing docs if you see the same question coming up.

### service issues
If the issue is with our services, create an [itaipu issue](https://github.com/nubank/itaipu/issues/) tagged with `bug` and `data-infra` and a priority.
[Here is a list](https://github.com/nubank/itaipu/issues?q=is%3Aopen+is%3Aissue+label%3Abug+label%3Adata-infra) of current such issues.

The priority breakdown tells us how the issue should resourced:

* _P4 Very high priority_: Stop everything and pull in other people to get this resolved. Includes: building invalid datasets and bugs that prevent us from meeting external SLAs.
* _P3 High priority_: Hausmeister should actively work on this or hand-off to someone with more context who should actively work to resolve it.
* _P2/P1 Medium/low priority_: Backlog issue that can be addressed when time permits if even worth the time investment.

One should also be aware of the [severity levels](https://github.com/nubank/morgue#severity-levels) described on the `Nubank`-wide incident procedure docs. If an issue falls into one of those severity levels (rare for data-infra), those procedures should be followed.
