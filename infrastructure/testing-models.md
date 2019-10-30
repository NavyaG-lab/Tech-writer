# Testing models in staging

We have a staging environment which serves as our sandbox. Keep in mind that other environments, including production, are still accessible from our staging environment, since it's simply another stack in our environment.

The first step is to create a [metapod transaction](../glossary.md#transaction) in the staging environment. A metapod transaction is a entity that is composed by one or more datasets. You will be referring to that transaction by its ID.

If you are testing a change to a model that is already running in production:

### 1. Get a current transaction ID from Airflow

That will be used to specify the model input data. To get latest completed transaction ID, follow [these steps](https://github.com/nubank/data-infra-docs/blob/master/monitoring_nightly_run.md#finding-the-transaction-id).

### 2. Clone the datasets into a transaction in staging

Since you will run the model in staging, you'll need a metapod transaction in staging with the datasets the model needs as inputs. To do that, get the names for the input and output datasets (that should be in the model code).

With the existing metapod production transaction ID, input dataset and output dataset names, you can configure and run [this script](https://github.com/nubank/metapod/tree/master/scripts/copy_transaction) (run instructions in link) to create a transaction in staging and copy the necessary dataset data into this new transaction.

The script will output a staging metapod transaction ID (in an UUID format). Have it ready, since you will need it later.

### 3. Publish a new docker image with the model code changes

After you have model changes in a branch and pushed to Github, you can trigger the corresponding Go pipeline for the model via the [Go pipelines page](https://go.nubank.com.br/go/pipelines), you can trigger the pipeline via the button like below:

![image](https://user-images.githubusercontent.com/1674699/38299232-c1b8df3a-37f9-11e8-9116-fd46a2d05f62.png)

In the pop-up that will appear, choose the *Environment Variables* tab and put the corresponding branch name:

![image](https://user-images.githubusercontent.com/1674699/38299318-ff8e00ce-37f9-11e8-9d59-ad6eaf9f74e9.png)

And click the _Trigger Pipeline_ button. This will result in a new image being published. Go into the console output for the pipeline run that you triggered, to see the hash for the new image (7-char revision hash).

### 4. Run the model in staging

You should now have:
- a staging metapod transaction ID, referring to a transaction with the datasets you need
- a hash corresponding to the image version you published in the previous step

You can now run the model in staging using our CLI tool `sabesp`. To install sabesp, follow its [README](https://github.com/nubank/sabesp).

#### Scale up a cluster

First, you need to scale a _cluster_ to run the model. This basically
means spinning up one (or more) instances on which the model code will
run. To do that, clone the
[aurora-jobs](https://github.com/nubank/aurora-jobs) repository, as
`sabesp` uses the job definitions from that project to create the
tasks in aurora. After that, run the following `sabesp` command. Don’t forget to:

  * Replace the two occurrences of `<YOUR_NAME>` with your lowercase
    first or last name, to make it easier to identity the instances
  * Replace `<DOCKER_IMAGE_TAG>` with the latest value of the value
    found in [the corresponding Docker repo](https://quay.io/repository/nubank/nu-scale-cluster)


```
sabesp --verbose --aurora-stack=cantareira-dev jobs create staging scale-ec2-<YOUR_NAME> \
    SLAVE_TYPE=<YOUR_NAME> \
    INSTANCE_TYPE=m4.xlarge NODE_COUNT=1 \
    --job-version "scale_cluster=<DOCKER_IMAGE_TAG>" \
    --filename scale-ec2 \
    --check
```

When the command finishes successfully (`finished with end_time` present in the output), you are ready to run the model code in those instances.

#### Run the model

You will also use `sabesp` for this, but you also need the aurora task name that is configured for the model. You can check the `jobs/` directory in the `aurora-jobs` repository. E.g., for `contextual-model`, there is a `jobs/contextual-model.aurora` file, so that will be the job name that we will use, and `sabesp` will look for a file with that name in your cloned repository, under the `jobs/` folder (and with the `.aurora` suffix).

Now, you can use the command below:

```
sabesp --verbose --aurora-stack cantareira-dev jobs create staging <MODEL_NAME> \
  TARGET_DATE=<TARGET_DATE> \
  METAPOD_REPO=s3://nu-spark-devel/<YOUR_NAME> \
  METAPOD_TRANSACTION=<METAPOD_TRANSACTION_ID>
  SLAVE_TYPE=mesos-on-demand-<YOUR_NAME> \
  METAPOD_ENVIRONMENT=staging \
  --job-version <MODEL_NAME>=<IMAGE_VERSION>
```

And interpolate the following variables in it:

Variable | What it is | Example
---  | --- | ---
`<MODEL_NAME>` | the task name for the model | `contextual-model`
`<TARGET_DATE>` | the date the transaction was created | `2018-09-14`
`<METAPOD_TRANSACTION_ID>` | the staging metapod transaction ID you created using the script | `5aa26ba4-9b26-4355-a418-1f42759976b5`
`<YOUR_NAME>` | your name in lowercase, same one used to scale up the cluster in the previous step | `my-name`
`<IMAGE_VERSION>` | hash of the published docker image for the model | `491d6de`

#### Checking whether the task was successful

You can follow the task progress and success/failure status via the Aurora UI: https://cantareira-dev-aurora-scheduler.nubank.com.br:8080/scheduler/jobs

Search for your model name (e.g., `contextual-model`) and click it to go to the corresponding task page.
There you will see two tabs: **Active Tasks**, and **Completed Tasks**. Depending on the progress, the task will be in one of the two tabs.

Once you find it, click at the IP address to the right of the row where the task is displayed. You will see a web interface for the host. You can check the task status, command, duration, and check the `stdout` and `stderr` links to see the log output for that task.

> If you don't see an IP address, that could mean Aurora was not able to allocate the task to a host (yet). Double-check whether the `SLAVE_TYPE` passed was correct - it should be composed by `mesos-on-demand-` and the same name which was used to scale up the cluster.

> You can also check how are the agents' `SLAVE_TYPE` attributes registered in Mesos (also using the Aurora UI) via [this page](https://cantareira-dev-aurora-scheduler.nubank.com.br:8080/agents). The `slave-type` attribute should be equal to what is being passed in the `sabesp` command.

#### Scale down

Don't forget to scale down the cluster after you're done. You can use this command (again interpolating the `<YOUR_NAME>` variable):

```
sabesp --verbose --aurora-stack=cantareira-dev jobs create staging scale-ec2-<YOUR_NAME> SLAVE_TYPE=<YOUR_NAME> INSTANCE_TYPE=m4.xlarge NODE_COUNT=1 --job-version "scale_cluster=a93e3c8" --filename scale-ec2 --check
```
