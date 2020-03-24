# Manual Dataset Series (in beta)

Many users of Nubank's data platform need to get slowly changing adhoc data into the ETL. The traditional way to do this was to create a new StaticOp every time you need to update data. This is very cumbersome.

A new alternative (in beta) is to use the [dataset series abstraction](/etl_users/dataset_series.md) to manually add new Parquet files to the ETL.

## How does it work?

Standard event-based dataset series take a bunch of kafka messages (with the same schema), put them in an avro, and append that as a new dataset in a dataset series.

With manual dataset series, we prepare by-hand the dataset that will be appended to the dataset series and directly tell `metapod`, our metadata store, to include it in the series.

This is done by running a CLI command that takes a Parquet file on s3 and the associated [logical type schema](/glossary.md#logical-type-schema) encoded as a json. The logical type schema describes the schema of the Parquet file using Nubank's custom type system. In Scala code we define this schema by having our SparkOps extend `DeclaredSchema` and defining the `attributes` field. Since we are working from the command line, we need to write this manually as a json file.

With the Parquet file and the schema file, the CLI command validates the logical type schema against the Parquet file, copies the Parquet into a permanent location, and tells our metadata store about your new dataset.

## Preparing the data
In a nutshell, place your parquet file on s3 somewhere (`s3://nu-tmp/me/my-dataset`) and place your logical type json schema in the same directory and name it `schema.json` (`s3://nu-tmp/me/schema.json`)

You need to add these files to a bucket of the country where you want to create the manual series. Examples of buckets: in BR `nu-tmp`, in MX `nu-tmp-mx`

In detail:

### The Parquet file

 - Create a Parquet file from whatever tool / source you want.
 - Place it on `s3` somewhere that you have permissions to access (i.e `s3://nu-tmp/me/my-dataset`).
 - Open it up on databricks and take a look at the schema of the resulting dataframe:

```scala
val df = spark.read.parquet("dbfs:/mnt/nu-tmp/my-dataset")
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

Prepare this file, name it `schema.json`, and place it in the same directory on s3 that your Parquet file is at (i.e `s3://nu-tmp/me/schema.json`).

## Before appending (Temporary)

First you will need to have docker installed, download [Here](https://download.docker.com/mac/stable/Docker.dmg). Docker is a set of coupled software-as-a-service and platform-as-a-service products that use operating-system-level virtualization to develop and deliver software in packages called containers [Wikipedia](https://en.wikipedia.org/wiki/Docker_(software)). Containers are isolated from one another and bundle their own software, libraries and configuration files; they can communicate with each other through well-defined channels. All containers are run by a single operating-system kernel and are thus more lightweight than virtual machines.

After that you will need to create an account in quay.io [Here](https://docs.quay.io/solution/getting-started.html), and ask permission in #access-request channel, to be added in Nubank group. (Do not forget to accept the invitation in quay website.)

Now you should have to sign into Quay.io using docker. Quay.io was originally created out of necessity when the company wanted to use Docker containers with an original IDE product, it is a private container registry that stores, builds, and deploys container images. It analyzes your images for security vulnerabilities, identifying potential issues that can help you mitigate security risks. In order to login run the command ```docker login quay.io ```.

Since appending involves talking directly to `metapod`, you will need the `admin` scope for your AWS user. Use `nu-<country> sec scope show <your-firstname.your-lastname>` to see if you have the `admin` scope. If you don't, ask for it using the access request form pinned to the `#access-request` channel. After getting it you may need to run `nu-<country> auth get-refresh-token --env prod --country <country>`. Where `<country>` is the country where you are creating your manual series (eg: br, mx).


Lastly, you will need to have read and write access the particular bucket where the dataset file will copied to. For this step, ask `#squad-data-infra` to run the following command. Note: due to limitations with our permission infrastructure, we can only grant access for 1 week at a time.

```
For BR:
nu iam allow <your.name> write bucket nu-spark-metapod-manual-dataset-series/<your-dataset-series>/* --until=1week
For other countries:
nu-<country> iam allow <your.name> write bucket nu-spark-metapod-manual-dataset-series-<country>-prod/<your-dataset-series>/* --until=1week
```

## Appending your dataset to your manual dataset series

```
nu-<country> dataset-series info my-series
```

Will give you information on the current status of the series in question.

If the series doesn't exist then you know you are starting fresh.
If it does exist, note number of datasets in the series so we can verify the number went up after we append a new one.

 - Do a dry run of the append to check that the schemas match up
   ```
   nu-<country> dataset-series append my-series s3://nu-tmp/me/my-dataset --dry-run
   ```

   If it fails you can get a little more info regarding the schemas by adding the `--verbose` flag.

 - Once the schema validation is passing ask on `#squad-data-infra` for write access to the manual series bucket if you don't have it already. This will eventually be automated through the `#access-request` form.

 - Run the append command

 ```
 nu-<country> dataset-series append my-series s3://nu-tmp/me/my-dataset
 ```

   * If there is an s3 file copy error, save the output of the command and ask on `#manual-dataset-series`

 - Run the info command again to see that your dataset was added `nu-<country> dataset-series info my-series`

## Create a dataset series contract op for your new dataset series

[Follow these instructions](/etl_users/dataset_series.md#creating-a-new-dataset-series) but be sure it set the `seriesType` to `Manual` in the contract SparkOp (`override val seriesType: SeriesType = SeriesType.Manual)

## Questions

checkout `#manual-dataset-series` channel on slack.

## Troubleshooting

### I appended a file to my dataset series but it's not appearing in the next run, how can I fix this?
The most common reason for this is due to your dataset being dropped by Itaipu due to a mismatch between the schema you declared and the schema encoded in the `DatasetSeriesContractOp`. See the [dataset series dropped schemas documentation](https://github.com/nubank/data-infra-docs/blob/4bc2d41242c3c4ce4fe333dfe77b3f9e8e030de6/etl_users/dataset_series.md#troubleshooting-dropped-schemas) for more information and how to remedy

### I appended wrong data to my series. How can I remove it?

Data Infra can retract bad data you accidentally added to your series. **Please bear in mind that this is a fairly manual and non-scalable process for us at this stage, and so requesting deletion should be a last-resort in cases when you can't do it any other way.** Among alternative ways to achieve the same result, you can:
- Add a batch id column to your dataset series, which you populate with a random id whenever generating the parquet files, and then use to blacklist selected batches using a downstream ops, e.g.:

```scala
// when generating the parquet file, first add a batch id
val batchId = '<batch_id>'
val annotatedDf = myDf.withColumn('batch_id', lit(batchId))

// later on you can create an op downstream from the series contract:

def batchBlacklist: Set[String] = Set(...)
def definition(datasets) = {
 val df = ...
 df.filter(!batchBlackList.contains($"batch_id"))
}

```

- use the [dropped schemas api](https://github.com/nubank/data-platform-docs/blob/master/etl_users/dataset_series.md#droppedschemas) to get rid of files appended with incorrect schemas

- create a new version of the series (e.g. `my-series-v2`) when you wish to start from scratch. This is an especially good approach if you know you'll be iterating a lot on your series, and will ensure you don't need to depend to much on us to clear its state between each iteration.

In order for this process to be as smooth and quick as possible, you'll need to follow these steps:

- Go to [Sonar](https://backoffice.nubank.com.br/sonar-js/#/sonar-js/graphiql) (our dataset query interface) and use the following graphql query:
```
query GetManualSeries {
  datasetSeries(datasetSeriesName: "series/<my-series>") {
    datasets {
      id
      committedAt
      path
    }
  }
}
```
- Running the above should return a list of datasets and their ids. Find the dataset you want to delete there (usually you'd look for the data at which you appended it) and get a hold of its `id` attribute
- On #squad-data-infra, ask for the deletion by providing:
  - your dataset series' precise name (e.g. `series/direct-mail`)
  - the id(s) of the dataset(s) you wish deleted
  - the reason for wishing to delete the data
