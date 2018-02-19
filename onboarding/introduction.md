# Berlin Onboarding

Welcome to [Nubank](https://nubank.com.br/) Berlin

## Getting a computer

ask **@gavin** for a computer :)

## Getting accounts

Good! You already have a computer, a Gmail and also a Slack account. Now it's time to get the other credentials you're going to need.

First, you need to have an account on both [github.com](http://github.com) and [quay.io](http://quay.io), then ask on the **#access-request** slack channel informing your nubank mail, your **GitHub** and quay.io **users** for the following accounts:

- Splunk
- Databricks
- AWS
- Nubank's [Quay.io](http://quay.io) + data-infra group

 **To ask for any kind of access, account or credentials you should ask on #access-request** 

So now ask on #access-request for the following permissions:

- Belomonte account

For more information on the access you need to contribute to data-infra: [Permissions needed to contribute to data infra](https://github.com/nubank/data-infra-docs/blob/master/primer.md#permissions--accounts-needed-to-contribute-on-data-infra-update-required) 

## Setting up your environment

Overall, you should use [https://wiki.nubank.com.br/index.php/Dev_environment](https://wiki.nubank.com.br/index.php/Dev_environment) . It has been updated and made more user-friendly recently.

The setupnu.sh script is self-explicative so you shouldn’t have major problems with it.

Every now and then people will find minor bugs on setupnu. This is a great opportunity to create your first PR.

To validate the environment is working properly, you should clone a service repo and try to run its tests. 

Setting up **scala:** 

Independently of your editor of choice, is always a good idea to default to IDEA when coding in **Scala,** download it here [https://www.jetbrains.com/idea/download/#section=linux](https://www.jetbrains.com/idea/download/#section=linux) , you can use the community edition, which is free and works for working with **scala** .

After installing IDEA, let's set up our main project, [Itaipu](https://github.com/nubank/itaipu/) :

- At this point in time, you already have **[nucli](https://github.com/nubank/nucli/)** installed, so let's use it.
- `nu projects clone Itaipu` this command you clone Itaipu to into your **$NU_HOME**
- now `cd` into itaipu's dir, and run `sbt test it:test` sbt is going to download all necessary dependencies and run Itaipu's tests.

Importing Itaipu on IDEA:

1. Open idea, click in **Configure -> Plugins** 

  ![](https://static.notion-static.com/d90d9310dc1642249a992163f8d72c81/Screenshot_2017-12-01_11-58-00.png)

2. Browse Repositories -> Type Scala in the search box, and install the **Scala Language** plugin.

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
- [Service code organization (Ports & Adapters)](http://alistair.cockburn.us/Hexagonal+architecture)
  - This [first PR](https://github.com/nubank/savings-accounts/pull/1/files?diff=unified) of this service might help visualize the code organization at Nubank' services
  - [Microservice structure and hexagonal architecture terms](https://github.com/nubank/playbooks/blob/master/glossary.md#microservice-structure-and-hexagonal-architecture-terms)
  - [Busquem conhecimento (Portuguese)](https://wiki.nubank.cofeedbacksm.br/index.php/Busquem_Conhecimento#Ports_.26_Adapters)
- [Kafka](http://kafka.apache.org/intro)
  - Kafka is a distributed streaming platform. We use it for async communication between services.
  - The main kafka abstraction we use is the topic. [Services produce](https://github.com/nubank/bleach/blob/master/src/bleach/diplomat/producer.clj) messages to topics and [services consume](https://github.com/nubank/bleach/blob/master/src/bleach/diplomat/consumer.clj) messages from topics. Any number of services can produce to a topic and all the services that are consuming from this topic will receive this message.
  - [Busqume conhecimento in portuguese](https://wiki.nubank.com.br/index.php/Busquem_Conhecimento#Kafka)
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
