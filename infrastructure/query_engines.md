# Query Engines used/considered at Nubank

|                               | AWS Redshift                        | Google BigQuery                | Spark (Databricks)             | Snowflake             |
|-------------------------------|-------------------------------------|--------------------------------|--------------------------------|--------------------------------|
| In production at Nubank       | Since mid 2016                      | No                             | No                             | No                           |
| Used for development          | No                                  | No                             | Yes<sup>1</sup>                | No                           |
| Metabase                      | Can connect                         | Can connect, no complex schema support<sup>2</sup>    | Can not connect                | Working driver, not officialy released<sup>20<sup>    |
| Looker                        | Can connect                         | Can connect                    | Can connect                    | Can connect<sup>21<sup>                 |
| Jupyter Notebook/Pandas       | Easy, using belomonte               | Easy, pd.read_gbq              | Embedded notebooks<sup>3</sup> | Basic connection through belomonte                  |
| DBeaver                       | Easy, lot of people doing it        | Can connect                    | Can't connect                  | Can connect<sup>22<sup>                           |
| Pricing model                 | Fixed cluster                       | Pay per query                  | Auto-scaling cluster           | Auto-scaling cluster                    |
| Runs on                       | AWS                                 | Google Cloud                   | AWS                            | AWS                           |
| We have experience            | Yes                                 | Yes                             | Yes                            | No                           |
| Loads data from               | S3 (Avro)                           | GCS (Avro/Parquet<sup>4</sup>) | Agnostic<sup>5</sup>           | S3 (Avro/Parquet)<sup>23<sup>                           |
| SQL Dialect                   | Very old PostgreSQL (8.0.2)         | Standard SQL                   | Spark SQL                      | Similar to Redshift's<sup>24<sup>                    |
| Complex schema support        | Limited JSON support                | Awesome<sup>6</sup>            | Sufficient<sup>7</sup>         | JSON support                         |
| Query start delay/overhead    | Relatively small<sup>8</sup>        | Relatively small<sup>9</sup>   | Relatively large<sup>10</sup>  | TODO                           |
| Caching                       | Data caching                        | Query caching                  | Data caching<sup>11</sup>      | Data caching<sup>25<sup>                           |
| Future potential<sup>12</sup> | Doesn't look promising<sup>13</sup> | Most promising<sup>14</sup>    | Promising<sup>15</sup>         | Promising                           |
| SLA in-place?                 | Great, existing AWS support         | None yet                       | Good, support is so-so         | None yet                           |
| Data load process             | Big overhead<sup>16</sup>           | Big overhead<sup>17</sup>      | Small overhead<sup>18</sup>    | TODO                           |
| BigDecimal support            | Yes, 18+ places                                 | Up to 9 places           | Yes, 18+ places                            | Yes, 18+ places                           |
| Concurrent query support      | TODO                                | TODO                           | TODO                           | TODO                           |
| Performance characteristics   | TODO                                | TODO                           | TODO                           | TODO                           |
| Bad query handling            | Cancels query<sup>19</sup>          | TODO                           | TODO                           | TODO                           |

1. Through notebooks
2. It doesn't support nested schemas [https://github.com/metabase/metabase/issues/5808]
3. Databricks has their own web based notebook implementation that runs Scala,
Python, R, and SQL that you are supposed to use if you want to benefit from auto
scaling clusters
4. Parquet is in beta
5. Can be any Hive-registered table
6. Google BigQuery has a lot of functions for arrays:
[https://cloud.google.com/bigquery/docs/reference/standard-sql/arrays]
7. Spark has sufficient support to create and unnest collections, but is
probably more verbose than BigQuery
8. Smaller overhead than reading from block storage like S3 because data is
stored on disk:
[https://docs.aws.amazon.com/redshift/latest/dg/c_redshift_system_overview.html]
9. Smaller overhead than reading from block storage like S3 because of
BigQuery's distributed filesystem Colossus:
[https://cloud.google.com/blog/big-data/2016/04/inside-capacitor-bigquerys-next-generation-columnar-storage-format]
10. Databricks queries files that are on block storage like S3, so IO
performance is worse than disk storage like Redshift and BigQuery
11. Databricks is improving its IO caching and its configurable:
[https://docs.databricks.com/user-guide/databricks-io-cache.html]
12. Hot new thing
13. AWS isn't adding great features to the Redshift core--just bandaid like
Spectrum
14. Google is pushing hard on its Google Cloud Platform
15. Spark is an active open-source project
16. Requires a system that generates manifest files to S3 and manage the
connection pooling
17. Currently requires a transfer of data from AWS to GCP, after that requires
some lambda style function that triggers load into BigQuery
18. Just needs to register a Hive table for it to be available for queries
19. Redshift cancels a bad query if the bad query is using all the disk space
20. Snowflake drive for Metabase PR: [https://github.com/metabase/metabase/pull/6658]
21. Looker and Snowflake integration: [https://looker.com/solutions/snowflake]
22. Snowflake supported SQL Editing / Querying Tools: [https://docs.snowflake.net/manuals/user-guide/ecosystem-editors.html]
23. Snowflake Data Loading: [https://docs.snowflake.net/manuals/user-guide/data-load.html]
24. How Compatible are Redshift and Snowflake’s SQL Syntaxes? [https://medium.com/@jthandy/how-compatible-are-redshift-and-snowflakes-sql-syntaxes-c2103a43ae84]
25. Snowflake caching tutorial [https://sonra.io/2018/03/05/deep-dive-on-caching-in-snowflake/]
