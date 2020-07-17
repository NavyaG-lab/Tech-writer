# Bumping Spark Versions on Itaipu

## Code Changes
Spark version upgrade requires changes across 3 code repositories.

### `Spark`

1. Clone [nubank/spark](https://github.com/nubank/spark) into a local repository.
2. Set [apache/spark]((https://github.com/apache/spark)) as a remote.
   ```
   git remote add upstream git@github.com:apache/spark.git
   ```
3. Fetch latest code from `upstream`
   ```
   git fetch upstream
   ```
4. This playbook assumes you are trying to upgrade to Spark `v2.4.6`. The Spark project maintains a separate branch for each release version. Let us fetch the corresponding branch for `v2.4.6`.
   ```
   git checkout tags/v2.4.6 -b branch-2.4.6
   ```
5. Create a new release branch for `nubank/spark`
   ```
   git checkout nubank-2.4.5-hadoop-2.9.2
   git checkout -b nubank-2.4.6-hadoop-2.9.2
   ```
6. Rebase to `v2.4.6`
   ```
   git rebase -i branch-2.4.6
   ```
7. Bump `SPARK_VERSION` in [build.d/build.sh](https://github.com/nubank/spark/blob/nubank-2.4.5-hadoop-2.9.2/build.d/build.sh) file to `2.4.6`.
8. Mesos fetches Spark builds from an `s3` bucket. Point [SPARK_EXECUTOR_URI](https://github.com/nubank/spark/blob/c8aee62e0d825c18e4c6bff8444e9ff5544ceb9d/conf/spark-env.sh#L4) to the new Spark bundle. The actual bundle will be available on `s3` only after we set up the `GoCD` pipelines, but we can guess the name of the object already (because we control it [here](https://github.com/nubank/spark/blob/nubank-2.4.5-hadoop-2.9.2/build.d/build.sh)). In this case, we should set the following:
   ```
   SPARK_EXECUTOR_URI=https://s3.amazonaws.com/nu-mirror-us-east-1-autocopy/apache-spark/spark-2.4.6-bin-hadoop-2.9.2-scala-2.11-nubank.tgz
   ```
8. Push the new branch. You can set it to be the new `default` branch using the Github Web UI, although it is not mandatory for the next steps.
   ```
   git push --set-upstream origin nubank-2.4.6-hadoop-2.9.2
   ```

### `GoCD-Config-DSL`

We need GoCD pipelines for Spark to build our new Spark branch. This can be done by updating the name of the `default` branch to build in [gocd-config-dsl]. An illustrative PR is [gocd-config-dsl/#1887](https://github.com/nubank/gocd-config-dsl/pull/1887/files). You might need to raise it with #foundation-tribe to get your PR reviewed.

### `Itaipu`
Once the GoCD pipelines build the Spark bundles, and we have it available on [s3](https://s3.amazonaws.com/nu-mirror-us-east-1-autocopy/apache-spark/), we can create an Itaipu PR to start using the new Spark version. [itaipu/#11245](https://github.com/nubank/itaipu/pull/11245/files) is an illustrative example for this PR.

Merging this PR is the final step for your changes to be deployed in production, and this should wait until after proper testing (see section on #Testing).

### Make Artefact Public
We mentioned above that Mesos downloads Spark bundles from an `s3` bucket. A further step is required to make this possible. Make your new Spark bundle on `nu-mirror-us-east-1-autocopy/apache-spark` bucket public. In our running example we should make https://s3.amazonaws.com/nu-mirror-us-east-1-autocopy/apache-spark/spark-2.4.6-bin-hadoop-2.9.2-scala-2.11-nubank.tgz public.


## Testing
This is the final (and hairiest) stage of Spark upgrades. We have no foolproof testing strategy available which provides us with a 100% coverage. However, we can ascertain issues at many levels before your Itaipu PR is merged & deployed to production.

### Itaipu Test Suite
Some breaking changes in APIs will surface as test failures (or even warnings during Itaipu compile/test phase). Keep an eye out for them. A recent example of such an issue was the change in behaviour of `na.fill` method, and the fix involved manual migration of a few datasets ([1](https://github.com/nubank/itaipu/pull/9936), [2](https://github.com/nubank/itaipu/pull/11247)).

### Pororoca
Use [Pororoca](../itaipu/pororoca.md) to run an _Itaipu_ job for the golden datasets.

### Contracts
Build a custom Itaipu image from your PR, and use it to run an _Itaipu_ job for a handful of Itaipu `contracts`.

`Contracts` are among the earliest datasets to run in a given Itaipu daily run, and issues affecting them tend to affect all the SLOs for our daily runs. Hence, this test is an important check to perform. Again, a 100% coverage is unrealistic, and my suggestion is to limit yourself to about 5 randomly-selected `contracts`.

### Itaipu-Rest
`Itaipu-Rest` node is a catch-all node on `Dagao`. You could run all the datasets in that node for a particular node. Co-ordinate with the Hausmeister to make sure your tests do not impact the state of the daily run.

That's it! If the above tests were satisfactory, we are ready to merge that PR. Notify the hausmeister of the incoming PR. In case of failures during the run, the only revert which needs to be performed is the PR merged on Itaipu.
