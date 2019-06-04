# Manual Dataset Series

Many users of Nubank's data platform need to get slowly changing adhoc data into the ETL. The traditional way to do this was to create a new StaticOp every time you need to update data. This is very cumbersome.

A new alternative (in alpha) is to use the dataset series abstraction to manually add new Parquet files to the ETL.

## How does it work?

Standard event-based dataset series take a bunch of kafka messages (with the same schema), put them in an avro, and append that as a new dataset in a dataset series.

With manual dataset series, we are preparing the dataset that will be appended to the dataset series manually and directly telling our metadata store to include it in the series.

In essence this comes down to running a CLI command that takes a Parquet file on s3 and the associated logical type schema. By logical type schema, I mean a json file that describes the contents of the Parquet file using Nubank's custom type system. In Scala code we define this schema by having our SparkOps extend `DeclaredSchema` and defining the `attributes` field. Since we are working from the command line, we need to write this manually as a json file.

With the Parquet file and the schema file, the CLI command copies the Parquet into a safe place, and tells our metadata store about your new dataset

__NOTE__ in the alpha version you have to write this by hand. Later we'll see if there is an easier way to generate this schema file. Also, there is currently no check to ensure that the json logical type schema you define matches the contents of the Parquet file. This will come later. It means you may run into unexpected issues when the dataset series contract is computed.

## Creating a dataset series from manually prepared data

 - Choose a name for your dataset series. You can't use an existing one. Let's call ours `my-monthly-report`
 - Check that you don't have any datasets in that dataset series by making the following [graphql query to `metapod`](https://github.com/nubank/data-infra-docs/blob/master/ops/graphql_clients.md)

 ```
{
    datasetSeries(datasetSeriesName: "series/my-monthly-report") {
      datasets {
        id
      }
    }
}
 ```

 - Prepare a Parquet file and place it on s3 somewhere. Let's say you put it in `s3://nu-spark-devel/my-monthly-report/`
 - Prepare the logical type schema for your dataset. Name it `schema.json` and put it in `s3://nu-spark-devel/my-monthly-report/`. It should look roughly like the following, where loosely the available types [are these](https://github.com/nubank/common-schemata/blob/40ab96f574ffe2d72eabd5b1260d406996f3c789/src/common_schemata/wire/etl.clj#L18-L20)

 ```
 {"attributes":
  [
    {"name": "foo", "logicalType": "DECIMAL", "nullable": "true"},
    {"name": "bar", "logicalType": "DATE", "nullable": "true"}
  ]
}
 ```

 - Ask for the [`manual-dataset-series` scope](https://github.com/nubank/service-scopes/blob/master/service-scopes.md) from someone on data-infra or data-access (probably @phillip for now)
 - Run the append command
 ```
 nu dataset-series append my-monthly-report s3://nu-spark-devel/my-monthly-report/costs-to-etl-00002.snappy.parquet
 ```

 - Run the graphql query mentioned above again and assert there is a new dataset

## Create a dataset series contract op for your new dataset series

[Follow these instructions](/etl-users/dataset_series.md#creating-a-new-dataset-series)

## References

If you want to look into the internals, here are some relevant PRs and docs

- [RFC](https://docs.google.com/document/d/1y12jsmp9CS6o_-qyOl-nfspZ9mUnWdQ7hjctyzJ-gwc/edit#heading=h.g1uhsmsys485)
- [nucli command](https://github.com/nubank/nucli/pull/1435)
- [metapod implementation](https://github.com/nubank/metapod/pull/276)
