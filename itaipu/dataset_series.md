# Dataset Series

## Background

At Nubank, Datomic is the main/preferred way to store data. But it's not the only one. Data that is high throughput is usually not stored on Datomic so as not to clutter it. While Itaipu [Contracts](contracts.md) are used as an entry point for data stored in Datomic, DatasetSeries are the mechanism we use in Itaipu to make high throughput events available for computation as input datasets.

| Input type     | Type of data                                                 |
| -------------- | ------------------------------------------------------------ |
| Contracts      | Datomic entities, historical attributes (e.g. Customer entity) |
| Dataset Series | High throughput attributes, very granular events (e.g. Click streams) |

#### Source of the data

Dataset series data is produced by services by calling the `common-schemata.wire.etl/produce-to-etl!` function ([source](https://github.com/nubank/common-schemata/blob/master/src/common_schemata/wire/etl.clj#L133-L137)) . The resulting data is then handled by the *Ingestion Layer* – a set of services linked to the `EVENT-TO-ETL` Kafka topic:

* The [Riverbend](https://github.com/nubank/riverbend) service is responsible for producing dataset series. It does so by consuming the `EVENT-TO-ETL` Kafka topic and serialising its messages to `.avro` files suitable for ingestion by Itaipu. A technical description for how data goes from Kafka all the way to being processed in Itaipu can be found in the [Annexes](#annexes) section
* The [Curva de Rio](https://github.com/nubank/curva-de-rio) service exposes an HTTP endpoint which allows services not connected to Kafka to send data to Riverbend.

## Using Dataset Series

In order to use the data from a Dataset Series in an Itaipu `SparkOp`, you'll first need to define a `DatasetSeriesOp`. In this Op you'll explicitly declare the schema ([why?](#why-do-i-need-all-these-different-schemas)) you expect to be receiving from the Series, as well as perform a number of standard data cleaning operations to make working with the data safer and more convenient.

### Creating a new dataset series

#### Code organization

Given a `DatasetSeriesOp` called `YourOp`:

* An `object` called `YourOp` extending `common_etl.operator.dataset_series.DatasetSeriesOp` should be placed in the `etl.dataset_series_2` [package](https://github.com/nubank/itaipu/tree/master/src/main/scala/etl/dataset_series_2). See [Code Generation](#code-generation) below for best practices on generating it from scratch.
* The object should be added to this package's `package.scala` file in the `allSeries` set [here](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/dataset_series_2/package.scala).

#### Code generation

A code generator helper can be found in `common-databricks`:

```scala
import common_databricks.dataset_series.DatasetSeriesOpGenerator
import common_databricks.DatabricksHelpers
import common_etl.metadata.Squad

val metapod = DatabricksHelpers.getMetapod()

DatasetSeriesOpGenerator.renderOp("your-series-name", 
                                  Squad.YourSquad,
                                  "description of your dataset series",
                                  metapod)

/* Output:

import common_etl.metadata.Squad
import common_etl.operator.dataset_series.{DatasetSeriesAttribute, DatasetSeriesOp}
import common_etl.schema.LogicalType

object YourSeriesName extends DatasetSeriesOp {

  override val seriesName: String = "your-series-name"

  override val ownerSquad: Squad = Squad.YourSquad
  override val description: Option[String]= Some("description of your dataset series")

  override val contractSchema: Set[DatasetSeriesAttribute] = Set(
    DatasetSeriesAttribute("index", LogicalType.UUIDType, description = Some("")),
    DatasetSeriesAttribute("attr1", LogicalType.StringType, description = Some("")),
    DatasetSeriesAttribute("attr2", LogicalType.IntegerType, description = Some(""))
  )

  override val alternativeSchemas: Seq[Set[DatasetSeriesAttribute]] = Seq(
    Set(
      DatasetSeriesAttribute("index", LogicalType.UUIDType),
      DatasetSeriesAttribute("attr1", LogicalType.StringType)
    ),
    Set(
      DatasetSeriesAttribute("index", LogicalType.UUIDType)
    )
  )
  
 */
```

Usage of the generator is highly recommended as it:

* Discovers for you all schemas existing in Metapod for your dataset series
* Follows the latest versions and idioms of the API

Feel free to use and copy the [example databricks notebook](https://nubank.cloud.databricks.com/#notebook/463279/command/463286) for this purpose.

#### Anatomy of a DatasetSeriesOp

###### `seriesName`

The name of your series, the same used by your service when posting data via the `common-schemata.wire.etl/produce-to-etl!` function ([source](https://github.com/nubank/common-schemata/blob/master/src/common_schemata/wire/etl.clj#L133-L137)).

###### `contractSchema`

What the final schema of your dataset series should be once it's done computing.

###### `alternativeSchemas`

Override this optional field to declare other existing schemas for your dataset series. Usually, these will be past versions which use obsolete names or datatypes. See [Dealing with Versions](#dealing-with-versions) for an overview of the version reconciliation metadata DSL.

#### Why do I need all these different schemas?

Over time, producers of the data in your dataset series ~~might~~ will introduce changes in its schema: adding/removing columns, renaming them, or even changing their types. Whenever a schema change is introduced, you will need to modify your `DatasetSeriesOp` accordingly to ensure that:

* it knows how to handle and reconcile the different schemas of your data
* aligns 100% with the schema *you* wish to pass down to downstream `SparkOps` (the `contractSchema` field)

### Dealing with versions

When your dataset series' schema has changed over time, you'll have to add metadata to your schema declarations so that the computing engine may reconcile them into the final contract version. When processing various versions, the engine:

* Looks for attributes with `transforms` fields and applies the transforms to these fields

  ```scala
  ...
  DatasetSeriesAttribute("field", LogicalType.IntegerType)
  	.withTransform($"field" + 10) // values of this field will have `10` added to them
  ...
  ```

  `withTransform` accepts any valid Spark `Column` expression.

  **NB**: don't abuse transforms; a `DatasetSeriesOp`'s primary purpose is to reconcile versions. Other logic can be implemented with a normal SparkOp consuming your `DatasetSeriesOp`

* Looks for attributes which do not exist in the `contractSchema` and tries to rename them to match an attribute from the `contractSchema`, using their `as` field:

  ```scala
  import org.apache.spark.sql.functions._
  
  ...
  val contractSchema = Set(
      DatasetSeriesAttribute("ndex", LogicalType.UUIDType, isPrimaryKey = true)
      			.as("index"),
      DatasetSeriesAttribute("user__id",
                              LogicalType.StringType)
  )
  
  val alternativeSchemas = Seq(
  	Set(
          // Will not be renamed as `ndex` is in the contractVersion
          DatasetSeriesAttribute("ndex", LogicalType.UUIDType, isPrimaryKey = true)
      			.as("index"),
          // Will be renamed prior to merging with other datasets, as `user__id` is
          // in the contract version
          DatasetSeriesAttribute("user_id",
                                 LogicalType.StringType,)
          	.as("user__id")
      )
  )
  ...
  ```

  See [Final Steps](#final-steps) for `as` fields declared on `contractSchema` attributes (which would be ignored in the above phase)

* Coerces the dataframe to the `contractSchema`:

  * Missing columns are added, and backfilled using the attribute's `defaultValue` (a `Column` expression) – `defaultValue` defaults to `lit(null)`

    ```scala
    import org.apache.spark.sql.functions._
    
    ...
    
    val contractSchema = Set(
        // Will be added to alternative version schemas which do not have
        // a `cpf` attribute, and backfilled with "N/A"
        // In schemas which do have it but with a different type, it will
        // be recast to string
        DatasetSeriesAttribute("cpf",
                               LogicalType.StringType,
                               defaultValue = lit("N/A"))
    )
        
    ...
    ```

  * Existing columns which match the contract by name but not by type are coerced to the contract's type. Coercions are currently supported for:

    * Number to number (e.g. double to decimal)
    * any to string
    * string to uuid-format string. If the original string cannot be parsed as a UUID, it will be converted to one using `java.util.UUID/nameUUIDFromBytes` ([source](https://github.com/nubank/common-etl/blob/master/src/main/scala/common_etl/operator/dataset_series/DatasetSeriesAttribute.scala#L53-L58))

  * Columns which do not appear in the contract are dropped

  ```scala
  import org.apache.spark.sql.functions._
  
  ...
  val contractSchema = Set(
      DatasetSeriesAttribute("customer__id", LogicalType.UUIDType, isPrimaryKey = true),
      DatasetSeriesAttribute("precise_amount", LogicalType.DecimalType),
  )
  
  val alternativeSchemas = Seq(
  	Set(
          // This will be automatically recast to UUID prior to
          // merging with other versions
          DatasetSeriesAttribute("customer_id",
                                 LogicalType.StringType),
          // This will be automatically recast to Decimal prior to
          // merging with other versions
          DatasetSeriesAttribute("precise_amount",
                                 LogicalType.DoubleType),
          // This will be dropped as it does not appear in the contract
          DatasetSeriesAttribute("amount",
                                 LogicalType.IntegerType)
      )
  )
  ...
  ```


**NB: both the `alternativeSchemas` and the `contractSchema` go through this step; in other words, the `contractSchema` is both used as one of the possible versions and as the final version of the dataset**

### Primary keys and deduplication

Once all versions (including the contract) have been processed, the engine unions all the datasets (which now have identical schema) and runs a deduplication step:

* Rows are grouped by primary key. A column can be made a primary key by marking its corresponding `DatasetSeriesAttribute` as `isPrimaryKey = true`

  ```scala
  import common_etl.operator.dataset_series.DatasetSeriesAttribute
  
  // `customer_id` and `cpf` are primary keys, `customer_name` is not
  val contractSchema = Set(
      DatasetSeriesAttribute("customer_id", LogicalType.UUIDType, isPrimaryKey = true),
      DatasetSeriesAttribute("cpf", LogicalType.StringType, isPrimaryKey = true),
      DatasetSeriesAttribute("customer_name", LogicalType.StringType)
  )
  ```

* When several rows have the same primary key, they are sorted and the first row in the resulting sequence is kept, the others are dropped. Sorting is done either:

  * Using the primary key columns sorted alphabetically

  * By passing a list of column objects in the *optional* `orderByColumns` field:

    ```scala
    import org.apache.spark.sql.functions._
    
    object MyDatasetSeriesOp extends DatasetSeriesOp {
        ...
        override val orderByColumns: Seq[Column] = Seq($"key1", desc($"key2"))
        ...
    }
    ```

**NB: The deduplication step can be skipped by using `override val deduplication = false` in the `DatasetSeriesOp` declaration**

### Final steps

After deduplication, two more steps are run on the resulting data:

* The engine looks for any ``contractSchema`` attribute with the `isPii = true` parameter, and hashes the corresponding columns:

  ```scala
  import common_etl.operator.dataset_series.DatasetSeriesAttribute
  
  // `cpf` and `customer_name` will be hashed
  val contractSchema = Set(
      DatasetSeriesAttribute("customer_id", LogicalType.UUIDType, isPrimaryKey = true),
      DatasetSeriesAttribute("cpf", LogicalType.StringType,
                             isPrimaryKey = true,
                             isPii = true),
      DatasetSeriesAttribute("customer_name", 
                             LogicalType.StringType,
                             isPii = true)
  )
  ```

* The engine looks for any `contractSchema` attribute with renaming metadata and renames the relevant columns. An attribute can be marked as renamed using the `as` method on `DatasetSeriesAttribute`

  ```scala
  import common_etl.operator.dataset_series.DatasetSeriesAttribute
  
  // `customer_id` and `cpf` will be renamed to `customer__id` and `id_number` in the
  // final dataframe
  val contractSchema = Set(
      DatasetSeriesAttribute("customer_id", LogicalType.UUIDType, isPrimaryKey = true)
      	.as("customer__id"),
      DatasetSeriesAttribute("cpf", LogicalType.StringType)
      	.as("id_number"),
      DatasetSeriesAttribute("customer_name", 
                             LogicalType.StringType)
  )
  ```

### `droppedSchemas`

Sometimes, you'll want to ignore certain versions of your series altogether. If this is the case, instead of declaring a schema in `alternativeSchemas`, you can declare it in `droppedSchemas`:

```scala
import common_etl.operator.dataset_series.DatasetSeriesAttribute

override val droppedSchemas = Seq(
    Set(
        DatasetSeriesAttribute("customer_id", LogicalType.UUIDType, isPrimaryKey = true),
        DatasetSeriesAttribute("corrupted_attribute", 
                               LogicalType.StringType,
                               isPii = true)
    )
)
```

It is fairly important to declare schemas you wish to drop on purpose in this `droppedSchemas` field; otherwise if you simply don't declare them Itaipu will alert on them and you won't be able to differentiate b etween schemas you're ignoring and schemas you're accidentally missing.

### Further reading:

* `DatasetSeriesOp` [docstring](https://github.com/nubank/common-etl/blob/master/src/main/scala/common_etl/operator/dataset_series/DatasetSeriesOp.scala#L11-L23) 
* `DatasetSeriesAttribute` [docstring](https://github.com/nubank/common-etl/blob/037fa6b506ed0f800609632eab7a433ef322ace5/src/main/scala/common_etl/operator/dataset_series/DatasetSeriesAttribute.scala#L11-L31)

## Annexes

### Technical description of the ingestion pipeline

1. Riverbend consumes the `EVENT-TO-ETL` Kafka topic using Kafka streams, constantly its content into `.avro` files. 

   * Each `.avro` file corresponds to one schema for one dataset series, over a window of either 90 minutes or 50,000 messages (whichever happens first)

   * Upon writing the `.avro` files, Riverbend commits them to Metapod. As separate datasets under a DatasetSeries GraphQL query endpoint, which can be queried like so:

   ```graph
   {
     datasetSeries(datasetSeriesName: "series/itaipu-spark-stage-metrics") {
       datasets {
         id
         committedAt
         path
       }
     }
   }
   ```

   One dataset corresponding to one generated `.avro` file. 

2. At the start of each run, Itaipu starts by [generating 'root datasets'](https://github.com/nubank/itaipu/blob/dc8fa20fc9af26b29dd3eb5cff6ed43496b7e083/src/main/scala/etl/itaipu/package.scala#L36-L46), which include the Dataset Series. It iterates through the DatasetSeriesOps listed in [etl.dataset_series.AllSeries](https://github.com/nubank/itaipu/blob/dc8fa20fc9af26b29dd3eb5cff6ed43496b7e083/src/main/scala/etl/dataset_series/package.scala#L12-L87), and for each Op:

   1. Queries Metapod to obtain a `DatasetSeries` object. The structure of this object is directly equivalent to the structure returned by the query, so that it contains a `datasets` field listing all avro file paths.
   2. Groups the avro files by Schema, and for each schema that matches one of the version declared in the `DatasetSeriesOp`, persists a dataset suitable for input into a `SparkOp` & identified by a combination of the series name and the version number. These datasets are identified by the prefix `series-raw
