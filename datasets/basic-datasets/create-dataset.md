---
owner: "#Analytics-productivity"
---

<!-- markdownlint-disable-file -->

# Step 1 - Create SQL query in Google Big Query or Databricks
***

## Google BigQuery

For exploring data and creating an SQL query, it is recommended to use Google BigQuery. You can also use Databricks for this purpose, and the steps on how to use it are provided in the following sections.

1. Go to [Google BigQuery](https://console.cloud.google.com/bigquery?project=nu-mx-data&p=nu-br-data&page=project). Note that to explore data and create a query, you must have view access to the projects `nu-br-data`, `nu-mx-data`, `nu-co-data`.
1. Choose projects and select datasets or contracts with which you want to create your dataset.
1. Create your query in the **Query editor** text area and run it. In Query search results, if you have the desired data in the dataset (table), then move to the next step - [Understanding the SparkOp class](#understanding-the-sparkop-class).

## Databricks
1. Go to `https://nubank.cloud.databricks.com/` and create your own Notebook. 

![](../../images/create_new_dataset_on_databricks.png)

2. Enter a meaningful name for your Notebook. You can name your notebook based on the task you're performing. In this Tutorial, we will be checking the calls from Ouvidoria.
3. Select the notebook's default language as `Scala` and cluster can be any one of the `general-purpose-*` (for intance, `general-purpose-1`).

When you click **create** a new notebook is created and is associated with the cluster selected during the notebook creation process.

**Note:** In Databricks Notebook, if you want to use another language that isn't the default, you can simply begin your block with %name_of_language. For example, let us create a simple query to check on the calls from Ouvidoria. It will be our example throughout the tutorial.

As we are querying the calls using SQL, the block in your notebook should begin with `%sql` as shown below:

```sql
%sql
SELECT calls.call__started_at AS time
     , calls.call__id AS call_id
     , calls.call__our_number AS our_number
     , calls.call__reason AS reason
  FROM contract.stevie__calls AS calls
 WHERE calls.call__started_at > '2017-02-01'
   AND calls.call__reason IS NOT NULL
   AND calls.call__our_number = '08008870463'
```

When you run this query, it should return a table with atmost 1000 rows.

## Understanding the SparkOp class
***

In the following SparkOp is a recipe for Spark transformations. In Itaipu context, the "dataset" is an interchangeable term for SparkOp and every dataset you find in Itaipu is a SparkOp.

The SparkOp class has six important parts:

- `name` property. It decides how your new dataset will be called in places such as Looker or Databricks once Itaipu runs. If `name = "dataset/name-of-dataset"`, then you'll be able to find it by querying dataset.name_of_dataset.

- `description` property. Description of what the dataset does, and why. This is useful to avoid confusion and help users to understand your dataset.

- `inputs` property. This is a set with the names of all the datasets you'll use in your query. **DON'T HARDCODE THEM.** Use the values we'll set further on.

- `definition` method. This is the core of your object. All the logic involved in creating your dataset will be placed here. Well, hopefully not **all** your logic, because you'll divide your code neatly into small functions that can be easily tested, won't you? Good.

- `attributes` property. This Set contains the definition of what your output will be. The column names, if any field is primary key or not, if it is nullable, the column **description** field etc.

- `ownerSquad` property. That's the squad that owns that dataset.

- `warehouseMode` property. This is optional, and you should only set it to make your new dataset available for querying on the data warehouse (BigQuery).

- dataset names section. Here we'll get all the names of all the datasets we'll use and place them on variables with clear names. The reason why we do so will become apparent eventually.

### Tips to follow during dataset creation
***
The following are the recommended tips to follow to avoid dataset failure during the run and have a smooth data flow in your service.

- It's recommended to create a dataset that don’t depend on too many datasets.
- It's recommended to use core datasets as an input for your dataset.
- It's recommemded to use Compass tool to check the available datasets, column names, descriptions, types. Note that this tool displays datasets that are created with declared schema.
- It's recommended to use [Difizinho](https://github.com/nubank/difizinho/blob/master/docs/GUIDE.md) tool to compare previous dataset with new dataset that is generated.
- It's a **mandatory step** to ensure that your dataset pass through all the points mentioned in the [verification check list](dataset-verification-checklist.md).

## Step 2 - Create the SparkOp Class & transform your SQL query into Scala code
***
1. In IntelliJ, go to `src/main/scala/etl/dataset` and see what folders are available. Choose your folder or, if there is none that fits your dataset, create a new one.

1. In that folder, create a new Scala class with the name of your new Dataset. The example below is a good template to follow.

_*Tip: you can add this to your IntelliJ templates by going to `IntelliJ > Editor > File and Code Templates` and save it with `Name: ETL - Scala Object` and `Extension: scala`*_

```scala
package etl.dataset.${PACKAGE_NAME}

import etl.static.StaticOp

// if you are going to use some contract
import etl.contract.DatabaseContractOps
import etl.contract._folder_._contractFileName_

// If you are going to use some dataset, you need to import it if it isn''t on the same folder
import etl.dataset._folder_._subfolder_._datasetFileName_

// Imports you'll probably use. Remove the ones you don't, afterwards. 
import java.math.BigDecimal
import java.sql.{Date => SQLDate}
import java.text.SimpleDateFormat
import java.time.LocalDate
import java.util.{Date, UUID}

import common_etl.implicits._
import common_etl.metadata.{Country, Squad}
import common_etl.metadata.Squad.SquadName
import common_etl.metapod.{Attribute, MetapodAttribute}
  import common_etl.operator.{SparkOp, WarehouseMode}
import common_etl.schema.{DeclaredSchema, DistConf, LogicalType}

import org.apache.spark.sql.{DataFrame, Row}
import org.apache.spark.sql.expressions.Window
import org.apache.spark.sql.functions._

object ${NAME} extends SparkOp with DeclaredSchema {
  //This is how you`ll access this database in the future, in Bigquery or Databricks
  //It must be on the form prefix-you-want-name-of-your-dataset
  override val name = "dataset/name-of-your-dataset"
  
  //Description of what the dataset does
  override def description: Option[String] = Some("Description Here")
  
  override val country = Country.BR
  
  //This sets the name of the squad who owns the dataset.
  //If your squad isn't in common_etl.metadata.Squad, please add it
  override val ownerSquad: Squad = SquadName

  //Optional. This is how you make the dataset available on BigQuery for querying
  override val warehouseMode: WarehouseMode = WarehouseMode.Loaded
  
  override val inputs: Set[String] = Set(fooName, barName, bazName)
  override def definition(datasets: Map[String, DataFrame]): DataFrame = {
    val foo = datasets(fooName)
    val bar = datasets(barName)
    val baz = datasets(bazName)

    myFunc(foo)
  }

  override def attributes: Set[Attribute] = Set(
    MetapodAttribute("some__id", LogicalType.UUIDType, nullable = false, primaryKey = true, description = Some("")),
    MetapodAttribute("another__id", LogicalType.UUIDType, nullable = false, description = Some("")),
    MetapodAttribute("some_amount", LogicalType.DecimalType, nullable = false, description = Some("")))

  // Defining a function in Scala
  def myFunc(df: DataFrame): DataFrame = df

  // If you want to use a contract, you get its name like this
  def barName: String = DatabaseContractOps.lookup(contractFileName).name
  
  // If you're using just another dataset, get the name like this
  def bazName: String = datasetFileName.name
  
  // Don't do this. Only villains do that.
  def fooName: String = "dataset/foo"
}
```
We'll explain everything that's in there in a bit. For now, just copy the contents of this file you've created, except the `package etl.dataset.${PACKAGE_NAME}`, into a new block in Databricks.

### Step 2.1 - Transform your SQL query into Scala code
***

Jump back to your Databricks notebook and copy your SparkOp class to a new cell. As mentioned earlier that there are different ways to create a dataset, the following example explains the creation of dataset using contracts.(Leave the package declaration out of it) e.g:

If you want create a dataset where input for that is another dataset, you can then use the [Compass tool](https://backoffice.nubank.com.br/compass/#search) to find and understand datasets. You can search by datasets, columns and their descriptions. Each dataset also has a details page, where users can find descriptions for all columns, column types, dataset description and a link to access it on BigQuery. Currently, the tool has a limitation and only displays datasets with declared schemas.

#### Create dataset using contract

```scala
import ...
import nu.data.br.dbcontracts.stevie.entities.Calls
//This is to use data available in the `nu.data.br.dbcontracts.stevie.entities.Calls` contract. For this tutorial we'll use `ContractOp` and `Calls` data.
object OuvidoriaCalls extends SparkOp with DeclaredSchema {
  override val name = "dataset/ouvidoria-calls"
  override def description: Option[String] = Some("Dataset to list all calls made to Nubank's Ouvidoria.")
  override val country = Country.BR
  override val ownerSquad: Squad = Squad....
  override val inputs: Set[String] = Set(callsName)

  override def definition(datasets: Map[String, DataFrame]): DataFrame = {
    val calls = datasets(callsName)
    
    filterCalls(calls)
  }
  
  def filterCalls(calls:DataFrame) : DataFrame = {
  
  }
  
  override def attributes: Set[Attribute] = Set()

  def callsName: String = Names.contract(Contract)
}
```
#### Step 2.2 - Write the SparkOP definition

1. Let's create a dataset that lists the calls made to the Nubank's Ouvidoria. For this we use  `Calls` `ContractOp`, located at `nu.data.br.dbcontracts.stevie.entities.Calls`.
1. Give a meaningful name to your dataset and provide description as shown in the above excerpt. Name of the dataset - "ouvidoria-calls" and description - "Dataset to list all calls made to Nubank's Ouvidoria".
 1. Then we need to define a function in Scala.

**`filterCalls` function**

We define `filterCalls` function and call the function by passing the `calls` Dataframe. But right now the `filterCalls` function is empty and that `filterCalls` function is where we'll put our logic.

#### Step 2.3 - Create a query in scala code on calls dataset

**`WHERE` in SQL to Scala code**

Let us add the first part of our `WHERE` and create a query on calls dataset.

```scala
def filterCalls(calls:DataFrame) : DataFrame = {
    calls where $"call__started_at" > "2017-02-01"
}
```
 There are a few things going on here, so let me break it down.
 
 ||
 |--|
 |**First**, there is **no `return` keyword** in the code. This is because Scala can return the last line or expression of the function as a result.|
 |**Second**, there is nothing connecting `calls` to `where`. This is because Scala does not care for `.`. `where` is a function of `calls` and we can use **`calls where`** in exactly the same way.|
 |**Third, where are the parentheses?** this isn't Clojure. Often times in Scala, parentheses are optional. For instance, If the function you're calling receives only one parameter, then parentheses can be removed.|
 |**Fourth**, what's up with the **`$"call__started_at"`**? That is our very special way of referencing columns. It basically means "Hey, go into the table you're in and get the column named call__started_at". However, you can also do it like this: **`calls("call__started_at")`**. The result is the same, and sometimes the second notation is **necessary**, such as when you're working on **joins of tables with columns with the same name**.|
 |**Fifth**, you can't compare a whole column to a string! That's not how types work! Why, yes you can. This is because `>` is actually a function, and that little space over there is actually a hidden `.`, just like in the `where` case above! `$"call__started_at" > "2017-02-01"` returns you which the lines of the column where the condition is true, comparing it value by value.|
 
 Now, let's add the second part of our SQL's `WHERE`, the `AND calls.call__reason IS NOT NULL`:
 ```scala
 calls where $"call__started_at" > "2017-02-01" and $"call__reason".isNotNull
 ```
If you're testing it in IntelliJ instead of just copy-pasting it, you'll see that there's an error. It can't resolve the symbol `and`. Why? Because it doesn't know if you're trying to call `where($"call__started_at" > "2017-02-01").and()` or  `where(($"call__started_at" > "2017-02-01").and())`. We solve that by adding parenthesis on the right spots:
```scala
calls where($"call__started_at" > "2017-02-01" and $"call__reason".isNotNull)
```
Beautiful. Now onto `AND calls.call__our_number = '08008870463'`.
```scala
call where($"call__started_at" > "2017-02-01" and $"call__reason".isNotNull and $"call__our_number" === "08008870463")
```
Note that you don't compare the column of a dataset to a string. Therefore, the `===` sign is used to compare each entry of the column individually with the string, and returns to you the entries that match.

And with that, our `WHERE` is done. Before we move on to the `SELECT`, lets break the line to find another problem.
```scala
call 
  where($"call__started_at" > "2017-02-01" and $"call__reason".isNotNull and $"call__our_number" === "08008870463")
```
If we do this, Scala won't recognize that `where` is a function call, so let's just wrap it all up with a couple of parenthesis.
```scala
(call 
  where($"call__started_at" > "2017-02-01" and $"call__reason".isNotNull and $"call__our_number" === "08008870463"))
```
**`SELECT` in SQL to Scala code**

Then onto our select. We need the columns `calls.call__started_at`, `calls.call__id`, `calls.call__our_number` and `calls.call__reason`. Here is the scala code:
```scala
(call 
  where($"call__started_at" > "2017-02-01" and $"call__reason".isNotNull and $"call__our_number" === "08008870463")
  select($"call__started_at",  $"call__id", $"call__our_number", $"call__reason"))
```
**Rename column**

Now we need to rename the columns. The Dataset object has the method `.withColumnRenamed` which allows you to rename any column you want, but an easier way is to use the Column method `.as`.
```scala
(calls
      where($"call__started_at" > "2017-02-01" and $"call__reason".isNotNull and $"call__our_number" === "08008870463")
      select($"call__started_at" as "time",  $"call__id" as "call_id", $"call__our_number" as "our_number", $"call__reason" as "reason"))
```
Boom! Your definition is done!

We're still not done, though. We now need to define what exactly are the types of the columns we want as output.

#### Step 2.4 - Define output of your SparkOP
***
 In our `definition` method, we need to define the exact types of the columns we want in our output. We do that using the `attributes`.
 
Take a look at the [LogicalType](https://github.com/nubank/common-etl/blob/master/src/main/scala/common_etl/schema/LogicalType.scala) class. It has all the types of objects you can have in your table. Our first field will be the `call_id`, which will be the primary key. As for the type, we check in the [Calls Contract](https://github.com/nubank/itaipu/blob/d0755724ceb7c40c36e9f670edb2cb505c3f3848/src/main/scala/nu/data/br/dbcontracts/stevie/entities/Calls.scala) and see that the column `call__id` is of type UUIDType.

```scala
 override def attributes: Set[Attribute] = Set(
    MetapodAttribute("call_id", LogicalType.UUIDType, primaryKey = true)
  )
```
Next, the `time` column and the `our_number` column. They come, respectively, from the `call__started_at` and `call__our_number` columns in Calls, which are TimestampType and StringType.
```scala
 override def attributes: Set[Attribute] = Set(
    MetapodAttribute("call_id", LogicalType.UUIDType, primaryKey = true),
    MetapodAttribute("time", LogicalType.TimestampType),
    MetapodAttribute("our_number", LogicalType.StringType)
  )
```
Then... there is the reason field. The reason field is a bit different, because it is an EnumType. That means it has a restricted range of values it can posses. You *could* just copy and paste the values for it from the contract definition, but that would be **bad**. If someone ever alters the contract, your class will be broken. So we won't do that.
Instead we will get the possible values of the EnumType like this:
```scala
MetapodAttribute("reason", LogicalType.EnumType(enums = Calls.attributes.find(_.source == "call__reason") match {
      case Some(EnumAttribute(_, _, _, _, LogicalType.EnumType(possibleReason), _, _)) => possibleReason
      case _ => throw new Exception("Invalid Attribute in Calls")
    }))
```
Yeah, it isn't pretty, and we'll probably do something to wrap it neatly in a function in the future, but for now we got nothing.

Also, let's put a description on those fields, so to let people know what they're all about.

That finishes our definition.

## Solution Scala code
```scala
package etl.dataset.collections
import common_etl.implicits._
import common_etl.metadata.{Country, Squad}
import common_etl.metapod.{Attribute, MetapodAttribute}
import common_etl.operator.{SparkOp, WarehouseMode}
import common_etl.schema.{DeclaredSchema, LogicalType}
import nu.data.br.dbcontracts.stevie.entities.{Calls, DialerCalls, DialerEvents, DialerRequests}
import nu.data.infra.api.datasets.v1.Names
import org.apache.spark.sql.DataFrame
import org.apache.spark.sql.expressions.Window
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types.{TimestampType => SQLTime}

object OuvidoriaCalls extends SparkOp with DeclaredSchema {
  override val name = "dataset/ouvidoria-calls"
  override def description: Option[String] = Some("Dataset to list all calls made to Nubank's Ouvidoria.")
  override val country = Country.BR
  override val ownerSquad: Squad = Squad.AnalyticsProductivity
  override val inputs: Set[String] = Set(callsName)
  override val warehouseMode: WarehouseMode = WarehouseMode.Loaded
  
  val dateToSearch = "2017-02-01"
  val phoneToFilter = "08008870463"

  override def definition(datasets: Map[String, DataFrame]): DataFrame = {
    val calls = datasets(callsName)
    filterCalls(calls)  
  }
  def filterCalls(calls:DataFrame) : DataFrame = {
    (calls
      where($"call__started_at" > dateToSearch and $"call__reason".isNotNull and $"call__our_number" === phoneToFilter)
      select($"call__started_at" as "time", $"call__id" as "call_id", $"call__our_number" as "our_number", $"call__reason" as "reason"))
  }

  override def attributes: Set[Attribute] = Set(
    MetapodAttribute("call_id", LogicalType.UUIDType, nullable = false, primaryKey = true, description = Some("Unique, UUID for each call")),
    MetapodAttribute("time", LogicalType.TimestampType, nullable = false, description = Some("UTC Timestamp for when the call started")),
    MetapodAttribute("our_number", LogicalType.StringType, nullable = false, description = Some("The number called to contact us")))

  def callsName: String = Names.contract(Calls)
}
```
We've removed the date and the phone number we're searching for and put them into variables, se we don'have any "magical numbers" floating around. This way, if we ever need to change it, we won't have to scour the whole code looking for them.

## Step 3 - Run your dataset on Databricks
***
Great! Run it on Databricks and see if it runs smoothly. Let's check it and see if we haven't done anything wrong.

The [DatabricksHelpers](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/databricks/DatabricksHelpers.scala) class has few functions that can help us check if everything is alright with our Dataset. You can just run it and save it on memory with
```scala
import etl.databricks.DatabricksHelpers
val table = DatabricksHelpers.opToDataFrame(spark, OuvidoriaCalls)
display(table)
```
Or we can save it in a table in Databricks, so we can query it normally with SQL:
```scala
import etl.databricks.DatabricksHelpers
DatabricksHelpers.runOpAndSaveToTable(spark, OuvidoriaCalls, "your_folder_name", "ouvidoria_calls")
```
```sql
select * from your_folder_name.ouvidoria_calls
```
If check if everything looks good, if the table you just generated has the same amount of rows as the one you created with sql, etc. Check to see if it really does what you think it does.
Does everything look good? GREAT! Copy that beauty back into IntelliJ and format it using scalafmt!

But you're still not done. There are tests to be done.

## Step 4 - Use Difizinho tool for Validation

Use [Difizinho](https://github.com/nubank/difizinho/blob/master/docs/GUIDE.md) tool to compare previous dataset with new dataset that will be generated.

## Next Steps

After you create dataset, you must:
- [Write test cases](testing-dataset.md)
- [Run tests](testing-dataset.md)
- [Validate your dataset against verfification checklist](dataset-verification-checklist.md)
- [Create a PR and add it to Itaipu for review](testing-dataset.md)
