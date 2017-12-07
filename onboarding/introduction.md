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

 **TODO:** explain this better

- Kafka
- Datomic
- Clojure
- Spark
- AWS

# Exercise

The goal of this exercise is to make you familiar with Nubank's infra-structure, and also with data-infra's specific technologies. It's going to touch our core abstraction the [**SparkOp**](https://github.com/nubank/common-etl/blob/master/src/main/scala/common_etl/operator/SparkOp.scala) ** (short for spark operation) ** and guide you through how to write a new SparkOp, how to run it on Databricks and to consume it in a Clojure service.

---

First make sure you have access to [**databricks**](http://nubank.cloud.databricks.com), then there's this [Databricks Tutorial](https://docs.databricks.com/spark/latest/gentle-introduction/for-data-engineers.html) , designed for giving you a introduction to Spark running on Databricks, open the tutorial and click on `copy this link to import this notebook!` and click on `Import Notebook`. Copy the URL, then import into [Databricks](https://nubank.cloud.databricks.com)

![Import into Databricks](https://user-images.githubusercontent.com/1674699/33720480-594ffaec-db64-11e7-96b5-ec6a78a4cbae.png)

Go through that notebook and come back here :)

## Statement

---

Nubank has a problem with dealing with bills, for some unknown reason, it has become really difficult to query what's the due amount of past bills for a given customer. To solve this issue We want a new service to be created, that's going to read data produced by the ETL to build a cache and serve the data using a GraphQL API.

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
- [ ]  Creating a component to read the dataset files from S3
  - [ ]  Make a request to metapod to get the list of paths for the dataset written
  - [ ]  Read the avros from S3
- [ ]  Create a **producer** to publish each row of the dataset
- [ ]  Create a **consumer** to read the published messages and persist to datomic
- [ ]  Create a graphql API for the Bill information

## Creating the Dataset

---

 **Figure out which Datasets should we use to build the derivative dataset** 

For this basically, you want information about, the customer and their bills. We organize our data-warehousing into facts and dimensions, using the terminology from [Kimball](https://github.com/nubank/data-infra-docs/blob/master/dimensional_modeling/kimball.md) 's DW books. 

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

But... it's SQL and we shouldn't throw SQL out to other people have to read, because we're nice with each other.

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

**IMPORTANT**: We just want a sample of the data, otherwise adding it to Kafka and datomic would take forever, so just add the `.sample(false, 0.002)` to the end of your definition, this you give you around 50k records.

More information about creating a new dataset [HERE](https://github.com/nubank/data-infra-docs/blob/master/itaipu/workflow.md#creating-a-new-dataset) : 

---

## Writing tests to the Dataset

For writting test we use two libraries, [ScalaTest](http://www.scalatest.org/) and [SparkTestingBase](https://github.com/holdenk/spark-testing-base) .

Fist create a class in the same package as your dataset, but changing from `main` to `test` and adding `Spec` to the end of the name.

add the following extensions to your class 

 `extends FlatSpec with NuDataFrameSuiteBase with Matchers` 

And then is basically writing normal tests, for reference you can check the [BillingCyclesSpec](https://github.com/nubank/itaipu/blob/master/src/test/scala/etl/dataset/billing_cycles/BillingCyclesUnsafeSpec.scala#L11) 

 [Running the tests](https://github.com/nubank/data-infra-docs/blob/master/itaipu/workflow.md#running-tests) 

---

## Build Itaipu locally

Time to run this it!

We use Docker for basically running everything here at Nubank, so it's not a surprise that you'll need to build Itaipu's docker container.

To do that just to:

`$NU_HOME/deploy/bin/docker.sh build-and-push $(git rev-parse --short HEAD)`

The docker.sh script is inside the `deploy` project, it's just a standard script for building docker images. It'll run the script `prepare.sh` (which will run `sbt assembly`) and then run `docker build .` then docker push using the name of your project as the name of the container. For Itaipu, it'll basically be `quay.io/nubank/nu-itaipu:{SHA}`

Done, now we can run it.

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

`sabesp --aurora-stack=cantareira-dev jobs create prod scale-ec2-/suffix/ SLAVE_TYPE=/suffix/ NODE_COUNT=16 --job-version="scale_cluster=d749aa4" --filename scale-ec2 --check`

This command basic translates to using the `scale-ec2` definition on aurora-jobs We're going to create the scale-up job that with 16 instances and using the version `d749aa4`, all those binds `VAR=value` translates to binds on the aurora-jobs those binds replace the mustaches `{{}}` in the file.

You can check if the instances are running on the AWS Console: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:search=Name:cantareira-dev-mesos-on-demand-*;sort=instanceId

#### 2. Run Itaipu

Wow, it's a huge command, but for Itaipu We need to set a bunch of parameters, eg: METAPOD_REPO=where I'm going to write this thing, CORES=how many cores is spark allowed to use, TARGET_DATE=When is this run happening. REFERENCE_DATE=what's the reference for the data being generated (usually is from yesterday). and so on.

d`sabesp --verbose --aurora-stack=cantareira-dev jobs create staging itaipu-/suffix/ --job-version="itaipu=$(git rev-parse HEAD --short)"  METAPOD_REPO=s3a://nu-spark-metapod-test TARGET_DATE=$(date --iso-8601) REFERENCE_DATE=$(date --iso-8601) DRIVER_MEMORY=26843545600 CORES=96 OPTIONS="filtered,dns" METAPOD_TRANSACTION=`uuidgen` METAPOD_ENVIRONMENT=prod SKIP_PLACEHOLDER_OPS="true" DATASETS="dataset/**THE_NAME_OF_YOUR_DATSET**" ITAIPU_SUFFIX=/suffix/ DRIVER_MEMORY_JAVA=22G --filename itaipu`

All those variables could seem magical defined, but actually, if you remove one of them sabesp is going to complain that an argument is missing :).

And if you're scared of trying to run, you can add the `--dryrun` flag to sabesp, which will just inspect if everything is "right".

You can check the status of your job on https://cantareira-dev-mesos-cluster.nubank.com.br/scheduler/jobs/staging/itaipu-/suffix/, and if you click into the link on the IP address of the instance you'll see a link `spark-ui`, if you click there you'll see the `SparkUI` on which you can keep an eye on the execution process.


To check if the job has finished you can look at the aurora-ui, or add the `--check` flag on sabesp so it'll away until the job has finished.


#### 3. Scale down the Cluster

After the job has finished, we need to scale down the cluster.

`sabesp --aurora-stack=cantareira-dev jobs create prod downscale-ec2-/suffix/ SLAVE_TYPE=/suffix/ NODE_COUNT=0 --job-version="scale_cluster=/suffix/" --filename scale-ec2 --check`


You can check if the instances are terminating in the AWS Console: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:search=Name:cantareira-dev-mesos-on-demand-*;sort=instanceId

---

## Query metapod to get the path were the dataset was written to

[`Metapod`](https://github.com/nubank/metapod) is the service on which We track the metadata about t he run. So it has all information related to:
* Where the datasets were committed
* What are the dataset's partitions
* What's its schema
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

After you have the path for the dataset, let's read it on Databricks to check if everything is as expected.

So, go back to you notebook and read it.

For dealing with avros, we need to import one library:

`import com.databricks.spark.avro._`

and then read it.

```
val df = spark.read.avro("dbfs://mnt/your-path-without-s3://")
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

# Study materials

First of all read this: [https://github.com/nubank/data-infra-docs/blob/master/primer.md](https://github.com/nubank/data-infra-docs/blob/master/primer.md)
