# Data Infra CLI (sabesp) examples

Sabesp's repository: https://github.com/nubank/sabesp

## Installation

```shell
pip install -i https://pypi.nubank.com.br/pypi sabespcli
```

Note: to deal with potential `Permission denied` issues during package installation, you can either use `sudo` (not recommended) or use `virtualenv`

#### Upgrade

```shell
pip install -i https://pypi.nubank.com.br/pypi sabespcli --upgrade
```


## Usage

If you want to run an arbitrary command to test `sabesp` itself, consider for
example this command that tries to scale up a cluster and fails (because x is not a number):
```shell
sabesp --aurora-stack=cantareira-midea jobs create test scale MODE=try-spot N_NODES=x --check
```

### Kill a specific job within the dagao run (itaipu for example):

```shell
sabesp --aurora-stack cantareira-stable jobs kill jobs prod itaipu-contracts
```

### Check the status of a job:

```shell
sabesp --aurora-stack cantareira-stable jobs status jobs prod itaipu-contracts
```

### Restart a job that has gotten into an infinite loop:

For a task that is taking longer than expected, check to see if:

- in the task logs you see `17/03/19 21:28:34 WARN TaskSetManager: Lost task 31.3254 in stage 5253.3 (TID 329360, 10.130.124.36, executor 68): TaskCommitDenied (Driver denied task commit) for job: 5253, partition: 182, attemptNumber: 3254`
- in the status line of the aurora job `2 minutes ago - PENDING : Constraint not satisfied: slave-type`

Then you can use the following command to restart the specific task in question (this example is for itaipu).

For an ad hoc run on devel:

```shell
sabesp --aurora-stack cantareira-stable jobs restart jobs devel itaipu
```

For a scheduled run on prod:

```shell
sabesp --aurora-stack cantareira-stable jobs restart jobs prod itaipu
```

Running a specific job (not the full dagao)

```shell
sabesp --aurora-stack=cantareira-stable jobs create prod capivara-clj
```

### Kill a job running from the dagao run:

```shell
sabesp --aurora-stack cantareira-stable jobs kill jobs prod hyoga-model
```

### Inspecting a metapod transaction

```shell
sabesp metapod --env prod --token transaction get 9684e3c0-a961-45da-add2-17b3de5b513b | jq . | less
```

## Running Itaipu

### Full run scaling the cluster up and down

```shell
sabesp --aurora-stack=cantareira-dev jobs itaipu staging midea s3a://nu-spark-metapod-test/ 216 --itaipu=4155f24b
```

### Full run scaling the cluster up and down and using the materialized log cache

```shell
sabesp --aurora-stack=cantareira-dev jobs itaipu staging midea s3a://nu-spark-metapod-test/ 216 --itaipu=4155f24b  --use-cache
```

### Filtered run scaling the cluster up and down

```shell
sabesp --aurora-stack=cantareira-dev jobs itaipu staging midea s3a://nu-spark-metapod-test/ 216 --itaipu=4155f24b  --filter-by-prefix contract
```


### Filtered run scaling the without scaling up or down

```shell
sabesp --aurora-stack=cantareira-dev jobs itaipu staging midea s3a://nu-spark-metapod-test/ 216 --itaipu=4155f24b  --filter-by-prefix contract --skip-scale-up --skip-scale-down
```

**for a full list of possible switches run `sabesp jobs itaipu --help`**


### Manually run job 

```
sabesp --aurora-stack=<stack>  jobs create <env> <job> <binds> --metapod-transaction <transaction-id> --job-version "<job>=<version>"
```

e.g:
```shell
sabesp --aurora-stack=cantareira-dev jobs create staging capivara-clj  DEPLOY_NON_DIMENSIONAL_MODELING=true OUTPUT_PREFIX=s3a://nu-spark-devel COPY_REDSHIFT_MAX_ERRORS=100 TARGET_DATE="2018-06-14" METAPOD_ENVIRONMENT=staging METAPOD_TRANSACTION=e25faed2-6578-4a57-a15a-01ec33642d5c --metapod-transaction e25faed2-6578-4a57-a15a-01ec33642d5c  --job-version "capivara_clj=e6fbb31"

```

### Manually commit a dataset to metapod

```shell
sabesp metapod --token --env prod dataset commit <metapod-transaction-id> <dataset-id> parquet s3://nu-spark-us-east-1/non-datomic/static-datasets/empty-materialized/empty.gz.parquet
```

See the entry in [Ops How-To](ops_how_to.md#manually-commit-a-dataset-to-metapod) for more details

## Troubleshooting

### 403 Forbidden

Receiving a 403 error is commonly caused clock skew between the local docker machine and aurora.  Restart docker and retry the command.
