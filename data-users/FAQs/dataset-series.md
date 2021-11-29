---
owner: "#data-infra"
---

# Dataset series

Here you will find answers to the most commonly raised questions on dataset series - event, archive, and manual. If you have any questions that we haven't been able to answer through this FAQs knowledge base, please post your question in #data-help slack channel and a member of Data Infra team will help you.

## Missing all data of an append in the Dataset series

If you find your dataset was committed successfully but couldn't find all the data of an append in the analytical environment, then it is likely **schema mismatch** issue. Refer to the documentation on [troubleshooting schema mismatches in Dataset series](https://github.com/nubank/data-platform-docs/blob/master/data-users/etl_users/dataset_series.md#troubleshooting-dataset-series-schema-mismatches).

## Missing partial data of an append in the Dataset series

In case some part of the data in the dataset is missing, then it could be due to either an **issue with the deduplication of rows** or a **schema mismatch** issue

### Description

The Dataset Series offers configuration for data to be deduplicated before being exposed as a contract to the rest of the ETL. This is useful in particular for Kafka based series, to mitigate against duplicated messages.

### How to determine if the issue is because of deduplication

1. Make sure you have the list of fields that are primary keys - <https://github.com/nubank/itaipu/tree/master/src/main/scala/nu/data/br/dataset_series> in your dataset series.

1. Login to Databricks and load your append data in a dataframe (you'll need to load the data from `nu-tmp` or whichever bucket you placed it on before running the DSS append command).

1. Run the following to check whether deduplication may be removing rows from your append.

    ```scala
    val originalCount = appendDf.count()

    val dedupedDf = appendDf.select($"<primary-key1>", $"<primary-key2>", $"<primary-key>",).distinct()

    val dedupedCount = dedupedDf.count()
    ```

    If `dedupedCount` is lower than `originalCount`, then the deduplication logic is removing some rows because they share primary keys. Therefore, some part of the data in that series append is missing in the analytical environment.

    Note that this will only work when troubleshooting deduplication within a single append. If rows across different appends share primary keys they will also get deduplicated according to it. You can check whether data from a new append may be deduplicated away due to a former append by joining your new append data with the latest contract data of your dataset.

    **Example**

    ```scala
    val originalCount = appendDf.count()

    val dedupedDf = appendDf.select($"as_of", $"cnpj", $"tipo_socio", $"cnpj_cpf_socio").distinct()

    val dedupedCount = dedupedDf.count()
    ```

### How to fix deduplication issues

You'll need to [update the primary keys](#how-can-i-change-the-primary-key) to ensure that the rows of your append are unique according to the set of primary keys.

## How can I change the primary key

You may have realised that the primary key assigned to a field in your dataset is not unique and needs to be changed. To do so, you can remove the flag `isPrimaryKey = true` from the `DatasetSeriesAttribute` corresponding to this field in the `contractSchema` of the `DatasetSeriesContract`. For more information on primary keys, refer to the documentation on [Dataset series](https://github.com/nubank/data-platform-docs/blob/e17ce316f92d0fb5078325387e3d007119bdabad/data-users/etl_users/dataset_series.md#rename-attributes).

## Missing specific records in the Dataset series

This case assumes that the issue you have at hand is not due to [missing partial data of an append](#missing-partial-data-of-an-append-in-the-dataset-series) neither due to [missing all data of an append](#missing-all-data-of-an-append-in-the-dataset-series) i.e. this is not a schema nor a deduplication problem. For such cases, please make sure you get a hold of the following data:

- The series name.
- The name of the service that produced the lost message.
- The date of when the missing message was produced to the ETL
- The CID of the `:out-message` to `:topic "EVENT-TO-ETL"` of your lost message.
- The `shard` on which this message was produced.

Please reach out to data-infra in `#data-help` slack channel for support and share the data above as part of your request.
