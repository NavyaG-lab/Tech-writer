# Contribution Margin Dataset

## Overview

Contribution margin is a special dataset because it combines data from 2 distinct sources:
* Bottom-up data from production systems (e.g., double entry) tracked per customer-account-day
* Top-down data from non-production systems (e.g., Matera, HR spreadsheets) that must be allocated based on drivers to get to per customer-account-day

This is also known as "segmented profitability" and it is a very powerful tool as it allows us to know whether we are making or losing money on specific customers (non-trivial in our business), and thus allows us to evaluate the profitability of any given segment of customers via aggregation.  Cohort curves are one example of segmenting our customers (by "release month" or "activation month" depending on the use case).

Because contribution margin incorporates data from sources that are infrequently updated (e.g., monthly cycle for Matera), it requires periodic maintenance to remain accurate.


## How to maintain on a monthly basis

The contribution margin dataset requires the following steps to be performed after the accounting books are closed each month (typically after the 4th of the month).


### Matera Exports

1) Export detailed data from our Matera ERP in CSV format - ask Bleise Cruz in finance.  The files should be uploaded as follows (one file per year per legal entity, historical years don't change):
* `s3://nu-spark-us-east-1/non-datomic/static-datasets/matera-exports-csv/entity=nu_eli/report_date=20XX-XX-XX/NUELI_ENTRIES_20XX.csv`
* `s3://nu-spark-us-east-1/non-datomic/static-datasets/matera-exports-csv/entity=nu_fid/report_date=20XX-XX-XX/NUFID_ENTRIES_20XX.csv`
* `s3://nu-spark-us-east-1/non-datomic/static-datasets/matera-exports-csv/entity=nu_pag/report_date=20XX-XX-XX/NUPAG_ENTRIES_20XX.csv`
* `s3://nu-spark-us-east-1/non-datomic/static-datasets/matera-exports-csv/entity=nu_pay/report_date=20XX-XX-XX/NUPAY_ENTRIES_20XX.csv`

Replace `20XX-XX-XX` with today's date and `20XX` with the relevant year to which the data relates.  If there are additional legal entities than the four listed above, each legal entity should have its own file (and this documentation must be updated).

Each file should conform to the [MateraExport row format](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/static/package.scala#L28).

2) After all files have been added to `matera-exports-csv`, we need to convert them to parquet format to validate and ensure better reliability.

Use the [Matera Exports Databricks Notebook](https://nubank.cloud.databricks.com/#notebook/102350) to convert from CSV to Parquet format.  In the notebook, replace 20XXXX with the current month (e.g., 201707).  You'll notice that this notebook prepares the actual parquet file as well as a test version.  The test version of the static file does not need to be updated with every Matera update.  The copy operation at the very end is commented to avoid accidentally running, but you'll need to run this command to actually update the files read by Itaipu.


### HR Variable Headcount

Ask the People & Culture squad for these inputs.

  * [Google sheet](https://docs.google.com/spreadsheets/d/17tDi9mdhn1cRH0PxpY6tvYi3LRkUZbfCEY6jX9AaTko)
  * [Format](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/static/package.scala#L60)
  * Example: `s3://nu-spark-us-east-1/non-datomic/static-datasets/hr-variable-headcount/report_date=2017-07-19/variable_headcount.csv`
  * [Databricks Workbook](https://nubank.cloud.databricks.com/#notebook/91349)


### HR Total Headcount

Ask the People & Culture squad for these inputs.

  * [Google sheet](https://docs.google.com/spreadsheets/d/17tDi9mdhn1cRH0PxpY6tvYi3LRkUZbfCEY6jX9AaTko)
  * [Format](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/static/package.scala#L67)
  * Example: [NO GOOD EXAMPLE, WAS CONVERTED TO PARQUET, NO CSV]

[TODO: just combine this with the variable headcount sheet so there is 1 update required]


### Matera Book Accounts

The Matera chart of accounts changes over time, but not as quickly as the data itself.  Nonetheless, it is always good to update the Matera Book Accounts as a matter of hygiene.  These are also exported from Matera.

  * [Format](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/static/package.scala#L69)
  * Example: `s3://nu-spark-us-east-1/non-datomic/static-datasets/matera-book-accounts/report_date=2017-07-20/accounts.csv`


### Contribution Margin Finance Inputs

Ask the FP&A squad to provide these inputs.

  * [Google sheet](https://docs.google.com/spreadsheets/d/17tDi9mdhn1cRH0PxpY6tvYi3LRkUZbfCEY6jX9AaTko)
  * [Format](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/static/package.scala#L234)
  * Example: `s3://nu-spark-us-east-1/non-datomic/static-datasets/contribution-margin-finance-inputs/report_date=2017-08-14/contribution_margin_finance_inputs.csv`


### Contribution Margin Collections Inputs

Ask the collections squad to provide these inputs.

  * [Google sheet](https://docs.google.com/spreadsheets/d/17tDi9mdhn1cRH0PxpY6tvYi3LRkUZbfCEY6jX9AaTko)
  * [Format](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/static/package.scala#L230)
  * Example: `s3://nu-spark-us-east-1/non-datomic/static-datasets/contribution-margin-collections-inputs/report_date=2017-08-15/contribution_margin_collections_input.csv`


### VAMP

This is a temporary static op for convenience in comparing ETL-based contribution margin numbers with the VAMP numbers, as VAMP remains the gold standard until we update VAMP to depend on ETL-based contribution margin as an input (as opposed to an alternative calculation methodology).  Note that this input file is subject to change as VAMP has been rapidly evolving.  Considered temporary.

  * [Format](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/static/package.scala#L83)
  * Example: `s3://nu-spark-us-east-1/non-datomic/static-datasets/vamp/report_date=2017-08-07/vamp.csv`
