---
owner: "#data-infra"
---

# Cantareira's Runtime Environment

_Table of Contents:_

* [Mesos overview](#mesos-overview)
* [Aurora overview](#aurora-overview)
* [Airflow overview](#airflow-overview)
* [Deployment](#deployment)
* [Types of Mesos Slaves](#types-of-mesos-slaves)
* [Upgrading Mesos](#upgrading-mesos)
  * [Reverting Bump](#reverting-bump)
* [Ops](#ops)
  * [Checking running instances](#checking-running-instances)
  * [Executor logs](#executor-logs)
  * [Updating Mesos IAM Roles](#updating-mesos-iam-roles)

The runtime relies on [Apache Mesos](http://mesos.apache.org/) for managing the resources, every ec2 instance that we use in the [Nightly Run](https://github.com/nubank/data-infra-docs/blob/master/monitoring_nightly_run.md) register itself as a Mesos Slave and its resources becomes available in the Mesos's pool of resources. For running jobs [Apache Aurora](https://github.com/nubank/aurora-jobs/blob/master/README.md#whats-aurora) is used, which register as a [Mesos Framework](http://mesos.apache.org/documentation/latest/architecture/) and accept Mesos offers.

When creating an Aurora Job, you need to specify the resources that this job is going to use, Aurora manages to accept offers from Mesos and run this process on a slave with enough capacity. More on this [Resource Isolation](http://aurora.apache.org/documentation/latest/features/resource-isolation/) and [Constraints](http://aurora.apache.org/documentation/latest/features/constraints/).

## Mesos overview

Mesos is a cluster manager that provides efficient resource isolation and resource sharing across distributed applications. It ensures that applications have the resources they need; a pool of machines can be shared and used to run different parts of your application without them interfering with each other. It also provides dynamic allocation of resources as needed.

Mesos consists of a *master* daemon that manages *agent* daemons (running on each cluster node), and *Mesos frameworks* that run *tasks* on these agents.

Further information on *frameworks* can be found [here](http://mesos.apache.org/documentation/latest/architecture/).

Note: There is no semantic different between *agents* and *slaves*, the terminology *slave* is deprecated and *agent* is preferred and recommended. Source: [https://issues.apache.org/jira/browse/MESOS-1478](https://issues.apache.org/jira/browse/MESOS-1478)

## Aurora overview

* [Aurora](http://aurora.apache.org/) is a resource manager that schedules and runs jobs across a [Mesos](http://mesos.apache.org/) cluster. All our jobs run inside Docker containers, so each job can execute arbitrary code written in separate languages/frameworks, as long as they are able to run on Linux.
  * The job definitions are written as a `.aurora` files and stored in the [aurora-jobs](https://github.com/nubank/aurora-jobs/tree/master/jobs) repo. `.aurora` files are [Pystachio](https://github.com/wickman/pystachio) templates that generate Python code to define the jobs themselves. A good reference to start understanding how they are structured is [the official tutorial](http://aurora.apache.org/documentation/latest/reference/configuration-tutorial/).
  * A short description of the jobs:
    * `itaipu-*` jobs run Spark driver nodes to run datasets defined in [itaipu](/primer.md#itaipu-overview). The Spark driver nodes talk directly to Mesos to get more resources, so only the driver node is managed via Aurora.
    * `scale-ec2-*` and `downscale-ec2-*` jobs add more machines to the Mesos cluster to run other jobs. Since AWS charges us per second of running time per instance, we scale up separate pools of machines for each `itaipu` job and Python machine learning model to have better isolation and debugging. The code to scale up and down the instances is in a small Python project we wrote called [scale-cluster](https://github.com/nubank/scale-cluster).
    * `*-model` are a set of jobs to run Python machine learning models. Most of them are defined in [batch-models-python](https://github.com/nubank/batch-models-python), a project maintained by the data scientists.

## Airflow overview

Airflow is the piece which controls when to execute, what to execute and what's the execution order. All code related to Airflow is a normal python code and is in the [airflow](https://github.com/nubank/aurora-jobs/tree/master/airflow) directory on [aurora-jobs](https://github.com/nubank/aurora-jobs/).

More stuff at [Airflow maintenance](/tools/airflow.md)

## Deployment

Creating a `MesosCluster` is done using the [Deploy](https://github.com/nubank/deploy), follow the guide in the project's README to install it.

1. Start the console using the cantareira environment `./console cantareira`
2. To create/update the cluster just type: `MesosCluster.create!("test")`.
3. To update individual Slaves you can type: `MesosFixed.create!("test")`, `MesosOnDemand.create!("test")`

As most of the things on Nubank, Mesos also runs as a container inside a `CoreOS` instance, the container definition is in the [dockerfiles](https://github.com/nubank/dockerfiles/) project. To change it you need to open a PR, get it merged, a pipeline on GO will build the docker image and then you need to update the mesos version in both [deploy](https://github.com/nubank/deploy/blob/master/lib/recipes/mesos_cluster.rb#L30) and in the [scale-cluster](https://github.com/nubank/scale-cluster/blob/master/src/scale_cluster/ec2.py#L155) projects.

## Types of Mesos Slaves

We have several types of mesos slaves, one for each kind of workload. They can be specified when running a job by defining [Constraints](http://aurora.apache.org/documentation/latest/features/constraints/) in the aurora job file, eg: `constraints={'slave-type': 'mesos-fixed'}`.

* **Fixed Instances** - Created by the `MesosFixed` recipe, those instances doesn't scale up and down when we scale the cluster, that's the instance type that you want to use when your job is not fault tolerant.
* **General On-Demand Instances** - Created by the `MesosOnDemand` recipe, those instances are spin scaling up the `mesos-on-demand` auto-scaling group, every `MesosCluster` has an On Demand autoscaling group.
  * can be scaled up using the following command: `sabesp --verbose --aurora-stack=cantareira-stable jobs create prod scale MODE=on-demand N_NODES=0 SCALE_TIMEOUT=5 --job-version scale_cluster=df8da67`
* **Spot Instances** -  These instances are created using the [scale-cluster](https://github.com/nubank/scale-cluster) `scale-ec2` entrypoint. Upon every run, a separate Spotinst Elasticgroup is created, with similar parameters(type, size, storage class) for every node in the group.
**Important**: Instance type may slightly vary within the group, but instance type and size must be compatible. Ex, the same group may have both `m5.2xlarge` and `m5n.2xlarge` instances, but not `r5.2xlarge` or `m5.xlarge`.
  * can be scaled up either through [scale-cluster](https://github.com/nubank/scale-cluster#using-spotinst) or by passing `--use-spotinst` flag to `sabesp jobs itaipu` command. Please note that within itaipu, currently only `itaipu` command supports this flat.

* **Specific On Demand Instances** - These instances are also created using the [scale-cluster](https://github.com/nubank/scale-cluster) `scale-ec2` entrypoint. The Specific On Demand instances are different from the other slaves as these involve spinning individual EC2 instances (not in auto-scale cluster). Therefore, you can specify different attributes for each instance (like: instance type, naming etc.).
  * can be scaled up using the following command: `sabesp --aurora-stack=cantareira-stable jobs create prod downscale-ec2-model SLAVE_TYPE=model NODE_COUNT=1 --job-version="scale_cluster=d749aa4" --filename scale-ec2`

## Upgrading Mesos

- Find the new mesos version, you can use `apt-get update && apt-cache search mesos` inside an ubuntu docker.
- Bump mesos version in mesos-base dockerfile follow [this](https://github.com/nubank/dockerfiles/pull/760/files) example.
- Bump mesos-base dependencies [eg](https://github.com/nubank/dockerfiles/pull/761/files)
- Bump deploy version of mesos-master and slave [eg](https://github.com/nubank/deploy/pull/3277)
- Bump sabesp version of aurora-client [eg](https://github.com/nubank/sabesp/pull/80)
- Bump aurora-jobs versions of aurora-client and sabesp [eg](https://github.com/nubank/aurora-jobs/pull/709)
- Bump all models that depend on `nu-mesos-python` or `nu-mesos-python-spark` (*you can use [source graph](https://sourcegraph.nubank.com.br/search) to find the repositories and `sed` + `hub` to open the PRs*)
- Create a test cluster using deploy's console [see here](#deployment)
- Run a successful job in the new cluster (using sabesp + itaipu filtered run)
- Merge all the stuff
- Update cantareira-dev and cantareira-stable clusters (using deploy's console as well)

### Reverting Bump

- Revert and merge:
  - `aurora-jobs`
  - `scale-cluster`
  - `deploy`
- Wait their pipelines to run in go run
- Retrigger `dagao` and `dagao-deploy` to send the changes on the two repos to airflow
- Update mesos cluster [see here](#deployment)

## Ops

### Checking running instances

You can check if the instances are running on the [AWS Console](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:tag:Name=cantareira-dev-mesos-on-demand-;sort=instanceId) and check the status of your jobs [here](https://cantareira-dev-aurora-scheduler.nubank.com.br:8080/scheduler/jobs). Now wait, it might take a while.

### Executor logs

Most of the logs relevant to issues are found on [aurora](https://cantareira-stable-aurora-scheduler.nubank.com.br:8080/scheduler/jobs/prod).

In the rare case that you want to see executor logs, navigate to [https://cantareira-stable-mesos-master.nubank.com.br/](https://cantareira-stable-mesos-master.nubank.com.br/)

From here you will need to manually navigate to the direct ip due to some dns issues.
look in the top left, where you will see something like:

```
Leader: ip-10-130-118-157.ec2.internal:5050
```

Navigate to that IP `10.130.118.157:5050`

Find your relevant active task and click `Sandbox` (note that opening this link in a new browser window is unsupported).
In the sandbox you can check the `stderr` and `stdout` logs.

Note that while doing this you will probably want to keep the machine up by disabling downscaling ([see here for instructions](../../on-call/data-infra/ops_how_to.md#keep-machines-up-after-a-model-fails)).

### Updating Mesos IAM Roles

IAM roles are stored in a separate project [iam-policies](https://github.com/nubank/iam-policies), to update them you need to change the file that corresponds the slave you want to change (or change all of them) files are:
* [Mesos Fixed Role](https://github.com/nubank/iam-policies/blob/master/role-lists/mesos-fixed.json)
* [Mesos On-Demand Role](https://github.com/nubank/iam-policies/blob/master/role-lists/mesos-on-demand.json)
* [Mesos Master Role](https://github.com/nubank/iam-policies/blob/master/role-lists/mesos-master.json)

Policies for mesos are inside the Mesos [directory](https://github.com/nubank/iam-policies/blob/master/policies/mesos/).

After you make a change, you need to deploy the changes via nucli:

```
nu iam create roles stable mesos-fixed --env cantareira
```

Done, now the iam-role for **mesos-fixed** in the stack **stable** is updated.
