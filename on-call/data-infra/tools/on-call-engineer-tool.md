---
owner: "#data-infra"
---

<!-- markdownlint-disable-file -->

# Hausmeister Tooling #

These are a set of tools that should aid the Hausmeister in performing certain tasks in an organized and straight-forward way.

## Setting up ##

The following projects need to be installed:

  * [nucli.py](https://github.com/nubank/nucli.py): A new port of nucli that serves as the hostbed for Hausmeister CLI operations.
  * [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive): A set of command-line tools for the Google Cloud Platform. Used for operations that interact with BigQuery.
  
After `gcloud` SDK is installed, run the following to setup your Google Account Credentials. Use your `nubank` email address to authenticate. 
  ```
  gcloud auth application-default login
  ```

## Use Cases ##

### Aborting a dataset ###

The command `dataset-abort` can be used to abort a dataset given a transaction ID and the 
dataset name, thus preventing the re-computation of this dataset for the duration of this transaction. The successors of this dataset will be automatically skipped by itaipu and have them aborted in metapod as well.

Example:
```
nu datainfra hausmeister dataset-abort a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
```

### Uncommitting a dataset along with its predecessors ###

The command `dataset-uncommit` can be used to uncommit a dataset from a transaction given the transaction ID and the
dataset name, in order to allow a further attempt to recompute this dataset after fixing its definition. To include
its predecessors, use the `--include-predecessors` switch in the command.

Example:
```
nu datainfra hausmeister dataset-uncommit --include-predecessors a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
```

### Resetting a dataset along with its predecessors ###

The command `dataset-reset` can be used to reset a dataset from a transaction given the transaction ID and the
dataset name, in order to allow a further attempt to recompute this dataset after fixing its definition. To include
its predecessors, use the `--include-predecessors` switch in the command. This command has similar functionality to
`dataset-uncommit` but much faster because it performs operations in bulk

Example:
```
nu datainfra hausmeister dataset-reset --include-predecessors a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops --reset-batch-size 100
```

### Flagging a dataset to get automatically aborted every day ###

The commands `dataset-flag` and `dataset-unflag` can be used to manage which dataset runs get aborted automatically in future transactions. By flagging a dataset, we are putting it on a list of datasets that get aborted automatically. This is useful when a dataset is broken or too heavy and we know it will take some time to fix - rather than removing it from Itaipu temporarily or aborting it manually every day, we can add it to the list of flagged datasets. Similarly, once we think it is fixed and should stop getting aborted automatically, we can remove it from the list by unflagging it.
To check what is currently on the list, the `dataset-flagged-list` command can be used.

Example:
```
nu datainfra hausmeister dataset-flag --flagging-reason-details "Is too heavy" dataset/spark-ops

nu datainfra hausmeister dataset-flagged-list

nu datainfra hausmeister dataset-unflag dataset/spark-ops
```

## CLI Commands ##

All the commands are available under `nu datainfra hausmeister`.

### `dataset-id [options] <tx-id> <dataset-name>` ##

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_id.py)]

Get the ID for a dataset in a transaction.

Example:
```
nu datainfra hausmeister dataset-id --env staging a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
```

### `dataset-path [options] <tx-id> <dataset-name>` ###

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_path.py)]

Get the path for a dataset in a transaction.

Example:
```
nu datainfra hausmeister dataset-path a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
```

### `dataset-uncommit [options] <tx-id> <dataset-name>` ###

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_uncommit.py)]

Uncommit a dataset from a transaction idempotently.

Example:
```
nu datainfra hausmeister dataset-uncommit -q --metapod-max-attempts 50 a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
```

### `dataset-reset [options] <tx-id> <dataset-name>` ###

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_reset.py)]

Reset a dataset from a transaction idempotently. This is a replacement for `dataset-uncommit` and it performs faster due to bulk operations

Example:
```
nu datainfra hausmeister dataset-reset -q --metapod-max-attempts 50 a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
```

### `dataset-abort [options] <tx-id> <dataset-name>` ###
[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_abort.py)]

Abort a dataset in a transaction.

Example:
```
nu datainfra hausmeister dataset-abort a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
```

### `dataset-successors [options] <tx-id> <dataset-name>` ###

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_successors.py)]

Get the successor datasets to a given dataset in a transaction.

Example:
```
nu datainfra hausmeister dataset-successors a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-op
```

### `dataset-predecessors [options] <tx-id> <dataset-name>` ###

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_successors.py)]

Get the predecessor datasets to a given dataset in a transaction.

Example:
```
nu datainfra hausmeister dataset-predecessors a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-op
```

### `dataset-flag [options] <dataset-names>...` ###

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_flag.py)]

Flag a dataset to get automatically aborted every day.

Example:
```
nu datainfra hausmeister dataset-flag --flagging-reason-details "Is broken" dataset/spark-ops
```

Note: Using `--flagging-reason-details` is optional but highly encouraged. 

You can fill it with a description of what's wrong with the dataset and/or links to relevant Slack threads.

### `dataset-unflag [options] <dataset-names>...` ###

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_unflag.py)]

Remove a dataset from the list of datasets to get automatically aborted every day.

Example:
```
nu datainfra hausmeister dataset-unflag dataset/spark-ops
```

### `dataset-flagged-list [options] <dataset-names>...` ###

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_flagged_list.py)]

List all datasets that are getting automatically aborted every day. 

Example:
```
nu datainfra hausmeister dataset-flagged-list --as-of 2021-11-12T00:00:00Z
```
