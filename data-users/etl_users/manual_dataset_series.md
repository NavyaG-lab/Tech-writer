---
owner: "#data-infra"
---

# Manual Dataset Series (in beta)

Manual dataset series allows you to periodically ingest non-service (i.e data not originated on our services) generated data into ETL. Many users of Nubank's data platform need to get slowly changing adhoc data into the ETL.

A new alternative (in beta) is to use the [dataset series abstraction](dataset_series.md) to manually add new Parquet files to the ETL.

## How does it work

Standard event-based dataset series take a bunch of kafka messages (with the same schema), put them in an avro, and append that as a new dataset in a dataset series.

With manual dataset series, we prepare by-hand the dataset that will be appended to the dataset series and directly tell `ouroboros`, our metadata store, to include it in the series.

This is done by running a CLI command that takes a Parquet file on s3 and the associated [logical type schema](../../glossary.md#logical-type-schema) encoded as a json. The logical type schema describes the schema of the Parquet file using Nubank's custom type system. In Scala code we define this schema by having our SparkOps extend `DeclaredSchema` and defining the `attributes` field. Since we are working from the command line, we need to write this manually as a json file.

With the Parquet file and the schema file, the CLI command validates the logical type schema against the Parquet file, copies the Parquet into a permanent location, and tells our metadata store about your new dataset.

Follow the steps below to create a Manual Dataset Series:

1. [Prerequisites](#prerequisites)
2. [Prepare the data and put on S3](#preparing-the-data)
3. [Appending your dataset to manual dataset series](#appending-dataset-to-manual-dataset-series)
4. [Creating dataset series contract op for new dataset series](#creating-dataset-series-contract-op-for-new-dataset-series)

### Prerequisites

1. [Download and install Docker](https://download.docker.com/mac/stable/Docker.dmg), if you don't already have it installed. For more information, see the documentation on [Docker](https://docs.docker.com/docker-for-mac/install/) and [containers](https://en.wikipedia.org/wiki/Docker_(software)).
2. You'll need to have an AWS account and AWS CLI 1.18+ set on your machine to use ECR. For more information on ECR setup, see [ECR documentation on playbooks](https://playbooks.nubank.com.br/ci-cd/ecr/getting-started/).

### Preparing the data

1. Place your parquet file on s3 somewhere (`s3://nu-tmp/me/my-dataset`) and place your logical type json schema in the same directory and name it `schema.json` (`s3://nu-tmp/me/schema.json`)

2. Add these files to a bucket of the country where you want to create the manual series. Examples of buckets: in BR `nu-tmp`, in MX `nu-tmp-mx`

#### Creating the Parquet file

1. Create a Parquet file from whatever tool / source you want.

2. Place it on an S3 bucket, under a key for which you have read access (i.e `s3://nu-tmp/me/my-dataset`).

3. Open it up on databricks and take a look at the schema of the resulting dataframe:

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
This is the reason we define our own logical type schema.

#### Defining the logical type schema

The logical type schema describes the schema of the dataset using our own internal schema language instead of that of Parquet. They differ a little bit, hence we don't have a tool to generate them automatically. Having said that, we do validate that the Parquet and logical type schemas match up before committing the dataset to the series.

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

Prepare this file, name it `schema.json`, and place it in the same directory on s3 where your Parquet file is at (i.e `s3://nu-tmp/me/schema.json`).

### Appending dataset to manual dataset series

#### Before appending your dataset

Make sure you have the following access permissions.

- Appending dataset to manual dataset series involves talking directly to `ouroboros`, you'll need the `admin` scope for your AWS user. Use `nu-<country> sec scope show <your-firstname.your-lastname>` to see if you have the `admin` scope. If you don't, ask for it using the access request form pinned to the `#access-request` channel.

- After getting the access, you may need to run `nu-<country> auth get-refresh-token --env prod --country <country>`. The `<country>` is the country from where you are creating your manual series (eg: br, mx).

- For copying dataset files to the bucket, you'll need to have the read and write access to that specific bucket. For access permissions, open a ticket in [#data-help](https://nubank.slack.com/archives/C06F04CH1), marking it with the `:data-infra-ticket` reaction, and asking for the following command to be run:

```
For BR:
nu iam allow <your.name> write bucket nu-spark-metapod-manual-dataset-series/<your-dataset-series>/* --until=1week
For other countries:
nu-<country> iam allow <your.name> write bucket nu-spark-metapod-manual-dataset-series-<country>-prod/<your-dataset-series>/* --until=1week
```

​ **Note**: Due to our permission infrastructure limitations, we can only grant access for one week at a time.

#### Appending dataset

1. Run the following command to check if the data is already on the current status of the series.

```
nu-<country> dataset-series info my-series
```

- If the series doesn't exist then you know you are starting fresh.

- If it does exist, note the number of datasets in the series so we can verify if the number has increased after we append a new one.

1. Do a dry-run of the append to check that the schemas match up

```
nu-<country> dataset-series append my-series s3://nu-tmp/me/my-dataset --dry-run
```

​ If it fails you can get more information regarding the schemas by adding the `--verbose`  flag.

​ Once the schema validation is passed, ask on `#squad-data-infra` for write access to the manual series bucket if you don't already have it.

1. Run the append command

 ```
 nu-<country> dataset-series append my-series s3://nu-tmp/me/my-dataset
 ```

- If there is an s3 file copy error, save the output of the command and ask on `#manual-dataset-series` channel.

- Run the info command again to see that your dataset was added `nu-<country> dataset-series info my-series`

### Creating dataset series contract op for new dataset series

[Follow these instructions](dataset_series.md#creating-a-new-dataset-series) but be sure it set the `seriesType` to `Manual` in the contract SparkOp (`override val seriesType: SeriesType = SeriesType.Manual)

### Dos and Don'ts

------

#### **Do**

- Familiarize yourself with the documentation and recommendations on [dataset series](dataset_series.md).
- Check if the file types match with the .parquet file, the schema.json file and the dataset series in Itaipu.
- Have a column that indicates the upload date of the series file or version, which you can then use to filter out obsolete/wrong data.
- Beware of PII information - You can either classify the whole dataset as a PII clearance needed or hash the PII field. To know how to set the PII clearance, see the documentation on [PII handling](dataset_series.md#pii-handling).

#### Don't

- Create a MDSS with open PII fields.
- Just update the schema when your data structure has changed (added new fields etc), because you'll lose all the historical data (historical data will stop being included in daily results i.e the data isn't lost, just ignored). Instead, make use of the **alternativeSchemas** feature, in which your added fields will be null for old data.

## Questions

checkout `#manual-dataset-series` channel on slack.

## Troubleshooting

### I appended a file to my dataset series but it's not appearing in the next run, how can I fix this

The most common reason for this is due to your dataset being dropped by Itaipu due to a mismatch between the schema you declared and the schema encoded in the `DatasetSeriesContractOp`. See the [dataset series mismatched schemas documentation](dataset_series.md#troubleshooting-dataset-series-schema-mismatches) for more information and how to remedy

### I appended wrong data to my series. How can I remove it

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

- use the [dropped schemas api](dataset_series.md#droppedschemas) to get rid of files appended with incorrect schemas

- create a new version of the series (e.g. `my-series-v2`) when you wish to start from scratch. This is an especially good approach if you know you'll be iterating a lot on your series, and will ensure you don't need to depend to much on us to clear its state between each iteration.

In order for this process to be as smooth and quick as possible, you'll need to follow these steps:

- Run the following nucli command:

```
nu dataset-series info <my-series> -v
```

- Running the above should return a list of resources (files) and their ids. Find the resource you want to delete there (usually you'd look for the date at which you appended it) and get a hold of its `id` attribute
- Open a ticket on [#data-help](https://nubank.slack.com/archives/C06F04CH1), marking it with the `:data-infra-ticket:` reaction and providing:
  - your dataset series' precise name (e.g. `series/direct-mail`)
  - the id(s) of the resources(s) you wish deleted
  - the reason for wishing to delete the data

**Important**: The word _deletion_ here does not necessarily mean that the data files are actually removed from S3 - they are only de-referenced. If you need to delete the actual files from S3 for compliance or security reasons, get in touch with the Data Infra team.
