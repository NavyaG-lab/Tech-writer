# Data Infra CLI (sabesp) examples

Sabesp's repository: https://github.com/nubank/sabesp

## Installation

```shell
pip install -i https://pypi.nubank.com.br/pypi sabespcli
```

Note: to deal with potential `Permission denied` issues during package installation, you can either use `sudo` (not recommended) or use `virtualenv`

## Usage

If you want to run an arbitrary command to test `sabesp` itself, consider for
example this command that tries to scale up a cluster and fails (because x is not a number):
```shell
sabesp --aurora-stack=cantareira-midea jobs create test scale MODE=try-spot N_NODES=x --check
```

### Create Belo Monte users
```shell
sabesp utils create-user <username>
```

### Start a test run of the dagao:
(The best way to do this is by triggering the Go pipeline, e.g.: https://go.nubank.com.br/go/pipelines/dagao/49/test/1)

```shell
[TBD]
```

### Kill a test run of the dagao:

```shell
sabesp --aurora-stack cantareira-test jobs kill dagao-47 test dagao-47
```

### Kill a specific job within the test dagao run (itaipu for example):

```shell
sabesp --aurora-stack cantareira-test jobs kill dagao-47 test itaipu
```

### Run the full dagao on the dev cluster (ensure nobody is using the dev cluster):

```shell
sabesp --aurora-stack cantareira-stable \
  jobs create devel dagao --check \
  METAPOD_REPO=s3a://nu-spark-metapod \
  METAPOD_ENVIRONMENT=prod \
  FINANCE_REPORT_PREFIX=s3://nu-fidc-prod/relatorios \
  REPORT_PREFIX=s3://nu-reports \
  LOG_PREFIX=s3a://nu-spark-us-east-1/db-dumps/ \
  OUTPUT_PREFIX=s3a://nu-spark-us-east-1/data
```

### Run a special version of the dagao on the dev cluster, pointed at Metapod prod to load DataBricks and devel Redshift

```shell
sabesp --aurora-stack cantareira-stable \
   jobs create devel dagao --check \
   METAPOD_REPO=s3a://nu-spark-metapod \
   METAPOD_ENVIRONMENT=prod \
   REPORT_PREFIX=s3://nu-reports \
   LOG_PREFIX=s3a://nu-spark-us-east-1/db-dumps/ \
   OUTPUT_PREFIX=s3a://nu-spark-us-east-1/data \
   "profile.das_path=s3://nu-spark-us-east-1/dags/test/dagao-135.json"
```

Note that this includes the Redshift load (into the devel Redshift cluster).

### Check the status of a job:

```shell
[TBD]
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
sabesp --aurora-stack=cantareira-stable jobs create prod key-integrity-vara OUTPUT_PREFIX=s3://nu-spark-us-east-1/data TARGET_DATE=2017-03-29 METAPOD_TRANSACTION=88f6c331-6505-4602-9adc-4b50cd35898f
```

### Cancel a run of the dagao:

```shell
[TBD]
```

### Run a filtered version of the dagao on the dev2 cluster (ensure nobody is using the dev2 cluster):

```shell
[TBD]
```

### Retry a failed run of the dagao (using the same metapod transaction id to pick up where it left off)

just add the **"profile.metapod_transaction=<tx>"** to the sabesp command.

```shell
sabesp --aurora-stack=cantareira-stable jobs create prod dagao \
"profile.metapod_transaction=13303089-db42-4f7e-b47c-efecf2cc385e""
```

### Retry a failed run of the dagao (using the same metapod transaction id to pick up where it left off) and start from a point in the dag

In this example, just the things after generate manifest failed, and I wanted to run it again, so i start with the existing metapod-transaction by setting **"profile.metapod_transaction=<tx>"**, **"profile.start_from=<task>"**.  In this case i had to exclude some datasets from the dag, so i use the attribute **"profile.exclude=<dataset>,<dataset>"**.

```shell
sabesp --aurora-stack=cantareira-stable jobs create prod dagao \
"profile.metapod_transaction=13303089-db42-4f7e-b47c-efecf2cc385e" \
"profile.start_from=generate-manifest" \
"profile.exclude=credit-limit-dataset,reactive-limit-model,proactive-limit-model,copy-model-csvs,scale-down,sleeper,cronno-model,hyoga-model,dimensional-modeling-vara"
```

### Retry a single job (not the whole dagao) which requires 2 metapod transaction ids (only credit limit stuff)

```shell
sabesp --aurora-stack=cantareira-stable jobs create prod credit-limit-dataset OUTPUT_PREFIX=s3://nu-spark-us-east-1/data TARGET_DATE=2017-03-29 METAPOD_ENVIRONMENT=prod METAPOD_TRANSACTION=52f3a86d-b32b-4a37-aabb-85a55bf50304 METAPOD_REPO=s3a://nu-spark-metapod CREDIT_LIMIT_TRANSACTION=58dc66b6-1c21-4a12-9b37-d3b76b4045f0
```

Note that you need to hardcode the relevant commit SHA into your local aurora-jobs

### Retry the dagao downstream of the credit-limit-dataset (inclusive), which requires 2 metapod transaction ids:

```shell
sabesp --aurora-stack=cantareira-stable jobs create prod dagao \
"profile.metapod_transaction=52f3a86d-b32b-4a37-aabb-85a55bf50304" \
"profile.start_from=credit-limit-dataset" \
"profile.credit_limit_metapod_transaction=58dc66b6-1c21-4a12-9b37-d3b76b4045f0"
```

Note that you need to hardcode the relevant commit SHA into your local aurora-jobs

### Schedule the dagao to run every day at a certain time:

```shell
[TBD]
```

### Kill an ad hoc dagao run on devel

```shell
sabesp --aurora-stack cantareira-stable jobs kill jobs devel dagao
sabesp --aurora-stack cantareira-stable jobs kill jobs devel itaipu
```

### Kill a job running from the scheduled dagao run:

```shell
sabesp --aurora-stack cantareira-stable jobs kill jobs prod hyoga-model
```

### Inspecting a metapod transaction

```shell
sabesp metapod --env prod --token transaction get 9684e3c0-a961-45da-add2-17b3de5b513b | jq . | less
```

### Starting the dagão of the current DAS by hand

```shell
sabesp --aurora-stack cantareira-stable raw cron start aurora/jobs/prod/dagao
```

### Manually commit a dataset to metapod

```shell
sabesp metapod --token --env prod dataset commit <metapod-transaction-id> <dataset-id> parquet s3://nu-spark-us-east-1/non-datomic/static-datasets/empty-materialized/empty.gz.parquet
```

See the entry in [Ops How-To](ops_how_to.md#manually-commit-a-dataset-to-metapod) for more details

## Troubleshooting

### 403 Forbidden

Receiving a 403 error is commonly caused clock skew between the local docker machine and aurora.  Restart docker and retry the command.
