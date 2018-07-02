# Data Access' Data Hero (aka weekday support rotation)

## What is a Data Hero?

The Data Access team is one of the main problem solvers for data related issues at Nubank, and one of the main channels that people can rely on to ask a question about data is the Slack channel [#data-help](https://nubank.slack.com/messages/C06F04CH1/). Nubank is growing up in size really fast and, as a consequence, the number of data related problems is growing with it, which results into members of data access team receiving more questions than they can respond in parallel to their normal workday. 

Worried about the constant context switch between squad's internal work to answering questions related to data, the Data Access team decided to create the role of the "data hero". Data hero is a person who will be in charge of resolving the problems of other nubankers that need help with data, while the rest of the team can focus on the squad objectives. By creating the role of Data Hero, Data Access will be able to benefit from more power hours of work without losing the ability to support other nubankers.

## Responsibilities

### Monitoring

Check and fix (if possible): 
 * [Redshift](https://console.aws.amazon.com/redshift/home?region=us-east-1#cluster-list:) 
 * [Databricks](https://nubank.cloud.databricks.com/#setting/clusters) 
 * [Metabase](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:search=metabase;sort=tag:Name)
 * [Looker](https://nubank.looker.com/admin)

### Support our Clients
Over the course of the week our customers, Nubank's data users, often encounter issues while using our services.
To support their effectiveness, the data hero is responsible for communicating with these users; looking into their issues in a timely manner; routing questions made by private messages and other channels to the proper one (_always respecting the current data hero technical limitations_).

Slack channels you should monitor for questions:

* [#data-help](https://nubank.slack.com/messages/C06F04CH1/)
* [#squad-data-access](https://nubank.slack.com/messages/C84FAS7L6/)
* [#guild-data-eng](https://nubank.slack.com/messages/C1SNEPL5P/)

### Itaipu

* Review and merge PR's
* Guide people on the creation of new datasets
* Move StaticOp's to the appropriate AWS S3 bucket and prefix

### Guide people on the use and setup of:
* Sonar
* belomonte (python library): https://wiki.nubank.com.br/index.php/Belo_Monte
* Imordor
* Mordor
* Dbeaver: https://github.com/nubank/playbooks/tree/master/squads/data-access/dbeaver and https://wiki.nubank.com.br/index.php/SQL_client

### Databricks
* Detach notebooks olders than 5 days
* Restart clusters that are not working as expected
* Attach, detach, add and remove libraries, especially itaipu

### Escalating
Do not be afraid of asking for help if you need to. Here are some non-comprehensive guidelines on when to escalate:
* if you want to start to work on an issue but do not know where to start;
* if you try to solve an issue for more than one hour and feel you are not making progress;
* if you do not know how to prioritize a new incoming issue.

## Schedule

Two members of data access will be scheduled to work as data hero for each week. The initial idea is to pick one of the more experienced members with a more junior one. In this week, the priority of the data heroes will be to help other nubankers. Should be harder for them to work on side projects, but they can if they want.

## *NOT* Responsabilities

### Support our Clients

Do not help people that come directly to the data access room with their laptops, without being invited. Properly point them to the respective slack channel, making sure they understand that this is not just for bureaucracy. That's how we measure the quality of our support and ensure that other users can help them as well.

### Data Infra

* Fix failures on the nightly run (data-infra is always working to improve the quality of our runs)
* Answer if tapir, conrado and curva-de-rio are working

### Itaipu

Create new datasets because someone is asking (the request for new datasets should be formally made to the data access squad/tech lead so we can add this to our backlog, if needed)

### Computer Issues

Fix someone else computer (we are here to help with data related problems)

## Tips

An issue has come to your attention via a slack channel, an alarm, or monitoring dashboards

### User Questions
If the issue is with how to do a specific task, point them in the right direction (docs/playbooks). It isn't necessarily your responsibility to help them do their work, but consider writing docs if you see the same question coming up.

### Itaipu

Common issues:

* Bad identation and/or formatting: run `scalafmt`
* New SparkOps not added to the main package
* New Dataset Series without a corresponding PR on [curva-de-rio](https://github.com/nubank/curva-de-rio)
* New StaticOp without file on S3


