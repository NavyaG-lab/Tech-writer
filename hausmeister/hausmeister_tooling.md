# Hausmeister Tooling #

These are a set of tools that should aid the Hausmeister in performing certain tasks in an organized and straight-forward way.

## Setting up ##

The following projects need to be installed:

  * [nucli.py](https://github.com/nubank/nucli.py): A new port of nucli that serves as the hostbed for Hausmeister CLI operations.
  * [Google Cloud SDK](https://cloud.google.com/sdk): A set of command-line tools for the Google Cloud Platform. Used for operations that interact with BigQuery.

## Use Cases ##
### Committing a dataset empty along with its successors ###
The command `dataset-commit-empty` can be used to commit-empty a dataset given a transaction ID and the 
dataset name, thus preventing the re-computation of this dataset for the duration of this transaction. To include 
its successors, use the `--include-successors` switch in the command.

Example:
```
nu datainfra hausmeister dataset-commit-empty --include-successors a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
```

### Uncommitting a dataset along with its predecessors ###
The command `dataset-uncommit` can be used to uncommit a dataset from a transaction given the transaction ID and the
dataset name, in order to allow a further attempt to recompute this dataset after fixing its definition. To include
its predecessors, use the `--include-predecessors` switch in the command.

Example:
```
nu datainfra hausmeister dataset-uncommit --include-predecessors a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
```

## CLI Commands ##

All the commands are available under `nu datainfra hausmeister`.

### `dataset-id [options] <tx-id> <dataset-name>` ##

[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_id.p)]

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

### `dataset-commit-empty [options] <tx-id> <dataset-name>` ###
[[source](https://github.com/nubank/nucli.py/blob/master/src/nucli/datainfra/hausmeister/dataset_commit_empty.py)]

Commit a dataset empty in a transaction.

Example:
```
nu datainfra hausmeister dataset-commit-empty --uncommit-first a374ea98-d7c3-4a4d-b18f-4b83c1c9dfd9 dataset/spark-ops
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
