# GraphQL clients



## Insomnia client

[Insomnia](https://insomnia.rest/) is http client GUI with a nice graphql interface. It is probably the most user-friendly way to query `metapod` via graphql.

### Setup for use with `metapod`'s graphql API

In Insomnia, create a new (graphql) request (CTRL+N)

Set the method to `POST` and the URL to:

```
https://prod-metapod.nubank.com.br/api/graphql/query
```

#### bearer token

In the request settings tabs bar below the URL, click `Bearer` (might be `Auth`, then choose `Bearer Token` in the dropdown) and add the output of running this command, excluding the `Bearer ` at the beginning

```
nu auth token prod
```

Note you may, from time to time, need to run ([more info](https://github.com/nubank/playbooks/blob/master/squads/infosec/faq.md#im-getting-http-401-unauthorized-errors-what-can-i-do)):

```
nu auth get-refresh-token
nu auth refresh-token
```

Alternatively, you can also add a new _Environment_ in Insomnia, which will allow you to set environment variables across all saved requests. To access the Manage Environments window, click the `No Environment` dropdown below the Insomnia logo on the top-left.
For instance, you can setup a `prod` environment such as:

```
{
	"metapod_base_url": "https://prod-global-metapod.nubank.com.br/api",
	"token": "EbDJHf45kj3b45..."
}
```

And then in the Bearer token setting, you can type `{{token}}` and it will use the env vars for the environment.

#### client cert and key

 - Navigate to the Insomnia `Workspace Settings` menu (click the Insomnia drop down next to the `Request` menu area)
 - Within the `Client certificates` tab select `New Certificate`
 - Configure the certificate to have
    - a `HOST` set to  `*.nubank.com.br`
    - a `CRT` set to the file `$NU_HOME/.nu/certificates/prod/cert.pem`
    - a `KEY` set to the file `$NU_HOME/.nu/certificates/prod/key.pem`
    - no `passphrase` or `PFX` are needed


### example query

```
{
    datasetSeries(datasetSeriesName: "series/policy-reactive-control") {
      datasets {
        committedAt
      }
    }
}
```

### Using query chaining in Insomnia

Insomnia allows you to 'chain' queries, meaning that you can automatically use the result of previous queries in your next query. The below steps focus on graphql, but can be easily adapted to normal REST as well:

1. First, go to Preferences -> Tick 'Nunjuck power user mode' (see [this issue](https://github.com/getinsomnia/insomnia/issues/1030) if you want to learn why)

2. Then to use query chains, create all the queries you need, and use the following syntax for inserting the result of a previous query in the desired place:

   ```
   {% response 'body', '<query_id>', '<JSONPath>' %}
   ```

   where:

   * **<query_id>** is the uuid of the query which you can find by right clicking on your query and opening its settings. The id is at the top, and looks like this: `req_46dbb5d3f9bb4625a2f11d1dd13f8e70`
   * **\<JSONPath\>** is a spec based on the [JSONPath syntax](https://github.com/json-path/JsonPath), e.g.: `$.data.createTransaction.id`

3. You can then go ahead and execute your queries in order, and the data should pull through

#### Example: Create a transaction in Metapod, commit two datasets and query Metapod again to see the final result:

##### Create Transaction (query id: `req_46dbb5d3f9bb4625a2f11d1dd13f8e70`)

###### Query

```graphql
query GetTransactionWithDatasets($transactionId: ID) {
  transaction(transactionId: $transactionId) {
    id
    datasets {
      id
      name
    }
  }
}

```

###### Variables

```json
{
	"input": {
		"type": "CUSTOM",
		"datasetNames": [
			"dataset/archived",
			"dataset/not-archived"
		]
	}
}
```

##### Commit archived dataset

###### Query

```graphql
mutation CommitDataset($input: CommitDatasetInput) {
  commitDataset(input: $input) {
    id
  }
}

```

###### Variables

```json
{
	"input": {
		"transactionId": "{% response 'body', 'req_46dbb5d3f9bb4625a2f11d1dd13f8e70', '$.data.createTransaction.id' %}",
		"datasetId": "{% response 'body', 'req_46dbb5d3f9bb4625a2f11d1dd13f8e70', '$.data.createTransaction.datasets[?(@.name==\"dataset/archived\")].id' %}",
		"format": "PARQUET",
		"actions": [
			"CREATE_ARCHIVE"
		],
		"schema": {
			"attributes": [
				{
					"name": "attr1",
					"logicalType": "INTEGER"
				}
			]
		}
	}
}
```

##### Commit non-archived dataset

###### Query

```graphql
mutation CommitDataset($input: CommitDatasetInput) {
  commitDataset(input: $input) {
    id
  }
}

```

###### Variables

```json
{
	"input": {
		"transactionId": "{% response 'body', 'req_46dbb5d3f9bb4625a2f11d1dd13f8e70', '$.data.createTransaction.id' %}",
		"datasetId": "{% response 'body', 'req_46dbb5d3f9bb4625a2f11d1dd13f8e70', '$.data.createTransaction.datasets[?(@.name==\"dataset/not-archived\")].id' %}",
		"format": "PARQUET"
	}
}
```

##### Query Metapod

###### Query

```graphql
query GetTransactionWithDatasets($transactionId: ID) {
  transaction(transactionId: $transactionId) {
    id
    type
    committedAt
    datasets {
      id
      name
      committedAt
      committed
      actions
      schema {
        attributes {
          name
          logicalType
        }
      }
    }
  }
}
```

###### Variables

```json
{
	"transactionId": "{% response 'body', 'req_46dbb5d3f9bb4625a2f11d1dd13f8e70', '$.data.createTransaction.id' %}"
}
```

And that's it! You can find more info on query chaining in the [Insomnia docs](https://support.insomnia.rest/article/43-chaining-requests).

## nu curl

You can use the `nu` bash command provided by [`nucli`](https://github.com/nubank/nucli) to perform graphql queries on `metapod`.

```
nu ser curl POST global metapod /api/graphql/query --env prod -- --data @your-query.json -v | jq .
```

where `your-query.json` has the following:

```
{"query": "{
  transaction(transactionId: \"4472a15e-7de7-5b51-8cb3-e367846c05ea\") {
    datasets(committed: ONLY_COMMITTED) {
      name
    }
  }
}"
}
```

The unfortunate aspect of this is that you have to escape special characters in your queries

## sonar

[Sonar](https://github.com/nubank/data-infra-docs/blob/master/primer.md#sonar-overview) has a graphql query interface at [`https://backoffice.nubank.com.br/sonar-js/#/sonar-js/graphiql`](https://backoffice.nubank.com.br/sonar-js/#/sonar-js/graphiql).

The page requires the VPN and is pretty slow to load. That said, it has some doc navigation and requires no other configuration.
