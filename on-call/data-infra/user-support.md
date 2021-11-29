---
owner: "#data-infra"
---

# User Support Documentation

## Missing data in the Dataset series

If user reports that their data is missing, check with them if all the data of an append is missing in the analytical environment or only some part of the data.

- Incase **all the data of an append is missing**, then it is an **issue with the schema mismatch**. Refere the documentation on [troubleshooting schema mismatches in Dataset series](https://github.com/nubank/data-platform-docs/blob/master/data-users/etl_users/dataset_series.md#troubleshooting-dataset-series-schema-mismatches).
- If **partial data of an append is missing**, then it is an **issue with deduplication of rows**.

### Missing Partial data in the Dataset series

If partial data of an append is missing, then it is a deduplication issue.

### Description

The Dataset Series offers configuration for data to be deduplicated before being exposed as a contract to the rest of the ETL. This is useful in particular for Kafka based series, to mitigate against duplicated messages.

### Information required from the user

- Name and country of the series, as well as the link to the file on Github
- Confirmation of when the last append happened, and that it was successful (can be checked with `nu-<country> dataset-series info <series-name>`)
- Confirmation of which run the user is expected to see the data in (usually either the previous day’s run or today’s run)
- Confirmation of which tool the user is trying to view the data in, usually either BigQuery or Databricks
- Exact characteristics of missing rows, such as primary key values.
- Confirmation that the `nu-<country> dataset-series diff <series-name>` command does not return any errors. This is to differentiate from a dataset series schema issue. For more information, refer to the documentation on [schema issues in dataset series](https://github.com/nubank/data-platform-docs/blob/master/data-users/etl_users/dataset_series.md#troubleshooting-dataset-series-schema-mismatches).

### How to determine the deduplication of rows issue in an append

1. Check that the series contract was committed for the run using the following command:

```
    nu-br etl info series-contract/<name-of-the-series-contract> --n=2
```

the `--n` parameter is to check the run history. To check yesterday's run, the value for the `--n` parameter should be 2. For current run, you don't need to provide this parameter.

If the dataset hasn’t been committed yet, and if the last append happened after the last run, report to the users that they should wait until it does get committed and close the ticket.

1. If the dataset is committed, get the dataset series information such as schemas, append ID, and corresponding appends by calling the dataset series endpoint.

    ```
    nu-br dataset-series info -v <name-of-the-dataset-series>
    ```

1. Get the paths of the append from the Ouroboros resource path endpoint.

    ```
    nu ser curl GET global ouroboros /api/admin/debug/resource/<append-id>/paths
    ```

    This path could be a path of the folder that contains all the parquet files. For instance,
    "s3://nu-spark-metapod-manual-dataset-series/pj-receita-socios/socios-2020-11-23_2021_02_09_14_39_08.parquet/"

1. Login to Databricks and load the append data into a dataframe by running the following:

```
    val appendPath = "s3://nu-spark-metapod-manual-dataset-series/pj-receita-socios/socios-2020-11-23_2021_02_09_14_39_08.parquet/".replace("s3://", "dbfs:/mnt")

    //provides the `appendPath` with the respective path with which you want to load data into databricks//

    val appendDf = spark.read.parquet(appendPath)
    //loads the Data frame corresponding to the append//
```

1. From the respective dataset series, get the list of fields that are primary keys - <https://github.com/nubank/itaipu/tree/master/src/main/scala/nu/data/br/dataset_series>.

1. In Databricks, run the following and you will find the rows missing, where these missing rows would be same as the ones in the primary keys in series contract.

    Make sure that you run `.count()` on each of the dataframes to get the number of rows deduplicated.

    ```
    val ac = appendDf.count()

    val dedupedDf = appendDf.select($"<primaray-key1>", $"<primary-key2>", $"<primary-keyn>",).distinct()

    val dc = deduppedDf.count()
    ```

    **Example**

    ```
        val ac = appendDf.count()

        val dedupedDf = appendDf.select($"as_of", $"cnpj", $"tipo_socio", $"cnpj_cpf_socio").distinct()

        val dc = deduppedDf.count()

    ```

    **Important**: If dedupedDf's count is lower than appendDf's, then the deduplication logic is masking some duplicated rows. Therefore, some part of the data in that series append is missing in the analytical environment.

### Deduplication of rows because of previously committed append

A more complicated but also common scenario is, the data that the user currently appended does not include duplicates, but there is a possibility of having duplicates with data that was already appended to the series in the past, as part of another append.

Note that the contract will have the data from all the previously committed appends and not just the current single append. For instance, if all the rows in the current append have a unique combination of field names such as, as_of, cnpj, tipo_socio and cnpj_cpf_socio, but some of these combinations already exist in the series contract data via previous appends, then it would still deduplicate those rows.

In order to investigate this case, you will have to look for that duplicated data between the append and the contract.
