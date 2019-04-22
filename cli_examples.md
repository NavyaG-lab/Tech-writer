# Data Infra CLI (sabesp) examples

Sabesp's repository: https://github.com/nubank/sabesp

Sabesp is avaiable as a [nucli](https://github.com/nubank/nucli) sub-command. For usage check out:
```shell
nu datainfra sabesp -- -h
```

## Usage

If you want to run an arbitrary command to test `sabesp` itself, consider for
example this command that tries to scale up a cluster and fails (because x is not a number):
```shell
nu datainfra sabesp -- --aurora-stack=cantareira-midea jobs create test scale MODE=try-spot N_NODES=x --check
```

### Kill a specific job within the dagao run (itaipu for example):

```shell
nu datainfra sabesp -- --aurora-stack cantareira-stable jobs kill jobs prod itaipu-contracts
```

### Check the status of a job:

```shell
nu datainfra sabesp -- --aurora-stack cantareira-stable jobs status jobs prod itaipu-contracts
```

### Restart a job that has gotten into an infinite loop:

For a task that is taking longer than expected, check to see if:

- in the task logs you see `17/03/19 21:28:34 WARN TaskSetManager: Lost task 31.3254 in stage 5253.3 (TID 329360, 10.130.124.36, executor 68): TaskCommitDenied (Driver denied task commit) for job: 5253, partition: 182, attemptNumber: 3254`
- in the status line of the aurora job `2 minutes ago - PENDING : Constraint not satisfied: slave-type`

Then you can use the following command to restart the specific task in question (this example is for itaipu).

For an ad hoc run on devel:

```shell
nu datainfra sabesp -- --aurora-stack cantareira-stable jobs restart jobs devel itaipu
```

For a scheduled run on prod:

```shell
nu datainfra sabesp -- --aurora-stack cantareira-stable jobs restart jobs prod itaipu
```

Running a specific job (not the full dagao)

```shell
nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs create prod capivara-clj
```

### Kill a job running from the dagao run:

```shell
nu datainfra sabesp -- --aurora-stack cantareira-stable jobs kill jobs prod hyoga-model
```

### Inspecting a metapod transaction

```shell
nu datainfra sabesp metapod -- --env prod --token transaction get 9684e3c0-a961-45da-add2-17b3de5b513b | jq . | less
```

## Running Itaipu

For these commands, when you don't specify a `--transaction` flag, it generates a random transaction for you

Also, the two s3 buckets, `s3a://nu-spark-metapod-test/` and `s3a://nu-spark-metapod-test/`, refer to the [`permanent` and `ephemeral`](/glossary.md#permanence-of-a-dataset) paths respectively.
For test cases you can set the same bucket, but if you run real jobs you should use the proper paths that [prod uses](https://github.com/nubank/aurora-jobs/blob/83ff733d40c5cfd6ec6bfcaa55f69c764a6f03ff/airflow/dagao.py#L193-L194).

### Full run scaling the cluster up and down

```shell
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs itaipu staging midea s3a://nu-spark-metapod-test/ s3a://nu-spark-metapod-test/ 5 --itaipu=4155f24b
```

### Full run scaling the cluster up and down and using the materialized log cache

```shell
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs itaipu staging midea s3a://nu-spark-metapod-test/ s3a://nu-spark-metapod-test/ 5 --itaipu=4155f24b  --use-cache
```

### Filtered run scaling the cluster up and down

```shell
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs itaipu staging midea s3a://nu-spark-metapod-test/ s3a://nu-spark-metapod-test/ 5 --itaipu=4155f24b  --filter-by-prefix contract
```


### Filtered run scaling the without scaling up or down

```shell
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs itaipu staging midea s3a://nu-spark-metapod-test/ s3a://nu-spark-metapod-test/ 5 --itaipu=4155f24b  --filter-by-prefix contract --skip-scale-up --skip-scale-down
```

**for a full list of possible switches run `sabesp jobs itaipu --help`**


### Manually run job

```
nu datainfra sabesp -- --aurora-stack=<stack> jobs create <env> <job> <binds> --metapod-transaction <transaction-id> --job-version "<job>=<version>"
```

e.g:
```shell
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs create staging capivara-clj DEPLOY_NON_DIMENSIONAL_MODELING=true OUTPUT_PREFIX=s3a://nu-spark-devel COPY_REDSHIFT_MAX_ERRORS=100 TARGET_DATE="2018-06-14" METAPOD_ENVIRONMENT=staging METAPOD_TRANSACTION=e25faed2-6578-4a57-a15a-01ec33642d5c --metapod-transaction e25faed2-6578-4a57-a15a-01ec33642d5c --job-version "capivara_clj=e6fbb31"
```

### Manually run cluster scale up job

Occasionally airflow may fail to run a cluster scale up job, which will cause a job to take way longer than usual because it doesn't have enough machines.
When this happens (instructions on verifying [this here](ops_how_to.md#checking-status-of-cluster-up-and-down-scales)), you may want to manaully run the scale up.

```shell
nu datainfra sabesp -- --aurora-stack=<stack> jobs create <env> scale-ec2-<job-name> NODE_COUNT=<nodes> SLAVE_TYPE=<job-name> --filename scale-ec2 --job-version"scale_cluster=<version>"
```

- `version`: corresponds to the version of [`scale-cluster` repository](https://github.com/nubank/scale-cluster) used for the daily ETL run. You can get this from the `Airflow started running a dagao` message on `#etl-updates`.
- `SLAVE_TYPE`: The job name, which will tag the instances with the name of your (itaipu) job. An example would be `itiapu-dimensional-modeling`.
- `INSTANCE_TYPE`: the correct instance type for your itaipu job can be found by searching for `instance_type` in [`airflow/dagao.py`](https://github.com/nubank/aurora-jobs/blob/5dd280285613670796e3f8fc31d44d811ab252da/airflow/dagao.py#L30) or defaults to [this](https://github.com/nubank/aurora-jobs/blob/5dd280285613670796e3f8fc31d44d811ab252da/airflow/itaipu.py#L31)
- `NODE_COUNT`: Number of instances to scale up to, which should be `cores / cores_per_instance`. `cores`, in the case of `itaipu-dimensional-modeling` for example, is defined in [`airflow/dagao.py`](https://github.com/nubank/aurora-jobs/blob/5dd280285613670796e3f8fc31d44d811ab252da/airflow/dagao.py#L44). And `cores_per_instance` is defined [here](https://github.com/nubank/aurora-jobs/blob/5dd280285613670796e3f8fc31d44d811ab252da/airflow/scale.py#L3-L9), where the instance type is proved [here](https://github.com/nubank/aurora-jobs/blob/5dd280285613670796e3f8fc31d44d811ab252da/airflow/itaipu.py#L31)

e.g:
```shell
nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs create prod scale-ec2-itaipu-dimensional-modeling NODE_COUNT=10 SLAVE_TYPE=itaipu-dimensional-modeling INSTANCE_TYPE=m4.2xlarge --filename scale-ec2 --job-version="scale_cluster=74e5894"
 ```

### Manually downscale the cluster
```shell
nu datainfra sabesp -- --aurora-stack=<stack> jobs create <env> downscale-ec2-<job-name> NODE_COUNT=<nodes> SLAVE_TYPE=<job-name> --filename scale-ec2 --job-version="scale_cluster=<version>"
```

e.g:
```shell
nu datainfra sabesp -- --aurora-stack=cantareira-stable jobs create staging downscale-ec2-itaipu-leo-test NODE_COUNT=20 SLAVE_TYPE=itaipu-leo-test --filename scale-ec2 --job-version="scale_cluster=74e5894"
 ```

### Manually commit a dataset to metapod

```shell
nu datainfra sabesp -- metapod --token --env prod dataset commit <metapod-transaction-id> <dataset-id> parquet s3://nu-spark-us-east-1/non-datomic/static-datasets/empty-materialized/empty.gz.parquet
```

See the entry in [Ops How-To](ops_how_to.md#manually-commit-a-dataset-to-metapod) for more details

## Troubleshooting

### 403 Forbidden

Receiving a 403 error is commonly caused clock skew between the local docker machine and aurora.  Restart docker and retry the command.
