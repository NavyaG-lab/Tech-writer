# Metapod

Metapod is our metadata management for ETL produced data. [More here](https://github.com/nubank/metapod#background).

It has a basic frontend called [Sonar](https://github.com/nubank/sonar-js).

### Table of contents

- [What is a transaction?](glossary.md#transaction)
- [GraphSQL Clients](ops/graphql_clients.md)
- [How to copy a transaction](#how-to-copy-a-transaction)

## How to copy a transaction

For debug purposes it is possible to create a copy of a transaction. This basically creates a new transaction, removing specified datasets. So it is possible to process and debug one specific dataset without having to reprocess everything again because the **s3 paths will be the same**.

The endpoint for this is: `/api/migrations/copy-transaction/TRANSACTION-ID` and the expected POST content:
```json
{"uncommitted-datasets":
  ["dataset/credit-limit-policies-input-2", "dataset/another-dataset-here"]
}
```

You can either use [nucli](https://github.com/nubank/nucli) or [Insomnia Client](ops/graphql_clients.md#insomnia-client).

1) First find out the transaction you want to copy. In this case we will use [`f083e991-db4d-56f7-9531-cd29c70d66b8`](https://backoffice.nubank.com.br/sonar-js/#/sonar-js/transactions/f083e991-db4d-56f7-9531-cd29c70d66b8) and the uncommitted dataset will be `dataset/credit-limit-policies-input-2`.

```shell
nu ser curl POST global metapod /api/migrations/copy-transaction/f083e991-db4d-56f7-9531-cd29c70d66b8 --data '{"uncommitted-datasets": ["dataset/credit-limit-policies-input-2"]}'
```

2) After the request, `metapod` will return a new transaction id. In this case the new one is: [`5cbdfe7d-49f3-409f-92af-4aae4b7eae73`](https://backoffice.nubank.com.br/sonar-js/#/sonar-js/transactions/5cbdfe7d-49f3-409f-92af-4aae4b7eae73)

It is possible to notice now that the Transaction Type is `COPIED` instead of `DAILY` or `CUSTOM`

Finally, after copying the transaction you can run itaipu using this transaction id:

```shell
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs itaipu prod test-decimal s3a://nu-spark-metapod-ephemeral-1/ s3a://nu-spark-metapod-ephemeral-1/ 50 --itaipu=test-leo-decimal --transaction 5cbdfe7d-49f3-409f-92af-4aae4b7eae73 --include-placeholder-ops
```

[more sabesp examples](cli_examples.md#data-infra-cli-sabesp-examples)
