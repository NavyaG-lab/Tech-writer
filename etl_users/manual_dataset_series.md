# Manual Dataset Series (in beta)

Many users of Nubank's data platform need to get slowly changing adhoc data into the ETL. The traditional way to do this was to create a new StaticOp every time you need to update data. This is very cumbersome.

A new alternative (in beta) is to use the [dataset series abstraction](/etl_users/dataset_series.md) to manually add new Parquet files to the ETL.

## How does it work?

Standard event-based dataset series take a bunch of kafka messages (with the same schema), put them in an avro, and append that as a new dataset in a dataset series.

With manual dataset series, we pepare by-hand the dataset that will be appended to the dataset series and directly tell `metapod`, our metadata store, to include it in the series.

This is done by running a CLI command that takes a Parquet file on s3 and the associated [logical type schema](/glossary.md#logical-type-schema) encoded as a json. The logical type schema describes the schema of the Parquet file using Nubank's custom type system. In Scala code we define this schema by having our SparkOps extend `DeclaredSchema` and defining the `attributes` field. Since we are working from the command line, we need to write this manually as a json file.

With the Parquet file and the schema file, the CLI command validates the logical type schema against the Parquet file, copies the Parquet into a permanent location, and tells our metadata store about your new dataset.

## Preparing the data
In a nutshell, place your parquet file on s3 somewhere (`s3://nu-scratch/me/my-dataset`) and place your logical type json schema in the same directory and name it `schema.json` (`s3://nu-scratch/me/schema.json`)

In detail:

### The Parquet file

 - Create a Parquet file from whatever tool / source you want.
 - Place it on `s3` somewhere that you have permissions to access (i.e `s3://nu-scratch/me/my-dataset`).
 - Open it up on databricks and take a look at the schema of the resulting dataframe:

```scala
val df = spark.read.parquet("dbfs:/mnt/nu-scratch/my-dataset")
df.schema
// results in:
StructType(
  StructField(id,StringType,true),
  StructField(example_boolean,BooleanType,true),
  StructField(example_booleans,ArrayType(BooleanType,true),true),
  StructField(example_date,DateType,true),
  StructField(example_dates,ArrayType(DateType,true),true),
  StructField(example_decimal,DecimalType(38,9),true),
  StructField(example_decimals,ArrayType(DecimalType(38,9),true),true),
  StructField(example_double,DoubleType,true),
  StructField(example_doubles,ArrayType(DoubleType,true),true),
  StructField(example_enum,StringType,true),
  StructField(example_enums,ArrayType(StringType,true),true),
  StructField(example_integer,IntegerType,true),
  StructField(example_integers,ArrayType(IntegerType,true),true),
  StructField(example_string,StringType,true),
  StructField(example_strings,ArrayType(StringType,true),true),
  StructField(example_timestamp,TimestampType,true),
  StructField(example_timestamps,ArrayType(TimestampType,true),true),
  StructField(example_uuid,StringType,true),
  StructField(example_uuids,ArrayType(StringType,true),true)
)
```

You'll see that the Parquet schema looses some type information, for instance, UUIDs are stored as strings.
This is why we define our own logical type schema.

### The logical type schema

The logical type schema describes the schema of the dataset using our own internal schema language instead of that of Parquet. They differ a little bit, hence we don't have a tool to generate them automatically. That said, we do validate that the Parquet and logical type schemas match up before committing the dataset to the series.

[Here is a full example of the logical type schema](manual_series_schema.json) for the dataframe above.

It looks roughly like:

```json
{
    "attributes": [
      {
        "name": "example_enum",
        "primaryKey": false,
        "logicalType": "DOUBLE",
        "logicalSubType": null
      },
      {
        "name": "id",
        "primaryKey": true,
        "logicalType": "UUID",
        "logicalSubType": null
      },
      ...
      ]
}
```

Prepare this file, name it `schema.json`, and place it in the same directory on s3 that your Parquet file is at (i.e `s3://nu-scratch/me/schema.json`).

## Appending your dataset to your manual dataset series

```
nu dataset-series info my-series
```

Will give you information on the current status of the series in question.

If the series doesn't exist then you know you are starting fresh.
If it does exist, note number of datasets in the series so we can verify the number went up after we append a new one.

 - Do a dry run of the append to check that the schemas match up
   ```
   nu dataset-series append my-series s3://nu-scratch/me/my-dataset --dry-run
   ```

   If it fails you can get a little more info regarding the schemas by adding the `--verbose` flag.

 - Once the schema validation is passing ask `@phillip` for write access to the `nu-spark-metapod-manual-dataset-series` bucket if you don't have it already. This will eventually be automated through the `#access-request` form.
 - Run the append command

 ```
 nu dataset-series append my-series s3://nu-scratch/me/my-dataset
 ```

   * If there is an s3 file copy error, save the output of the command and ask `@phillip` for help

 - Run the info command again to see that your dataset was added `nu dataset-series info my-series`

## Create a dataset series contract op for your new dataset series

[Follow these instructions](/etl_users/dataset_series.md#creating-a-new-dataset-series)
