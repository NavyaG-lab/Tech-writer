# Berlin Onboarding

Welcome to [Nubank](https://nubank.com.br/) Berlin :tada:🇩🇪

## Getting accounts and permissions

Good! You already have a computer, a Gmail and also a Slack account. Now it's time to get the other credentials you're going to need.

First, you need to have an account on both [github.com](http://github.com) and [quay.io](http://quay.io).

### Access Requests

Then let's ask for access requests with this
[form](https://forms.gle/DkwiWfWoZXHXHAFQA).

* Submit one request by selecting `Account Creation -> add` for each of the
  following accounts, if don’t have them, already:
  * Github
  * Quay
  * Splunk
  * Databricks
  * AWS
  * Looker
* Submit another request by selecting `Account Creation -> group-add`.
  Specify `amazon` and paste the following groups:
  ```
  data-access-ops data-infra-aurora-access eng infra-ops prod-eng data-infra belomonte analyst
  ```
* Sonar-JS. Submit another request by selecting `Scopes`, and the
  scope name is: `metapod-admin`
* [BigQuery](https://wiki.nubank.com.br/index.php/BigQuery)

You'll be tagged in #access-request slack channel when the permission
is given to you.

### Other accounts

* Now, to join `datainfra` quay.io team, ping `@chico` or `@schaffer`
  on Slack with your quay.io handle (currently only admins are able to
  do this).
* Log-in to [circleci](https://circleci.com) with your GitHub account.
  This is for building code on branches, such as the pull request
  build indicator on Itaipu.

## Setting up your environment

### `setupnu.sh`

Overall, you should use [setupnu.sh](https://github.com/nubank/nudev#setting-up-a-new-development-machine). It has been updated and made more user-friendly recently.

The `setupnu.sh` script is self-explanatory. Make sure that you have gone through [Getting accounts and permissions](#getting-accounts-and-permissions) to be in the engineering group, otherwise you will have problems to use your aws key and secret while running `setupnu.sh`.

Every now and then people will find minor bugs on setupnu. This is a great opportunity to create your first PR.

### Other useful programs

[This wiki page](https://wiki.nubank.com.br/index.php/Programas_%C3%BAteis) lists
additional programs not covered by the setup script that you can
install and configure.

### VPN

After running `setupnu.sh`, setup your VPN by following [these steps](https://nubank.slack.com/archives/C024U9800/p1545380162000900).

### Validation
To validate the environment is working properly, you should clone a service repo and try to run its tests.

### Setting up scala

Scala 101: https://wiki.nubank.com.br/index.php/Scala

Independently of your editor of choice, is always a good idea to default to IDEA when coding in **Scala,** download it here [https://www.jetbrains.com/idea/download/#section=linux](https://www.jetbrains.com/idea/download/#section=linux) , you can use the community edition, which is free and works for working with **scala** .

After installing IDEA, let's set up our main project, [Itaipu](https://github.com/nubank/itaipu/) :

- At this point in time, you already have **[nucli](https://github.com/nubank/nucli/)** installed, so let's use it.
- `nu projects clone itaipu` this command you clone Itaipu to into your **$NU_HOME**
- now `cd` into itaipu's dir, and run `sbt test it:test` sbt is going to download all necessary dependencies and run Itaipu's tests.

Importing Itaipu on IDEA:

1. Open idea, click in **Configure -> Plugins**

  ![](https://static.notion-static.com/d90d9310dc1642249a992163f8d72c81/Screenshot_2017-12-01_11-58-00.png)

2. Browse Repositories -> Type Scala in the search box, and install the **Scala Language** plugin (you can further add IDEA features by following the instructions in section 7 of wiki's [useful programs](https://wiki.nubank.com.br/index.php/Programas_%C3%BAteis)).

  ![](https://static.notion-static.com/6224eb2fb911420bbafca0019e283e0a/Screenshot_2017-12-01_12-00-42.png)

3. Restart IDEA
4. Now, click on **Import Project** and select **itaipu's directory**

  ![](https://static.notion-static.com/83b9fb8bf0384dafb15400821f4af401/Screenshot_2017-12-01_12-01-54.png)

5. Select **Import Project from external Model -> SBT**

  ![](https://static.notion-static.com/c5d12ddcbd2f45c1a76f6a6515fe6526/Screenshot_2017-12-01_13-53-31.png)

6. Select the Java SDK that is installed on your machine. If you don't have one, click on **NEW** and select from your local machine.

  ![](https://static.notion-static.com/7a4b466d0c1a4ce1be1bf78122f7abc0/Screenshot_2017-12-01_13-56-33.png)

7. Next, Next, Finish. Wait a little bit for IDEA to download all dependencies and build the project.
8. Repeat the process with **common-etl**

All done.

## Nubank Core Infrastructure

You can find a bunch of relevant engineering links here:  [Onboarding](https://wiki.nubank.com.br/index.php/Engineering_Chapter/Onboarding)
[Tech talks](https://wiki.nubank.com.br/index.php/Busquem_Conhecimento3)
- Clojure
  - Clojure is the main programming language used at Nubank. You should know basic clojure well.
  - [Free beginner book](https://www.braveclojure.com/clojure-for-the-brave-and-true/)
  - [Advanced book](https://pragprog.com/book/vmclojeco/clojure-applied)
- [Service code organization (Ports & Adapters)][hexagonal-architecture-article]
  - This [first PR](https://github.com/nubank/savings-accounts/pull/1/files?diff=unified) of this service might help visualize the code organization at Nubank' services
  - [Microservice structure and hexagonal architecture glossary][code-organization-glossary]
  - [Busquem conhecimento (Portuguese)](https://wiki.nubank.cofeedbacksm.br/index.php/Busquem_Conhecimento#Ports_.26_Adapters)
- [Kafka](http://kafka.apache.org/intro)
  - Kafka is a distributed streaming platform. We use it for async communication between services.
  - The main kafka abstraction we use is the topic. [Services produce](https://github.com/nubank/bleach/blob/master/src/bleach/diplomat/producer.clj) messages to topics and [services consume](https://github.com/nubank/bleach/blob/master/src/bleach/diplomat/consumer.clj) messages from topics. Any number of services can produce to a topic and all the services that are consuming from this topic will receive this message.
  - [Busquem conhecimento in portuguese](https://wiki.nubank.com.br/index.php/Busquem_Conhecimento#Kafka)
- [Datomic](http://docs.datomic.com/tutorial.html)
  - Datomic is a git like database. Information accumulates over time. Information is not forgotten as a side effect of acquiring new information.
  - [Intro to Datomic](https://www.youtube.com/watch?v=RKcqYZZ9RDY)
  - [Learn datalog](http://www.learndatalogtoday.org/)
- AWS
  - We run most of Nubank services on AWS. If you want to get to know our cloud infrastructure better please go to `Basic Devops` at the [general onboarding guide](https://docs.google.com/a/nubank.com.br/document/d/1x6soXtlFli-I6zaGyUI-oG3k87ASaICoqr698NhFwwQ/edit?usp=sharing)
  - [Intro to Nubank's AWS Infrastructure](https://wiki.nubank.com.br/index.php/Busquem_Conhecimento#Intro_to_Nubank.27s_AWS_Infrastructure)
- Spark
  - **TODO**

## Data Infra's Onboarding Exercise

The goal of this exercise is to make you familiar with Nubank's general and data infrastructures. The exercise is split up into two parts, _Part I_ is ["Creating a dataset"](dataset-exercise.md) and _Part II_ is ["Creating a service to expose a dataset via API"](service-exercise.md).

[hexagonal-architecture-article]: https://alistair.cockburn.us/hexagonal-architecture/
[code-organization-glossary]: https://github.com/nubank/playbooks/blob/502cd385d5c30f13405f9b481d0557d793c61279/docs/code-organization.md#hexagonal-architecture
