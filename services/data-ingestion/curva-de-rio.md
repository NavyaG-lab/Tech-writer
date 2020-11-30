---
owner: "#data-infra"
---

# Curva-de-Rio

A HTTP Entrypoint for non-datomic data to be ingested into the ETL/Datalake.

Every request will generated a new message into the EVENT-TO-ETL topic which will then be batched and uploaded to S3 to be accessible on Itaipu.

To ingest directly using kafka, refer to [Alph](/services/data-ingestion/alph.md).

## See also

[Code repo](https://github.com/nubank/curva-de-rio)
