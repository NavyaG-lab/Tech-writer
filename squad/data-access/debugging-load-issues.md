---
owner: "#data-access"
---

# Debugging Load Issues

## Check if the dataset ran on this transaction

The first step in debugging a missing dataset is to determine if the dataset has run. To check this, we can run

`nu etl info <dataset-name> --n=5`

which will get you information on the dataset in the last few transactions. You can also check if the dataset has been committed empty by looking at the path of the dataset. This way you can know if it has been calculated and simply hasn't been loaded yet, or if it hasn't been calculated at all (meaning it is a problem in the etl and there is not much we can do).


## Checking Loads on Databricks

We can check if a table has been properly loaded by checking the table `meta.loads` (BR) or `meta.international_loads` (all other regions).

```sql
%sql
SELECT * FROM meta.loads 
WHERE datasetName = '<dataset-name>'
ORDER BY loadTime
limit 100
```

With the query above we can check what was the most recent transaction that loaded the table and other metadata about said load. This can help you decide where is the problem. Another place you can check is the load jobs ([BR](https://nubank.cloud.databricks.com/#job/13083), [Others](https://nubank.cloud.databricks.com/#job/19327)), from where you might see the specific errors that caused the table not to be loaded.

If the table is not in the load tables and there are no errors, maybe it hasn't been loaded yet. Try manually triggering the job, which might give you more info.

There is a known issue with datasets that are commited after midnight UTC: when a dataset is committed on a day other than its execution, it will not be loaded into databricks because another itaipu execution already exists, therefore another transaction ongoing. To read these datasets, we need to read the files directly from S3 path, this [notebook](https://nubank.cloud.databricks.com/#notebook/11147162) can help with the procedure.

## Checking Loads on BigQuery

You can check the status of the transfer and load of the dataset in [this dashboard](https://nubank.splunkcloud.com/en-US/app/search/data_access__bigquery_load?form.dataset_name=&form.index=main)

Another place you can check is the bigquery table itself, on the [BigQuery Console](https://console.cloud.google.com/bigquery?project=nu-br-data). Its tags will tell you the transaction of the current table, and the `Last modified` field will tell you when the table was last updated.

As a last resort, a splunk query filtering for monsoon with the name of the dataset will show you every log of everything that happened to the transfer and load of the dataset.

`index=main source=monsoon <dataset-name>`

Also, always remember that there are 2 instances of monsoon running: one in the BR environment and another in the Data environment. When checking logs, one should always remember to check the correct env by setting the right index on the search (`main` for BR, `prod-data` for Data).
