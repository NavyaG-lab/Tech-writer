# Archived Datasets Reference

The dataset archive system allows you to save the output of any ETL dataset for reuse in a subsequent run.

A typical use case is when computing a model every day. The authors of the model might want to keep track of the scores output by the model over time, and analyse them as part of model monitoring efforts. In such a scenario, they would set up the dataset to be archived, thereby exposing a new dataset in the ETL containing the history of outputs of their model.

Setting up a dataset to be archived is a two-fold process:

1. Add relevant metadata to the dataset for the ETL to correctly trigger its archiving after each successful computation.
2. Write an archive `DatasetSeriesContractOp` for the ETL to correctly read it back in subsequent runs.

This reference document assumes that you understand how to code up a basic `SparkOp`, and that you are somewhat familiar with the `DatasetSeriesContractOp` API.

### Relevant vocabulary

* Transaction id: the unique identifier of a daily run
* Run target date: the date on which a run was started

### Notes on archive datasets

* Datasets output by the archive system are augmented with the following metadata columns:

  | Name                     | Type         | Description                                                  |
  | ------------------------ | ------------ | ------------------------------------------------------------ |
  | `archive_index`          | `StringType` | A hash of the archive row composed of the original dataset's primary key concatenated to the run's target date. |
  | `archive_date`           | `StringType` | The target date of the run producing the archived row        |
  | `archive_version`        | `StringType` | The first few characters of the git commit hash of the version of Itaipu which created the row |
  | `archive_environment`    | `StringType` | The environment in which the row was created. For most use cases, this should be `prod` |
  | `archive_transaction_id` | `StringType` | The transaction id for the run that produced the row         |

* The dataset archive feature builds on the `DatasetSeriesContractOp` API as it facilitates deduplication and schema reconciliation. In the case of archives, its schema reconciliation facilities are particularly useful as they allows you to safely evolve your dataset's schema without catastrophically breaking its ingestion. The trade-off is that you need to be careful to update the corresponding `DatasetSeriesContractOp` after any modification of the dataset; if you do not, new versions of your dataset will be dropped and will not appear in subsequent runs until you fix the Op. See relevant section in the Dataset Series documentation for more information on [schema evolution](dataset_series.md#dealing-with-versions) & [troubleshooting dropped datasets](dataset_series.md#droppedschemas).

### Set up

#### 1. Marking a dataset for archiving

Marking your dataset for archiving is done by setting the `SparkOp`'s `archiveMode` attribute to `common_etl.operator.ArchiveMode.CreateArchive` and ensuring it extends `DeclaredSchema`.

```scala
package etl.dataset.mysquad

import common_etl.operator.{ArchiveMode, SparkOp}
import common_etl.schema.DeclaredSchema
...

object MyDataset extends SparkOp with DeclaredSchema {
  
  override val name = "dataset/my-dataset"
  
  ...
  
  override val archiveMode: ArchiveMode = ArchiveMode.CreateArchive
  
  ...
  
  override def attributes: Set[Attribute] = Set(
    ...
  )
}
```

#### 2. Setting up a `DatasetSeriesContractOp`

This step is automated when using [Squish](dataset_series.md#squish) (which should work for most Archived Datasets).

You can set up your series normally as described in the [Dataset Series documentation](dataset_series.md), keeping the following in mind:

* We usually try to keep all archives in the `archived` package of the `dataset_series` package
* The `name` attribute of your `DatasetSeriesContractOp` is identical to your original dataset's with all `/` characters replaced with `-`. For example, `dataset/my-dataset` becomes `dataset-my-dataset`
* as described above, the archive system adds additional metadata columns to your dataset, which would need to be required in the dataset series definition as well. For this purpose, you can use the `archivedSchema` function (available in the `archived` package) to turn any normal Dataset Series schema into its augmented version.



```scala
package etl.dataset_series.archived

object MyDataset extends DatasetSeriesContractOp {
  
  val name = "dataset-my-dataset"
  
  ...
  
  // Earlier version of the dataset, no longer being output
  private val v1 = Set(
    ...
  )
  
  // Current version
  private val v2 = Set (
    ...
  )
  
  val contractSchema = archivedVersion(v2)
  
  val alternativeSchemas = Seq(
    v1
  ).map(archivedVersion(_))
  
}
```

Note that by default, `archivedVersion` makes all metadata columns primary keys of your new dataset. If you wish to change this (to change deduplication behaviour for example), it also takes an optional `commonPrimaryKeys` which you can use to restrict which of these keys should be set as primary.
