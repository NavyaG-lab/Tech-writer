# Berlin Onboarding

Welcome to [Nubank](https://nubank.com.br/) Berlin :tada:🇩🇪  We are excited you're here!

As part of Onboarding, you'll need to do the following:

* [Create accounts and request for accesses](#accounts-and-access-permissions)
* [Setup environment](setup.md)
* [Onboarding Exercises](setup.md)

## Accounts and access permissions

Good! that you already have a Nubank machine and a Gmail account with Nubank credentials.

Let's get started by creating the following accounts:

* Slack
* [github](https://github.com/)
* [Quay.io](https://quay.io/)

### Request access for services through IT Ops

Raise a request for the following accounts by logging into Nubank's [IT Ops](https://nu-itops.atlassian.net/servicedesk/customer/user/login).

### Services

|Tools or services|Notes|
|----------------|---------|
|Create a [Github](https://github.com/) account|Get access to the [Nubank github](https://github.com/nubank/) account, the Nubank's codebase|
|splunk|To trace and debug the services|
|Databricks|Data analysis tool. You already have access to Databricks via Okta. To access databricks notebooks, reach out to florian.kornrumpf@nubank.com.br. Or, raise a request via IT Ops to get added to a specific group inside Databricks|
|Looker|Data visualization tool|
|Sonar-js|Submit request by selecting `Scopes`, and name of the scope is `metapod-admin`|
|OpsGenie|An Incident management tool used by Hausmeisters|

#### How to request access

1. Log in to [IT Ops](https://nu-itops.atlassian.net/servicedesk/customer/user/login) using Nubank credentials.
1. Choose the service or tool for which you want to raise a request.
1. Fill the required fields and submit.

### Request access for AWS groups

The AWS credentials are sent to you through SlackBot, a few days after you join. Then, request for accessing the AWS groups.

1. Log in to [IT Ops](https://nu-itops.atlassian.net/servicedesk/customer/user/login) using Nubank credentials.
1. Select **BR** from the list of AWS accounts. Fill other required fields.

   **Note**: Make sure you are added to all three accounts in AWS - **BR**, **MX**, and **Data**. You must raise requests to be added in each AWS account.
1. Enter the following groups in the **IAM Group/s** field.
    * For **BR** account
        * data-access-engineering
        * data-access-ops
        * data-infra
        * data-infra-aurora-access
    * For **Data** account
        * eng
        * prod-dev
1. Submit the request.

## How to Join datainfra group in Quay.io

1. You must have created Quay.io account already. If you don't already have an account, [create one](https://quay.io/).
1. You'll receive an invite on your email to join quay.io "nubank account". If not, reach out to #access-request Slack channel to join.
1. Then, join the datainfra quay.io team. To do so,
      * Ping @chico or @schaffer on Slack with your quay.io handle (or)
      * Join #access-request Slack channel and post your request.

## Other accounts

* [BigQuery](https://wiki.nubank.com.br/index.php/BigQuery): A data visualization and analysis tool. By default everyone has access to non-PII data.
* [Circleci](https://circleci.com): Log-in to [circleci](https://circleci.com) with your GitHub account.
  This is for building code on branches, such as the pull request
  build indicator on Itaipu.

## Get access to production and Staging environment

An Engineer will have aceess to Production environment by default. For access to staging environment, you must raise a request.

* For Metapod: Raise a request for staging CERT through [IT Ops](https://nu-itops.atlassian.net/servicedesk/customer/user/login).

 **Note:** For requests related to access permissions, reach out to #access-request slack channel and post your request.

## Nubank Core Infrastructure

You can find a bunch of engineering links here:  [Onboarding](https://wiki.nubank.com.br/index.php/Engineering_Chapter/Onboarding)
[Tech talks](https://wiki.nubank.com.br/index.php/Busquem_Conhecimento3)

* Clojure
  * Clojure is the main programming language used at Nubank. You should know basic clojure well.
  * [Free beginner book](https://www.braveclojure.com/clojure-for-the-brave-and-true/)
  * [Advanced book](https://pragprog.com/book/vmclojeco/clojure-applied)
  * [Courses on Alura portal](https://courses.alura.online/loginForm?urlAfterLogin=/loginForm)
* [Service code organization (Ports & Adapters)][hexagonal-architecture-article]
  * This [first PR](https://github.com/nubank/savings-accounts/pull/1/files?diff=unified) of this service might help visualize the code organization at Nubank' services
  * [Microservice structure and hexagonal architecture glossary][code-organization-glossary]
  * [Busquem conhecimento (Portuguese)](https://wiki.nubank.cofeedbacksm.br/index.php/Busquem_Conhecimento#Ports_.26_Adapters)
* [Kafka](http://kafka.apache.org/intro)
  * Kafka is a distributed streaming platform. We use it for async communication between services.
  * The main kafka abstraction we use is the topic. [Services produce](https://github.com/nubank/bleach/blob/master/src/bleach/diplomat/producer.clj) messages to topics and [services consume](https://github.com/nubank/bleach/blob/master/src/bleach/diplomat/consumer.clj) messages from topics. Any number of services can produce to a topic and all the services that are consuming from this topic will receive this message.
  * [Busquem conhecimento in portuguese](https://wiki.nubank.com.br/index.php/Busquem_Conhecimento#Kafka)
* [Datomic](http://docs.datomic.com/tutorial.html)
  * Datomic is a git like database. Information accumulates over time. Information is not forgotten as a side effect of acquiring new information.
  * [Intro to Datomic](https://www.youtube.com/watch?v=RKcqYZZ9RDY)
  * [Learn datalog](http://www.learndatalogtoday.org/)

* AWS
  * We run most of our Nubank services on AWS using Kubernetes. If you want to get to know our cloud infrastructure, go to `Basic Devops` at the [general onboarding guide](https://docs.google.com/a/nubank.com.br/document/d/1x6soXtlFli-I6zaGyUI-oG3k87ASaICoqr698NhFwwQ/edit?usp=sharing)
  * [Intro to Nubank's AWS Infrastructure](https://wiki.nubank.com.br/index.php/Busquem_Conhecimento#Intro_to_Nubank.27s_AWS_Infrastructure)
  * [Buscquem conhecimento in English on Kubernetes](https://www.youtube.com/watch?v=93O8C4cKd1g)

* [Apache Spark](https://spark.apache.org/)
  * Apache Spark is a general framework, that by leveraging distributing computing, handles large-scale data processing and analytics.
  * We at Nubank are heavy users of it; We use it to process and produce new [datasets](https://github.com/nubank/data-platform-docs/blob/master/glossary.md#dataset).

After requesting for access permissions, [setup](setup.md) your dev environment.
