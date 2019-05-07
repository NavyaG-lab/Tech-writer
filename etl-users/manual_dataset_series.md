# Manual Dataset Series

Many users of Nubank's data platform need to get slowly changing adhoc data into the ETL. The traditional way to do this was to create a new StaticOp every time you need to update data. This is very cumbersome.

A new alternative (in alpha) is to use the dataset series abstraction to manually add new Parquet files to the ETL.

## Creating a dataset series from manually prepared data

 - Choose a name for your dataset series. You can't use an existing one. Let's call ours `my-monthly-report`
 - Check that you don't have any datasets in that dataset series by making the following graphql query to `metapod`

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
