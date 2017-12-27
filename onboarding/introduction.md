# Berlin Onboarding

Welcome to [Nubank](https://nubank.com.br/) Berlin

# Getting a computer

ask **@gavin** for a computer :)

# Getting accounts

Good! You already have a computer, a Gmail and also a Slack account. Now it's time to get the other credentials you're going to need.

First, you need to have an account on both [github.com](http://github.com) and [quay.io](http://quay.io), then ask on the **#squad-infosec** slack channel informing your nubank mail, your **GitHub** and quay.io **users** for the following accounts:

- Splunk
- Databricks
- AWS
- Nubank's [Quay.io](http://quay.io) + data-infra group

 **To ask for any kind of access, account or credentials you should ask on #access-request** 

So now ask on #access-request for the following permissions:

- Belomonte account

For more information on the access you need to contribute to data-infra: [Permissions needed to contribute to data infra](https://github.com/nubank/data-infra-docs/blob/master/primer.md#permissions--accounts-needed-to-contribute-on-data-infra-update-required) 

# Setting up your environment

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

# Nubank Core Infrastructure

You can find a bunch of relevant engineering links here:  [Onboarding](https://wiki.nubank.com.br/index.php/Engineering_Chapter/Onboarding)
[Tech talks](https://wiki.nubank.com.br/index.php/Busquem_Conhecimento3)
- Clojure
  - Clojure is the main programming language used at Nubank. You should know basic clojure well.
  - [Free beginner book](https://www.braveclojure.com/clojure-for-the-brave-and-true/)
  - [Advanced book](https://pragprog.com/book/vmclojeco/clojure-applied)
- [Service code organization (Ports & Adapters)](http://alistair.cockburn.us/Hexagonal+architecture)
  - This [first PR](https://github.com/nubank/savings-accounts/pull/1/files?diff=unified) of this service might help visualize the code organization at Nubank' services
  - [Microservice structure and hexagonal architecture terms](https://github.com/nubank/data-infra-docs/blob/master/glossary.md#microservice-structure-and-hexagonal-architecture-terms)
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

# Exercise

The goal of this exercise is to make you familiar with Nubank's infra-structure, and also with data-infra's specific technologies. It's going to touch our core abstraction the [**SparkOp**](https://github.com/nubank/common-etl/blob/master/src/main/scala/common_etl/operator/SparkOp.scala) ** (short for spark operation) ** and guide you through how to write a new SparkOp, how to run it on Databricks and to consume it in a Clojure service.

---

First make sure you have access to [**databricks**](http://nubank.cloud.databricks.com), then there's this [Databricks Tutorial](https://docs.databricks.com/spark/latest/gentle-introduction/for-data-engineers.html) , designed for giving you a introduction to Spark running on Databricks, open the tutorial and click on `copy this link to import this notebook!` and click on `Import Notebook`. Copy the URL, then import into [Databricks](https://nubank.cloud.databricks.com)

![Import into Databricks](https://user-images.githubusercontent.com/1674699/33720480-594ffaec-db64-11e7-96b5-ec6a78a4cbae.png)

Go through that notebook and come back here :)

## Statement

---

Nubank has a problem with dealing with bills. For some unknown reason, it has become really difficult to query what is the due amount of past bills for a given customer. To solve this issue, we want to create a new service that will read data produced by the ETL, build a cache from it, and serve the data using a GraphQL API.

 **TODO - Creating the Dataset** 

---

- [ ]  Figure out which datasets should we use to build the derivative dataset
- [ ]  Write a SQL query that represents the dataset on Databricks
- [ ]  Transform that Query into Scala code
- [ ]  Write a SparkOp with the definition of our dataset
- [ ]  Run the SparkOp on Databricks
- [ ]  Add the new dataset to Itaipu
- [ ]  Writing Tests to the Dataset
- [ ]  Build Itaipu locally
- [ ]  Run it on a Cluster
- [ ]  Query metapod to get the path were the dataset was written to
- [ ]  Read the written dataset on Databricks to check it.

 **TODO - Creating the Service** 

---

- [ ]  Generating a new service using the nu-service-template
- [ ]  Getting the avro partitions through the s3 component
- [ ]  Defining the inner representation of the entity
- [ ]  Endpoint to trigger data consumption
- [ ]  Producing and consuming to kafka
- [ ]  Saving to datomic
- [ ]  Endpoint for getting the data
- [ ]  Testing
  - [ ]  Unit tests
  - [ ]  Integration test
- [ ]  Run the service locally

## Creating the Dataset

---

 **Figure out which Datasets should we use to build the derivative dataset** 

For this, basically you want information about the customer and their bills. We organize our data-warehousing into facts and dimensions, using the terminology from [Kimball's DW books](https://github.com/nubank/data-infra-docs/blob/master/dimensional_modeling/kimball.md). 

So, let's look at the available tables on Databricks.

 `show tables from dataset` will list all the tables from the **dataset** schema

 `show tables from dataset like "fact*"` for the bills table we want to search for it in the **fact** schema.

 `show tables from dataset like "dimension*"` for the customer table we want to look at the dimension tables.

So, let's figure out which is the table that we should use:

![](https://static.notion-static.com/1a39fc32ba514f7389624f1efda33b8f/Screenshot_2017-12-05_15-54-00.png)

Running the command above gives you the **fact__billing_cycle** as the only alternative

So now let's look at its data to see if it makes sense:

![](https://static.notion-static.com/d4f0485d14ab4a6a95e4b8b6786e9b84/Screenshot_2017-12-05_15-56-19.png)

It does! So now do the same thing to figure out which **dimension ** should we use to join to the **customer_key** column.

---

## Write a SQL query that represents the dataset on Databricks

So now it's time to join both tables generate a new dataset. Do this using SQL.

The schema of the dataset should be

 **customer_id, bill_id, bill_index, due_date, amount_on_bill** 

If you don't remember much SQL, get a refresh [HERE](https://docs.databricks.com/spark/latest/spark-sql/language-manual/select.html) 

---

## Transform that Query into Scala code

Now you should have a nice SQL query that returns the data for our service.

But... it's SQL and we shouldn't throw SQL out to other people have to read, because we're nice to each other.

So let's transform that SQL query into Scala code!

The first step to do that is to get the inputs that you need as Dataframes, you do that by using the method `.table` from the `SparkSession` which is available on Databricks as the value `spark` 

So for the bill fact would be something like:

 `val billsFact = spark.table("dataset.fact__billing_cycle")` 

then you do the same thing for the customer's table.

Once you have both Dataframes, you need to change the SQL functions to SparkSQL functions, you can look up at the Documentation for:

 [Dataset](http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.Dataset) (have all functions for when you have a Dataframe/Dataset and you do dataframe.function, **join** and **select** are there for example)

 [sql.functions](http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.functions$) (this is where the aggregations and statistical functions are, as well as bunch of other helpful functions like ones related to dates)

 [Column](http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.Column) (when you need to do operations using columns like column + column)

Now, go for it, change your code to Scala :)

---

## Write a SparkOp with the definition of our dataset

You're probably questioning WTF is a SparkOP :), you can look by yourself [HERE](https://github.com/nubank/common-etl/blob/master/src/main/scala/common_etl/operator/SparkOp.scala#L7) 

It's the core abstraction behind our data-platform, the important things are:

 **Name:** You have to grant your dataset a name so others can use your dataset as dependency

 **Inputs:** The list of inputs that you're going to need, you just need the name of them, and you can find which are the name of your dependencies by looking at its SparkOps

 **Definition:** That's where the magic happens, the inputs above are going to get injected at runtime to this function in this **Map[String, Dataframe]** so the name of your input is the key on the map and its Dataframe is the value.

 **Format:** That's where you define which format you're going to get as output, in our case let's use [**Avro**](https://avro.apache.org/docs/1.2.0/) because it'll be easier to consume from the service side.

So now import the **SparkOp** trait on Databricks:

 `import common_etl.operators.SparkOp` 

and create a new `object` that `extends` the `SparkOp` and implement the methods :)

---

## Run the SparkOp on Databricks

Once you have your SparkOp done, you can use the function on [DatabricksHelpers](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/databricks/DatabricksHelpers.scala#L40) and run:

 `DatabricksHelpers.runOpAndSaveToTable(spark, op, "**schema**", "the_name_of_dataset")` 

 `**schema**` usually we use our own names as the schema when saving the table to Databricks.

Run it! And then query your dataset to see if everything is nice!

To make it easier to do the service exercise save the avro files to s3 once again (itaipu will do that, but we're doing it again in case anything goes wrong there). This will save the dataset on `s3://nu-spark-devel/onboarding/**schema**/`

```
spark.table("**schema**.the_name_of_dataset").write.avro("/mnt/nu-spark-devel/onboarding/**schema**/")
```

---

## Add the new dataset to Itaipu

Now that you have a SparkOP ready is time to add it to Itaipu.

Create a file on:

 `itaipu/src/main/scala/etl/dataset/` With the name of your dataset `.scala` 

If you do through IntelliJ it already adds the package information for you. (Right-click on the `dataset` directory > new > `Scala Class` 

Then just paste the code there!

Now, you need to add the dataset to the list of all SparkOps that are run by Itaipu. This dataset fits the category of "general dataset" so you add it [**here**](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/dataset/package.scala#L23), all other lists of datasets can be found **[here](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/itaipu/Itaipu.scala#L46)** 

To check if everything is right you can run: 

 `sbt it:test` 

On Itaipu we have the [ItaipuSchemaSpec](https://github.com/nubank/itaipu/blob/master/src/it/scala/etl/itaipu/ItaipuSchemaSpec.scala#L35) that runs all **SparkOps** with fake data, and check if all inputs match the expectation. We can only to that due to Spark's lazy model, so we can effectively call the **definition** function with the expected **dataframes** as inputs, and check if all operation that you are doing can be done, like if the column that you're expecting from an input actually is there.

**IMPORTANT**: We just want a sample of the data, otherwise adding it to Kafka and datomic would take forever, so just add the `.limit(10000)` to the end of your definition, this you give you 10k records. The `limit` method adds all the data into a single partition, to fix that just add `.repartition(10)` after the `limit` call

More information about creating a new dataset [HERE](https://github.com/nubank/data-infra-docs/blob/master/itaipu/workflow.md#creating-a-new-dataset) : 

---

## Writing tests to the Dataset

For writting tests we use two libraries, [ScalaTest](http://www.scalatest.org/) and [SparkTestingBase](https://github.com/holdenk/spark-testing-base) .

Fist create a class in the same package as your dataset, but changing from `main` to `test` and adding `Spec` to the end of the name.

Add the following extensions to your class:

```scala
extends FlatSpec with NuDataFrameSuiteBase with Matchers
```

And then is basically writing normal tests, for reference you can check the [BillingCyclesSpec](https://github.com/nubank/itaipu/blob/master/src/test/scala/etl/dataset/billing_cycles/BillingCyclesUnsafeSpec.scala#L11) 

[Running the tests](https://github.com/nubank/data-infra-docs/blob/master/itaipu/workflow.md#running-tests) 

---

## Build Itaipu locally

Time to run it!

We use Docker for basically running everything here at Nubank, so it's not a surprise that you'll need to build Itaipu's docker container.

To do that just to:

`$NU_HOME/deploy/bin/docker.sh build-and-push $(git rev-parse --short HEAD)`

The `docker.sh` script is inside the `deploy` project. It's a standard script for building docker images. It will run the script `prepare.sh` (which will run `sbt assembly`) and then run build and push the docker image using the name of your project as the name. e.g. for `itaipu`, it will be `quay.io/nubank/nu-itaipu:{SHA}`

Done, we can now run it!

---

## Run it on a Cluster

Now it's where the real fun begins :)

First, let's split the work into 4 parts.

* Get used to `sabesp`
* Scale the cluster
* Run Itaipu
* Downscale the cluster


Sabesp is basically a wrap over the [`aurora-client`](http://aurora.apache.org/documentation/latest/reference/client-commands/) so we don't have to write a bunch of things manually and it makes us able to specify which Aurora cluster do you want to run your command.

Take a look at [cli-examples](../cli_examples.md) to get a sense of how running sabesp commands look like.

Now, we're going to use just a single command
`sabesp --aurora-stack=cantareira-dev jobs create ... ... ...`
Which translates to create a job on the `cantareira-dev` stack. All jobs definition are inside the (aurora-jobs)[github.com/nubank/aurora-jobs] project.

If you don't have aurora-jobs cloned, please do it (inside the $NU_HOME directory), because sabesp you look for the definitions from there.

We need a suffix for scaling and running itaipu, so we can run Spark in an isolated set of instances, so when you see the placeholder /suffix/ just use the same value. When running dev-runs We usually use our names.

#### 1. Scale the Cluster

`sabesp --aurora-stack=cantareira-dev jobs create prod scale-ec2-/suffix/ SLAVE_TYPE=/suffix/ NODE_COUNT=100 INSTANCE_TYPE=m4.2xlarge --job-version="scale_cluster=21d67a5" --filename scale-ec2 --check`

This command basic translates to using the `scale-ec2` definition on aurora-jobs We're going to create the scale-up job that with 16 instances and using the version `d749aa4`, all those binds `VAR=value` translates to binds on the aurora-jobs those binds replace the mustaches `{{}}` in the file.

You can check if the instances are running on the AWS Console: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:tag:Name=cantareira-dev-mesos-on-demand-;sort=instanceId

**IMPORTANT** Don't forget to scale down (step 3) after you are done running Itaipu. Leaving the cluster up is very expensive.

#### 2. Run Itaipu

Wow, it's a huge command, but for Itaipu We need to set a bunch of parameters, eg: METAPOD_REPO=where I'm going to write this thing, CORES=how many cores is spark allowed to use, TARGET_DATE=When is this run happening. REFERENCE_DATE=what's the reference for the data being generated (usually is from yesterday). and so on.

```
sabesp --verbose --aurora-stack=cantareira-dev \
jobs create staging itaipu-/suffix/ \
--job-version="itaipu=$(git rev-parse --short HEAD)" \
--filename itaipu \
METAPOD_REPO=s3a://nu-spark-metapod-test \
TARGET_DATE=$(date --iso-8601) \
REFERENCE_DATE=$(date --iso-8601) \
DRIVER_MEMORY=26843545600 \
CORES=9999 \
OPTIONS="filtered,dns" \
METAPOD_TRANSACTION=$(uuidgen) \
METAPOD_ENVIRONMENT=staging \
SKIP_PLACEHOLDER_OPS="true" \
DATASETS="dataset/**THE_NAME_OF_YOUR_DATSET**" \
ITAIPU_SUFFIX=/suffix/ \
DRIVER_MEMORY_JAVA=22G
```
**Important**: Replace the `THE_NAME_OF_YOUR_DATSET` with the name attribute of your spark-op, and also replace the `/suffix/` with the same suffix that you used to upscale the cluster.

All those variables could seem magical defined, but actually, if you remove one of them sabesp is going to complain that an argument is missing :).

And if you're scared of trying to run, you can add the `--dryrun` flag to sabesp, which will just inspect if everything is "right".

You can check the status of your job on https://cantareira-dev-mesos-master.nubank.com.br/scheduler/jobs/staging/itaipu-/suffix/, and if you click into the link on the IP address of the instance you'll see a link `spark-ui`, if you click there you'll see the `SparkUI` on which you can keep an eye on the execution process.


To check if the job has finished you can look at the aurora-ui, or add the `--check` flag on sabesp so it'll away until the job has finished.


#### 3. Scale down the Cluster

After the job has finished, we need to scale down the cluster.

`sabesp --aurora-stack=cantareira-dev jobs create prod downscale-ec2-/suffix/ SLAVE_TYPE=/suffix/ NODE_COUNT=0 --job-version="scale_cluster=21d67a5" --filename scale-ec2 --check`


You can check if the instances are terminating in the AWS Console: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:tag:Name=cantareira-dev-mesos-on-demand-;sort=instanceId

---

## Query metapod to get the path were the dataset was written to

[`Metapod`](https://github.com/nubank/metapod) is the service on which we track the metadata about t he run. So it has all information related to:
* where the datasets were committed;
* what are the dataset's partitions;
* what's its schema;
* and so on.

We can query metapod directly using its URL, for our run we used the staging metapod, so it'll be accessible on: https://staging-global-metapod.nubank.com.br/


**IMPORTANT** to do requests on Metapod you need the `metapod-admin` scope, ask on #access-request for this scope on both `prod` and `staging`

There's a bunch of ways to get information about our dataset, the simplest way is to get it for [sonar](https://github.com/nubank/sonar-js) which is the UI for metapod. You can access it on:
Prod - https://backoffice.nubank.com.br/sonar-js/
Staging - https://staging-backoffice.nubank.com.br/sonar-js/

log in, and then find your transaction in the list of [transactions](https://backoffice.nubank.com.br/sonar-js/#/sonar-js/monitoring) "Monitoring" menu on the left side, click on it and search for the dataset, and there you can see all information about it.

![Transaction on Sonar](./images/sonar-tx.png)

Other option is to use the GraphQL interface on Sonar and do a query.

![Graphqi interface](./images/graphiql.png)

Just open the menu and click on `GraphiQL`, it'll open the editor above.

The query to get a specific dataset from a transaction is the one below:

```
query GetFilteredDataset($transactionId: ID, $datasetNames: [String]) {
  transaction(transactionId: $transactionId) {
    id
    name
    startedAt
    committedAt
    datasets(datasetNames: $datasetNames, committed: ONLY_COMMITTED) {
      id
      transactionId
      name
      partitions {
        id
      }
      format
      path
      committedAt
    }
  }
}
```

and You need to bind the query-parameters to the ones in the query like:
```
{
	"transactionId": "b44c7bab-a90e-54ab-a029-5fc6594eefb5",
	"datasetNames": [
		"dataset-fact/credit-card-account-snapshot",
		"dataset-fact/credit-card-account-snapshot-avro"
	]
}
```

![query using graphiql](./images/query-graphiql.png)

Now you have all the information needed to query the dataset on databricks.

---

## Read the written dataset on Databricks to check it

After you get the path for the dataset from metapod (through the graphql at Sonar), let's read it on Databricks to check if everything is as expected.

So, go back to you notebook and read it.

For dealing with avros, we need to import one library:

`import com.databricks.spark.avro._`

and then read it.

```
val df = spark.read.avro("dbfs:/mnt/your-path-without-s3://")
df.count()
display(df)
```

On Databricks we read from S3 through DBFS, the s3 buckets are mounted on `/mnt` you can see the buckets there by using the dbfs api.

```
%fs
ls /mnt
```





---

PS: if you get stuck, you can get all steps done in [this](https://nubank.cloud.databricks.com/#notebook/138371) notebook, but, don't cheat :)

# Creating the Service to serve the data

---

Before starting you should read this glossary of our 
[service architecture](https://github.com/nubank/data-infra-docs/blob/master/glossary.md#microservice-structure-and-hexagonal-architecture-terms)

Best Nubank tool: adding `#nu/tapd` before an s-exp will print the value 
returned by this s-exp everytime your code execute this s-exp. That's great for
debugging or to just know WTH is going on in a piece of code. To add in the 
middle of a thread macro (this print the value being passed in the thread macro 
at a certain point) add `nu/tapd` (without the `#`). More about `nu/tapd` and
other helpful debug macros can be found in the [cljdev
readme](https://github.com/nubank/cljdev#functionsmacros)


## Generating a new service using the nu-service-template

We usually use this [template](https://github.com/nubank/nu-service-template) 
for generating new services. You should create a `normal` service, and not a 
`global` one.

After generating the code of your service run 
`nu certs gen service test <service-name>`. This command doesn't work with 
dockerized `nu`, you can check if your `nu` command is dockerized with `type nu`
 and `which nu`. If you have a dockerized nucli run `unset nu`, this will unset 
the dockerized version in your current terminal session.

After that your tests should be working. Run [`lein nu-test`](https://github.com/nubank/nu-test)
(this will run both [midje unit tests](https://github.com/nubank/data-infra-docs/blob/master/glossary.md#test-unit-tests) and [postman integration tests](https://github.com/nubank/data-infra-docs/blob/master/glossary.md#postman-tests))

---

## Getting the avro partitions through the s3 component

The library that we will use to read avro files requires the files to be saved 
locally, so before reading the files we need to download them from s3.

We'll use the 
[s3 component](https://github.com/nubank/common-db/blob/master/src/common_db/components/s3_store.clj)
to discover and dowload the files. This component implements mainly the [storage protocol](https://github.com/nubank/common-db/blob/master/src/common_db/protocols/storage.clj). 
Looking at the protocols implemented by a component is the simplest way to have 
a big picture understanding of it can do.

We'll add this component to the `base` fn on the `service.components` namespace 
of your service. Just take a look on how other components are added and do the 
same. The only dependency that your component needs is the `config` component.

This s3 component can be used to access only one bucket (the bucket is the first
 part of an s3 uri after the `s3://`: `s3://bucket/folders/files`). One way to 
define which bucket your component will use is add an entry on 
`resources/service_config.json.base` with key `s3_bucket` and value 
`nu-spark-devel` (which is the 
[bucket](https://github.com/nubank/data-infra-docs/blob/onboarding/onboarding/introduction.md#run-the-sparkop-on-databricks)
 that we used to manually save the dataset on databricks)

Congrats, you now have a s3 component. Now lets use it.

In a repl (or a file that will be sent to a repl) start your system with 
`service.components/create-and-start-system!` (save it a def)

This system is a map with all the components defined on the `service.components`
 namespace.

To list all the files you can simply do 
`(common-db.protocols.storage/list-objects (:s3 system) "onboarding/**schema**/")`.
 This s3 path was defined 
[here](https://github.com/nubank/data-infra-docs/blob/onboarding/onboarding/introduction.md#run-the-sparkop-on-databricks)

Now you should write some code to caching locally all these files of a given s3 
folder.

---

## Defining the inner representation of the entity

We want to store all the entries on the avro files on datomic. For each line 
we'll store a new entry on datomic. To insert data on datomic we need a schema. 
To help us figure out a good inner schema we'll have a look on the schema of the
 avro files. For reading avro files we'll use the library 
[abracad](https://github.com/damballa/abracad). You'll need to add this library 
as a dependency on your `project.clj` file and restart your repl.

Run `(seq (abracad.avro/data-file-reader file-name))` for any file that you 
saved locally. This wil return all the record on a given avro file. Based on 
these record you should define an inner representation to your entity. Take a 
look at this 
[namespace](https://github.com/nubank/savings-accounts/blob/master/src/savings_accounts/models/savings_account.clj)
 to get an idea on how to create your model.

The `id`s that you got on the avro files are all foreign keys, but we also need 
a primary key. We use uuid to do that and usually call them `name-of-entity/id`.
 This id will be generated by datomic when you insert the entity.

After creating the schema of your entity add the skeleton on the namespace 
`service.db.datomic.config`

---

## Endpoint to trigger data consumption

Now let's move away from the repl a bit to start to write the flow.

We want an endpoint that only who has the `admin` scope can use. Add a new 
endpoint to the `service` namespace. This endpoint should receive a json body
with the s3 path associated with the key `s3-path`. To extract the body 
parameters on your handler you need to extract the `:body-params` key in the 
arg list of the `defhandler` (in the same level as the `:components` is)

This flow will cache locally the files from s3 and produce messages to kafka. So
 in the handler triggered by the new endpoint we'll extract the s3 and producer 
component. But before using the s3 component on the http handler we need to add 
it as a dependency to the webapp component(in the `service.components` 
namespace). The producer already is a dependecy of this component.

The endpoint you are creating will call a `controller` function that will 
control the flow. All the deterministic and without side effects functions go 
into a `logic` namespace, try to extract as many as these functions as possible.

The flow will download the files from s3 and for each entry in all files it 
will produce a message on kafka

---

## Producing and consuming to kafka

The namespaces responsible for producing and consuming messages to and from 
kafka are `service.diplomat.producer` and `service.diplomat.consumer`, 
respectively. Take a look at `savings-accounts` to grasp how they work.

To produce a message we need to convert the data to a wire schema. We are 
reading the messages in the avro schema, so we need a function to convert this 
avro in our a wire schema; this kind of functions live on namespaces under 
`service.adapters`.

But before defining the adapting function we need to define the wire schema. 
Usually these schemas live on 
[common-schemata](https://github.com/nubank/common-schemata). But since this is 
a pet project we can define them under `service.models` (don't tell anybody I 
recommended that ;) )

Now you can write the function that avro-schema->wire-schema. These adapters 
functions are called on the edges(consumer, producer, https), so we don't have 
to deal with wire data inside our service.

Everytime you use a new topic you need to register it on `kafka_topics` in the 
`resources/service_config.json.base` file.

We'll consume the topic we just produced the messages(yes, it doesn't make a lot
 of sense in this case - it's just so you see producing/consuming of messages).

---

## Saving to datomic

When we consume the messages that we've produced they will be in the same format
 we used to produce (obviously), that is a wire schema. We need an adapter 
function to convert a wire schema to our inner schema. This function will be 
called on the consumer.

Now that we have an inner representation of the data we can send this data to a 
controller function. This new flow is simpler, we just need to store the data on
 datomic, the functions to do that are in namespaces under `service.db.datomic`.

There is a little problem with this topic we are consuming. Our flow is not 
idempotent. If we consume the message more than one time we will either insert 
the record twice (with different ids) or it will throw an exception when 
inserting the second time (if our inner schema has an unique field). For our 
solution choose one the fields (the one that makes more sense for that) of the 
schema and declare it as unique: just add `:unique true` to the schema. Now when
 we consume the topic twice it will throw an exception. An ok way to avoid that 
is to wrap the datomic insert function in a `try catch` statement, so the rest 
of the code don't have to care about it.

---

## Endpoint for getting the data

Now let's add a new endpoint for querying the data we inserted. We'll query 
datomic using the id you made unique in the schema. The user will send this 
id in the url path. Take a look 
[here](https://github.com/nubank/savings-accounts/blob/master/src/savings_accounts/service.clj)
 to see how this extracting looks like.

When we extract data from the url we get just a string, and that's sad because 
we need an `UUID`. Fortunately we have an pedestal interceptor that does this 
conversion automatically for us. We just need to add it to the interceptor list 
at the `services` namespace. Take a look in the link above to find this
interceptor.

You'll have to find another usefull interceptor now. We don't directly use the 
datomic component to fetch data, we get a snapshot from the database using the 
`common-datomic.db.db` fn and with this snapshot we query for data. There is a 
interceptor that already gives the snapshot to the handler. The main advantage 
of this approach is that it's automatically clear if an endpoint will change 
anything in the database or just query it. Take a look in the link above to find
 this interceptor.
 
Remeber that you should use convert the data to a wire schema before replying 
the request.

---

## Testing

Even though running code in the repl is great, automated tests are even better. 
We'll write two types of tests: unit(midje) and integration(postman) tests.

A good place to understand our way of writing is the README of our 
[common-test](https://github.com/nubank/common-test)

Before writing to many tests we should change a thing we did in the  beggining 
of this exercise. We added the s3 component to the base layer of components, 
but hitting s3 for unit and [inner] integration tests is not very good. 
Fortunatelly we have a mock component for s3. We can add this mock component 
to run just when we are running local tests by adding a new entry in the 
`test` fn on the `components` namespace. We just need to add the same name we
 did in the `base` fn and now use the 
[mock component](https://github.com/nubank/common-db/blob/master/src/common_db/components/mock_s3_store.clj).

### Unit tests

The tests files follow the same structure as the "real code", the two 
differences are:
- instead of being in the `src` folder they are in the `test` folder
- the test files add the suffix `_test` in the end of the file name (and before 
`.clj`). Also the namespace has a `-test` suffix.

We should write tests for all functions in the `logic`, `adapters`, `datomic` 
namespaces. If on the `service`, `consumer` and `producer` namespaces you are 
doing anything out of the ordinary or are not felling very confortable about 
some function you should also add tests to them.

Use `s/with-fn-validation` every time that you can. Be aware that midje's 
metaconstant break these validations. Also, ALWAYS test logic functions with 
schema validation and no stubs or mocks.

Controllers tests are a bit more controversial. Some people like to have them, 
others think they should be avoided because they don't have a big upside and 
require labor intensive work when the code is changed.

### Integration test

Take a look at this [postman test](https://github.com/nubank/savings-accounts/blob/master/postman/postman/account_creation.clj)
to get familiarized to the way we write integration tests.

The integration tests go in `postman/postman/` folder.

You should add one postman test that will ensure that the whole flow is working:
- caching locally and processing avro files
- producing and consuming kafka messages
- saving to datomic
- receiving and answering http request
- querying datomic

Since you are using the mock component for s3 we should add some mock data there
 so we have something to download from s3. This component is a regular s3 
component, you can use the methods defined in the s3 protocol for saving data.
For a better code organization you can separate this function to an auxiliary 
namespace.

For triggering an endpoint you can use the same functions as in `service-test`. 
To see if a message was produced to kafka you can use the function 
[log-messages](https://github.com/nubank/common-test/#kafka). Make sure you call 
 `common-test.postman.helpers.kafka/clear-messages!` in the `aux/init` function.

---

## Run the service locally

Before you run we should make some small changes to make the process a bit more 
interesting:
- comment the s3 mock component in the `test` environment. In this way your 
service will use the `base` s3 component, which will actually hit Amazon's s3.
- in the function that inserts the data on datomic do a `#nu/tapd` in the unique
 field. This will give some visibility on the insertions and you can later use 
these ids in the query endpoint.

Running a service is pretty straight forward with 
[nudev](https://github.com/nubank/nudev). First of all in this repo add your 
service to the `UNFLAVORED` list on `nustart.d/nustart/lein_service.rb` (this is
 related to the structure we're using in the `components.clj`).

Before running any service you need to ensure the dependencies of the service 
are up. Running `dev-env-compose up -d` on a terminal starts a Kafka, Datomic, 
Redis and Zookeeper. To start your service run `dev-compose up -d service-name`.
To see the logs run `dev-compose logs -f service-name`.

If you don't see anything weird (no logs or stack traces) in the logs your 
service is probably running ok. To make sure it's running do a 
`curl localhost:port/api/version`. This should return `{"version":"MISSING"}`. 
You can get the port by looking the `dev_port` in the 
`resources/service_config.json.base` file.

If everything goes fine you can hit the endpoint that consume the data from s3. 
After that hit the endpoint to get the entity that was inserted.

You finished it, but our princess is in another castle. Now you need to go to 
the real world!.

---

# Study materials

First of all read this: [https://github.com/nubank/data-infra-docs/blob/master/primer.md](https://github.com/nubank/data-infra-docs/blob/master/primer.md)
