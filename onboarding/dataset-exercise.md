# Onboarding Exercise Part I: Creating a Dataset

The goal of this exercise is to make you familiar with data-infra specific technologies. It's going to touch our core abstraction the [**SparkOp**](https://github.com/nubank/common-etl/blob/master/src/main/scala/common_etl/operator/SparkOp.scala) ** (short for spark operation) ** and guide you through how to write a new SparkOp, how to run it on Databricks and to consume it in a Clojure service.


 **TODO - Creating the Dataset**

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


---

First make sure you have access to [**databricks**](http://nubank.cloud.databricks.com), then there's this [Databricks Tutorial](https://docs.databricks.com/spark/latest/gentle-introduction/for-data-engineers.html) , designed for giving you a introduction to Spark running on Databricks, open the tutorial and click on `copy this link to import this notebook!` and click on `Import Notebook`. Copy the URL, then import into [Databricks](https://nubank.cloud.databricks.com)

![Import into Databricks](https://user-images.githubusercontent.com/1674699/33720480-594ffaec-db64-11e7-96b5-ec6a78a4cbae.png)

Go through that notebook and come back here :)

## Statement

---

Nubank has a problem with dealing with bills. For some unknown reason, it has become really difficult to query what is the due amount of past bills for a given customer. To solve this issue, we want to create a new service that will read data produced by the ETL, build a cache from it, and serve the data using a GraphQL API.


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

It does! So now do the same thing to figure out which **dimension ** should we use to join to the **customer_key and due_date_key** column.

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

You're probably questioning WTF is a SparkOp :), you can look by yourself [HERE](https://github.com/nubank/common-etl/blob/master/src/main/scala/common_etl/operator/SparkOp.scala#L7)

Feel free to see some [examples of datasets](https://github.com/nubank/itaipu/tree/master/src/main/scala/etl/dataset) that extend SparkOp, in special (for this onboarding) the datasets: [BillingCycleFact](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/dataset/fact/BillingCycleFact.scala), [CustomerDimension](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/dataset/dimension/CustomerDimension.scala) and [DateDimension](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/dataset/dimension/DateDimension.scala).

SparkOp is the core abstraction behind our data-platform, the important things are:

 **Name:** You have to grant your dataset a name so others can use your dataset as dependency

 **Inputs:** The list of inputs that you're going to need, you just need the name of them, and you can find which are the name of your dependencies by looking at its SparkOps

 **Definition:** That's where the magic happens, the inputs above are going to get injected at runtime to this function in this **Map[String, Dataframe]** so the name of your input is the key on the map and its Dataframe is the value.

 **Format:** That's where you define which format you're going to get as output, in our case let's use [**Avro**](https://avro.apache.org/docs/1.2.0/) because it'll be easier to consume from the service side.

So now import the **SparkOp** trait on Databricks:

 `import common_etl.operator.SparkOp`

and create a new `object` that `extends` the `SparkOp` and implement the methods :)

---

## Run the SparkOp on Databricks

Once you have your SparkOp done, you can use the function on [DatabricksHelpers](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/databricks/DatabricksHelpers.scala#L40) and run:

 `DatabricksHelpers.runOpAndSaveToTable(spark, op, "**schema**", "the_name_of_dataset")`

 `**schema**` usually we use our own names as the schema when saving the table to Databricks.
 
 ![Databricks Schema](../images/databricks_schema.png)

Run it! And then query your dataset to see if everything is nice!

To make it easier to do the service exercise save the avro files to s3 once again (itaipu will do that, but we're doing it again in case anything goes wrong there). This will save the dataset on `s3://nu-spark-devel/onboarding/**schema**/`:

```
import com.databricks.spark.avro._

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

And then is basically writing normal tests, for reference you can check the [CustomerTagsLogSpec](https://github.com/nubank/itaipu/blob/6b73228/src/test/scala/etl/dataset/CustomerTagsLogSpec.scala#L8).

[Running the tests](https://github.com/nubank/data-infra-docs/blob/master/itaipu/workflow.md#running-tests)

---

## Build Itaipu locally

Time to run it!

Make sure that you were added to the `data-infra` group on `quay.io` (**#access-request**). We use Docker for basically running everything here at Nubank, so it's not a surprise that you'll need to build Itaipu's docker container.

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

In the following steps, we're going to use just a single command that looks like:

`sabesp --aurora-stack=cantareira-dev jobs ...`

Which translates to create a job on the `cantareira-dev` stack. All jobs definition are inside the [aurora-jobs](https://github.com/nubank/aurora-jobs) project. If you don't have `aurora-jobs` cloned, please do it (inside the $NU_HOME directory), because `sabesp` will look for the definitions from there. Also, make sure that you were added to the *data-infra-aurora-access* group in aws (**#access-request**).

#### Scale, Run and downscale the Cluster

Using the up-to-date version of `sabesp`, you should be able to scale, run and downscale the cluster using just one command, what makes everything simpler:

`sabesp --aurora-stack=cantareira-dev jobs itaipu staging **your_name** s3a://nu-spark-metapod-test/ 100 --itaipu=**repository_tag** --filter-by-prefix **dataset_name**`

eg:
`sabesp --aurora-stack=cantareira-dev jobs itaipu staging rodrigo s3a://nu-spark-metapod-test/ 100 --itaipu=be24227a --filter-by-prefix dataset/on-boarding-exercise-part-i`

You can check if the instances are running on the [AWS Console](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:tag:Name=cantareira-dev-mesos-on-demand-;sort=instanceId) and check the status of your jobs [here](https://cantareira-dev-mesos-master.nubank.com.br:8080/scheduler/jobs). Now wait, it might take a while.

If your proccess fails, you can run the same command again adding your `transaction_id`. The proccess will start again from where it stopped.

eg:
`sabesp --aurora-stack=cantareira-dev jobs itaipu staging rodrigo s3a://nu-spark-metapod-test/ 100 --itaipu=be24227a --filter-by-prefix dataset/on-boarding-exercise-part-i --transaction 56078219-e6e0-43ec-a7a0-0bcc59600473`

#####**Make sure that your [AWS instances are terminating](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:tag:Name=cantareira-dev-mesos-on-demand-;sort=instanceId) at the end of the proccess**.

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

## Next up

_Part II_ of the exercise, ["Creating a service to expose a dataset via API"](service-exercise.md), is building a Nubank microservice to serve data from the dataset you created in this page.
