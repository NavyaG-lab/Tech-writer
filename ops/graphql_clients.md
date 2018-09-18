# GraphQL clients

## Insomnia client

[Insomnia](https://insomnia.rest/) is http client GUI with a nice graphql interface.
It is probably the most user-friendly way to query `metapod` via graphql.

### Setup for use with `metapod`'s graphql API

In Insomnia, create a new (graphql) request (CTRL+N)

Set the method to `POST` and the URL to:

```
https://prod-metapod.nubank.com.br/api/graphql/query
```

#### bearer token

In the request settings click `Bearer` and add the output of running this command, excluding the `Bearer ` at the beginning

```
nu auth token prod
```

Note you may, from time to time, need to run ([more info](https://github.com/nubank/playbooks/blob/master/squads/infosec/faq.md#im-getting-http-401-unauthorized-errors-what-can-i-do)):

```
nu auth get-refresh-token
nu auth refresh-token
```

#### client cert and key

 - Navigate to the Insomnia `Workspace Settings` menu (click the insomnia drop down next to the `Request` menu area)
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

[Sonar](primer.md#sonar-overview) has a graphql query interface at [`https://backoffice.nubank.com.br/sonar-js/#/sonar-js/graphiql`](https://backoffice.nubank.com.br/sonar-js/#/sonar-js/graphiql).

The page requires the VPN and is pretty slow to load. That said, it has some doc navigation and requires no other configuration.
