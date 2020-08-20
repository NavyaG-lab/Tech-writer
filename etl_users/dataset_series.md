# Dataset Series

## Table of Contents

* [Background](#background)
    * [Source of the data](#source-of-the-data)
* [Using Dataset Series](#using-dataset-series)
  * [Creating a new dataset series](#creating-a-new-dataset-series)
    * [Code organization](#code-organization)
    * [Anatomy of a DatasetSeriesContract](#anatomy-of-a-datasetseriescontract)
        * [seriesName](#seriesname)
        * [contractSchema](#contractschema)
        * [alternativeSchemas](#alternativeschemas)
    * [Why do I need all these different schemas?](#why-do-i-need-all-these-different-schemas)
  * [Dealing with versions](#dealing-with-versions)
    * [Transform values of existing attributes](#transform-values-of-existing-attributes)
    * [Rename attributes](#rename-attributes)
    * [Coerce values](#coerce-values)
  * [Metadata](#metadata)
  * [Primary keys and deduplication](#primary-keys-and-deduplication)
  * [Final renaming](#final-renaming)
  * [Troubleshooting dropped schemas](#troubleshooting-dropped-schemas)
    * [Troubleshooting very big dataset series](#troubleshooting-very-big-dataset-series)
  * [PII Handling](#pii-handling)
  * [Accessing the output dataframes](#accessing-the-output-dataframes)
* [Squish](#squish)
  * [How to create archived schemas with just one line of code with Squish](#how-to-create-archived-schemas-with-just-one-line-of-code-with-squish)
  * [How to create multiple versions in an archive dataset with Squish](#how-to-create-multiple-versions-in-an-archive-dataset-with-squish)
  * [How to edit default parameters of Squish](#how-to-edit-default-parameters-of-squish)

## Background

At Nubank, Datomic is the main/preferred way to store data. But it's not the only one. High-throughput data, i.e. click streams, is usually not stored on Datomic so as not to clutter it. While Itaipu [Contracts](../itaipu/contracts.md) are used as an entry point for data stored in Datomic, DatasetSeries are the mechanism we use in Itaipu to make high throughput events available for computation as input datasets.

| Input type     | Type of data                                                 |
| -------------- | ------------------------------------------------------------ |
| Contracts      | Datomic entities, historical attributes (e.g. Customer entity) |
| Dataset Series | High throughput attributes, very granular events (e.g. Click streams) |

### Source of the data

Dataset series data is produced by services by using the [common-ingestion](https://github.com/nubank/common-ingestion) component; please refer to its README to understand its usage and how to integrate it with your service. The resulting data is then handled by the *Ingestion Layer* – a set of services linked to the `EVENT-TO-ETL` Kafka topic:

* The [Riverbend](https://github.com/nubank/riverbend) service is responsible for producing dataset series. It does so by consuming the `EVENT-TO-ETL` Kafka topic and serialising its messages to `.avro` files suitable for ingestion by Itaipu. The dataset-name should be in the format `series/dataset-name`.
* The [Curva de Rio](https://github.com/nubank/curva-de-rio) service exposes an HTTP endpoint which allows services not connected to Kafka to send data to Riverbend.

## Using Dataset Series

In order to use the data from a Dataset Series in an Itaipu `SparkOp`, you'll first need to define a `DatasetSeriesContract`. In this contract you'll explicitly declare the schema ([why?](#why-do-i-need-all-these-different-schemas)) you expect to be receiving from the series, as well as perform a number of standard data cleaning operations to make working with the data safer and more convenient.

### Creating a new dataset series

#### Code organization

Given a `DatasetSeriesContract` called `MySeriesContract`:

* An `object` called `MySeriesContract` extending `nu.data.infra.api.dataset_series.v1.DatasetSeriesContract` should be placed in the `nu.data.<country>.dataset_series` [package](https://github.com/nubank/itaipu/tree/master/src/main/scala/nu/data/br/dataset_series) (this link is only for BR series, change the url to the country you need).
  * Actually the dataset series doesn't specifically need to live anywhere, but it’s a convention
  to make it easier for people to find it, and to keep code organized along with the list that gets
  built by itaipu in the [dataset series package](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/dataset_series/package.scala)
  (link for BR series only), i.e., the run won’t fail even if a dataset series is declared in a
  `foo.bar` package, as long as they are imported and referenced in the collection of classes that
  gets picked up by itaipu.
* The object should be added to this package's `package.scala` file in the `v1DatasetSeriesContracts` set [here](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/dataset_series/package.scala) (again this file is for BR, change it according to your needs).

#### Anatomy of a DatasetSeriesContract

##### `seriesName`

The name of your series, the same used by your service when posting data via the `common-schemata.wire.etl/produce-to-etl!` function ([source](https://github.com/nubank/common-schemata/blob/master/src/common_schemata/wire/etl.clj#L133-L137)) but without the `series/`.

##### `contractSchema`

What the final schema of your dataset series should be once it's done
computing. Usually this corresponds to the current schema with which your series is being produced.

See also [metadata](#metadata).

##### `alternativeSchemas`

Override this optional field to declare other existing schemas for your dataset series. Usually, these will be past versions which use obsolete names or datatypes. See [Dealing with Versions](#dealing-with-versions) for an overview of the version reconciliation metadata DSL.

_Tip_: If you would like to see the various schemas registered to your series, this nucli command can help:

```bash
nu dataset-series info YOUR_DATSET_SERIES -v
```

#### Why do I need all these different schemas?

Over time, producers of the data in your dataset series ~~might~~ will introduce changes in its schema: adding/removing columns, renaming them, or even changing their types. Whenever a schema change is introduced, you will need to modify your `DatasetSeriesContract` accordingly to ensure that:

* it knows how to handle and reconcile the different schemas of your data
* aligns 100% with the schema *you* wish to pass down to downstream `SparkOps` (the `contractSchema` field)

### Dealing with versions

When your dataset series' schema has changed over time, you'll have to add metadata to your schema declarations so that the computing engine may reconcile them into the final contract version. When processing various versions, the engine will go through the following steps:

1. Transform values of existing attributes
2. Rename attributes
3. Coerce values

#### Transform values of existing attributes
The engine looks for attributes with `transform` fields and applies
the transforms to these fields.

```scala
...
DatasetSeriesAttribute("field", LogicalType.IntegerType)
    .withTransform($"field" + 10) // values of this field will have `10` added to them
...
```

`withTransform` accepts any valid Spark `Column` expression.

**NB**: don't abuse transforms; a `DatasetSeriesContract`'s primary
purpose is to reconcile versions. Other logic can be implemented with
a normal SparkOp consuming [one of the datasets output](#accessing-the-output-dataframes) from your `DatasetSeriesContract`

#### Rename attributes
The engine looks for attributes that can be renamed using their `as`
field. In this example `ndex` becomes `index`, `user_id` becomes
`user__id`, so that they match an attribute from the `contractSchema`:

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

See [Final Steps](#final-renaming) for `as` fields declared on`contractSchema` attributes (which would be ignored in the above
phase).

#### Coerce values

We have three possible cases:
  * The column is missing
  * The column has a different type
  * The column does not appear in any schema

**NB: both the `alternativeSchemas` and the `contractSchema` go through this step; in other words, the `contractSchema` is both used as one of the possible versions and as the final version of the dataset**

Missing columns are added, and backfilled using the attribute's `defaultValue` (a `Column` expression) – `defaultValue` defaults to `lit(null)`

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

Existing columns which match the contract by name but not by type are coerced to the contract's type. Coercions are currently supported for:

  * Number to number (e.g. double to decimal)
  * any to string
  * string to uuid-format string. If the original string cannot be parsed as a UUID, it will be converted to one using `java.util.UUID/nameUUIDFromBytes` ([source][1])

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

Columns which do not appear in the contract are dropped.

### Metadata

Every event-based dataset series has additional ingestion-related metadata that can be made visible by overriding the flag `DatasetSeriesContract.addIngestionMetadata` and setting it to `true`.

Note that archive and manual dataset series don't have this ingestion data.

When this flag is enabled, every schema has a corresponding “metadata enriched” version. This applies to `contractSchema`, too, in the following way: `contractSchema` as defined by the user will be added
to the set of alternative schemas; the effective schema enforced at runtime will be `contractSchema` plus the metadata fields.

Currently, the metadata fields are the following:

  * `series_event_cid`
  * `series_event_prototype`
  * `series_event_produced_at`
  * `series_event_processed_at`
  * `series_event_service_name`
  * `metadata_id`

See [RFC-9878](https://github.com/nubank/riverbend/blob/master/doc/rfc-9878.md) for more details.

### Primary keys and deduplication

Once all versions (including the contract) have been processed, the engine unions all the datasets (which now have identical schema) and runs a deduplication step:

* Rows are grouped by primary key. A column can be made a primary key by marking its corresponding `DatasetSeriesAttribute` as `isPrimaryKey = true`
* When several rows have the same primary key, they are sorted and the first row in the resulting sequence is kept, the others are dropped. Sorting is done either:

  * Using the primary key columns sorted alphabetically
  * By passing a list of column objects in the *optional*
    `orderByColumns` field:
    ```scala
    import org.apache.spark.sql.functions._

    object MySeriesContract extends DatasetSeriesContract {
          ...
          override val orderByColumns: Seq[Column] = Seq($"key1", desc($"key2"))
          ...
      }
    ```


**NB: The deduplication step can be skipped by using `override val deduplicate = false` in the `DatasetSeriesContractOp` declaration**

### Final renaming

After deduplication, the engine looks for any `contractSchema` attribute with renaming metadata and renames the relevant columns. An attribute can be marked as renamed using the `as` method on `DatasetSeriesAttribute`

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

#### Explicitly dropping schemas

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

It is fairly important to declare schemas you wish to drop on purpose in this `droppedSchemas` field; otherwise Itaipu will alert on them and you won't be able to differentiate between schemas you're ignoring intentionally and schemas you're accidentally missing.

## Troubleshooting dropped schemas

Ideally, you'd want all datasets to be either processed normally, or intentionally dropped through the `droppedSchemas` attribute described above. If Itaipu is unable to match a given dataset against one of the schemas defined in the op, it will log a warning and ignore the dataset.

To track these, the `Dropped Series Versions` table in the [ETL Monitoring Dashboard](https://nubank.splunkcloud.com/en-US/app/search/etl__dataset_issues_monitoring) indicates which dataset series experienced datasets being dropped. If your series appears in this table, it means that Itaipu found an existing dataset series in S3, but could not match all of its datasets with a schema declared in the relevant `DatasetSeriesContract` (including schemas in `droppedSchemas`). The `dropped_count` column shows how many datasets were dropped, and the `schemas` column indicates how many distinct schemas were found in these datasets, which could not be reconciled against the contract schema.

In order to remedy this, you will need to update the existing schemas or add new schema in the op to match these dropped datasets. Currently you need to debug this by hand, perhaps with the help of the `nu dataset-series info YOUR_DATASET_SERIES -v` command. We hope to soon fix up our databricks helper notebooks that can aid in this.

### Troubleshooting very big dataset series

One issue you might encounter when using this notebook is that the Metapod query will timeout (in case of very big series); in this case, you can solve the dropped datasets issue by:
- Going to this [Splunk query](https://nubank.splunkcloud.com/en-US/app/search/search?q=search%20index%3Dcantareira%20%22Dropping%20dataset-series%22&display.page.search.mode=fast&dispatch.sample_ratio=1&earliest=-24h%40h&latest=now&sid=1549617293.5429746) and change it to search for the name of the series you're looking to troubleshoot
- Finding the message for dropped datasets, which contains the schema that was dropped
- Adding it to the schemas of the op (usually alternative schemas)

### PII Handling

When declaring the contract schema, attributes representing PII data should be marked as `isPii = true`:

```scala
import common_etl.operator.dataset_series.DatasetSeriesAttribute

// `cpf` and `customer_name` are marked as PII
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

Fields marked as PII are automatically hashed in the output contract dataset. If you need to expose the PII data directly, there are two tools at your disposal:

- The PII contract dataset, which is the same as the contract dataset, but with no hashing
- PII attribute lookup table dataset, which allow lookups from a hash value to the original PII value

By default, none of the two above are generated. To have them generated, you'll need to extend the `generatedPiiTables` field on `DatasetSeriesContract`:

```scala
import nu.data.infra.api.dataset_series.v1.{DatasetSeriesContract, PiiTableType}

object MySeriesContract extends DatasetSeriesContract {
  ...
  override def generatedPiiTables: Set[PiiTableType] =
        Set(
          PiiTableType.PiiContractTable, // <- this will generate the full unhashed dataset
          PiiTableType.PiiAttributeLookupTable("attr_2") // <- this will generate a PII lookup table for `attr_2`
        )
}
```

Note that when declaring a `PiiAttributeLookupTable`  on an attribute that is renamed in the contract with the `as` method, you'll need to refer to it by its final, changed name.

### Accessing the output dataframes

When a dataset series contract is computed, the following datasets are generated:

* `series-contract/<my-series>`  (`series.contract__my_series` in BigQuery/Databricks) contains the computed series data, with PII fields hashed.
* `series-contract/<series-name>-pii` contains the computed series data without any pii hashing. This dataset requires PII access privileges to be consulted in the analytical environment.
* `series-contract/<my-series>-<attribute-name>-pii` contains the PII lookup lookup table for a given attribute. This dataset requires PII access privileges to be consulted in the analytical environment.

Within Itaipu, the `DatasetSeriesOpNameLookup` helper should be used instead of hardcoding dataset names:

```scala
package nu.data.br.datasets

...
import nu.data.infra.util.dataset_series.DatasetSeriesOpNameLookup
import nu.data.br.dataset_series.MySeriesContract

object `MyOp` extends SparkOp {
  ...
  // get a hold of the Contract Op name with the helper:
  val contractOpName = DatasetSeriesOpNameLookup.datasetSeriesContractOpName(MySeriesContract)

  // then use the name in your `inputs` and `definition`:

  def inputs: Set[String] = Set(contractOpName)

  def definition(datasets: Map[String, DataFrame]): DataFrame = {
  	datasets(contractOpName)
    	.someOperation
  }

}
```

`DatasetSeriesOpNameLookup` exposes the following methods:
- `datasetSeriesContractOpName` : the name of the normal output contract op
- `datasetSeriesPiiContractOpName` : the name of the pii contract
- `datasetSeriesPiiLookupTableOpName` : the name of the PII lookup tables
- `datasetSeriesContractOpAttributes` : the set of attributes in the normal output contract op

## Squish

### How to create archived schemas with just one line of code with Squish

Considering you set your SparkOp to be archived, all you have to do is add this line to the archives package (considering that Squish is already imported into the package):

```scala
SparkOpToSeries(etl.dataset.blabla.MyObject)
```

Or, if you have a case class that receives a date as a parameter:

```scala
SparkOpToSeries(etl.dataset.blabla.MyCaseClass(squishDate))
```

Note that the date being passed to `MyCaseClass` is a dummy date and could be any date.

### How to create multiple versions in an archive dataset with Squish

Create a file in the `dataset_series/archived` folder for your Dataset Series. In it, follow the example below:

```scala
object  DatasetSquishExample  extends  SparkOpToSeries(SquishExample)  {  //Change for the address and names corresponding to your dataset

  val  v2  =  contractSchema.less("column1")

  val  v1  =  v2.less("column2")

  override  val  alternativeSchemas  =  Seq(v1,  v2)
}
```

In this example, the current version (`v3`) contains all columns from the SparkOp. The alternative schema `v2` contains all columns from the SparkOp/current version (`v3`), except `column1`, and `v1` contains all columns except `column1` and `column2`.

### How to edit default parameters of Squish

By default Squish copies exactly the parameters as defined in the SparkOp

- country
- description
- ownerSquad
- warehouseMode
- orderByColumns (sortKey in the SparkOp)
- clearance
- qualityAssessment

If you want to change something (`country`  in the example below), just create a file in the `dataset_series/archived` folder for your Dataset Series and in it, follow the example below:

```scala
object DatasetSquishExample extends SparkOpToSeries(SquishExample) {

  override val country: Country = Country.MX

  val v2 = contractSchema.less("column1")

  val v1 = v2.less("column2")

  override val alternativeSchemas = Seq(v1, v2)
}
```

In this example, we have overriden the `country` attribute from the SparkOp to `Country.MX`.

[1]: https://codesearch.nubank.com.br/search/linux?q=val%20toUUIDUdf
