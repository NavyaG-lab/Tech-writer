# Databricks S3 Inventory

[S3 Inventory](https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-inventory.html) provides information at the object level for S3 buckets.

There's currently an inventory for all objects under `s3://nubank-databricks-root/nubank/0/user/hive/warehouse/`, the default path where user generated tables are saved.

A [Databricks job](https://nubank.cloud.databricks.com/#job/42307) currently parses the inventory data and generates two tables:

- [meta.s3_inventory__nubank_databricks_root](https://nubank.cloud.databricks.com/#table/meta/s3_inventory__nubank_databricks_root): Raw logs
- [meta.s3_inventory__databricks_user_tables](https://nubank.cloud.databricks.com/#table/meta/s3_inventory__databricks_user_tables): Parsed logs

With these tables it's possible to use these tables to answer questions like:

- What was the last time a table was accessed on Databricks?
- How much does storing a table in Databricks costs?
