---
owner: "#data-infra"
---

# Dataset series

Here you will find answers to the most commonly raised questions on dataset series - event, archive, and manual. If you have any questions that we haven't been able to answer through this FAQs knowledge base, please post your question in #data-help slack channel and a member of Data Infra team will help you.

## Missing all data of an append in the Dataset series

If you find your dataset was committed successfully but couldn't find all the data of an append in the analytical environment, then it is an **issue with the schema mismatch**. Refere the documentation on [troubleshooting schema mismatches in Dataset series](https://github.com/nubank/data-platform-docs/blob/master/data-users/etl_users/dataset_series.md#troubleshooting-dataset-series-schema-mismatches).

## Missing partial data of an append in the Dataset series

Incase some part of the data in the dataset is missing, then it is an **issue with deduplication of rows**.

### Description

The Dataset Series offers configuration for data to be deduplicated before being exposed as a contract to the rest of the ETL. This is useful in particular for Kafka based series, to mitigate against duplicated messages.

### How to determine if the issue is because of deduplication

1. Login to Databricks where the append data in a dataframe is available.

    Make sure you have the list of fields that are primary keys - https://github.com/nubank/itaipu/tree/master/src/main/scala/nu/data/br/dataset_series in your dataset series.

1. Run the following and you will find the rows missing, where these missing rows would be same as the ones in the primary keys in your series contract. If dedupedDf's count is lower than appendDf's, then the deduplication logic is masking some duplicated rows. Therefore, some part of the data in that series append is missing in the analytical environment.

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

## How can I change the primary key?

You may have realised that the primary key assigned to a field in your dataset is not unique and need to change it. Then, in your dataset, you can just remove the flag `isPrimaryKey = true,` assigned for the field in the `contractschema`. For more information on primary keys, refer to the documentation on [Dataset series](https://github.com/nubank/data-platform-docs/blob/e17ce316f92d0fb5078325387e3d007119bdabad/data-users/etl_users/dataset_series.md#rename-attributes).
