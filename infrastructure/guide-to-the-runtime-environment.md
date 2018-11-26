# Cantareira's Runtime Environment

The runtime relies on [Apache Mesos](mesos.apache.org) for managing the resources, every ec2 instance that we use in the [Nightly Run](https://github.com/nubank/data-infra-docs/blob/master/monitoring_nightly_run.md) register itself as a Mesos Slave and its resources becomes available in the Mesos's pool of resources. For running jobs [Apache Aurora](https://github.com/nubank/aurora-jobs/blob/master/README.md#whats-aurora) is used, which register as a [Mesos Framework](http://mesos.apache.org/documentation/latest/architecture/) and accept Mesos offers. 

When creating an Aurora Job, you need to specify the resources that this job is going to use, Aurora manages to accept offers from Mesos and run this process on a slave with enough capacity. More on this [Resource Isolation](http://aurora.apache.org/documentation/latest/features/resource-isolation/) and [Constraints](http://aurora.apache.org/documentation/latest/features/constraints/).


## Deployment

Creating a `MesosCluster` is done using the [Deploy](https://github.com/nubank/deploy), follow the guide in the project's README to install it. 

1. Start the console using the cantareira environment `./console cantareira`
2. To create/update the cluster just type: `MesosCluster.create!("test")`.
3. To update individual Slaves you can type: `MesosFixed.create!("test")`, `MesosOnDemand.create!("test")`

As most of the things on Nubank, Mesos also runs as a container inside a `CoreOS` instance, the container definition is in the [dockerfiles](https://github.com/nubank/dockerfiles/) project. To change it you need to open a PR, get it merged, a pipeline on GO will build the docker image and then you need to update the mesos version in both [deploy](https://github.com/nubank/deploy/blob/master/lib/recipes/mesos_cluster.rb#L30) and in the [scale-cluster](https://github.com/nubank/scale-cluster/blob/master/src/scale_cluster/ec2.py#L155) projects.

## Updating Mesos IAM Roles

IAM roles are stored in a separate project [iam-policies](https://github.com/nubank/iam-policies), to update them you need to change the file that corresponds the slave you want to change (or change all of them) files are:
* [Mesos Fixed Role](https://github.com/nubank/iam-policies/blob/master/mesos-fixed.json) 
* [Mesos On-Demand Role](https://github.com/nubank/iam-policies/blob/master/mesos-on-demand.json) 
* [Mesos Spot Multi Az Role](https://github.com/nubank/iam-policies/blob/master/mesos-spot-multi-az.json) 
* [Mesos Master Role](https://github.com/nubank/iam-policies/blob/master/mesos-master.json) 

Policies for mesos are inside the Mesos [directory](https://github.com/nubank/iam-policies/blob/master/policies/mesos/).

After you make a change, you need to deploy the changes via nucli:
```
nu iam create roles stable mesos-fixed --env cantareira
```

Done, now the iam-role for **mesos-fixed** in the stack **stable** is updated.

## Types of Mesos Slaves

We have several types of mesos slaves, one for each kind of workload. They can be specified when running a job by defining [Constraints](http://aurora.apache.org/documentation/latest/features/constraints/) in the aurora job file, eg: `constraints={'slave-type': 'mesos-fixed'}`.

* **Fixed Instances** - Created by the `MesosFixed` recipe, those instances doesn't scale up and down when we scale the cluster, that's the instance type that you want to use when your job is not fault tolerant. 
* **General On-Demand Instances** - Created by the `MesosOnDemand` recipe, those instances are spin scaling up the `mesos-on-demand` auto-scaling group, every `MesosCluster` has an On Demand autoscaling group.
  * can be scaled up using the following command: `sabesp --verbose --aurora-stack=cantareira-stable jobs create prod scale MODE=on-demand N_NODES=0 SCALE_TIMEOUT=5 --job-version scale_cluster=df8da67`
* **Spot Instances** -  Created by the `MesosMultiAZSpotInstances` recipe, same as the on-demand but spins up spot-instances.
  * can be scaled up using the following command: `sabesp --verbose --aurora-stack=cantareira-stable jobs create prod scale MODE=spot-only N_NODES=0 SCALE_TIMEOUT=5 --job-version scale_cluster=df8da67`
* **Specific On Demand Instances** - Those instances are created using the [scale-cluster](https://github.com/nubank/scale-cluster) `scale-ec2` enstrypoint, this differs from the other slaves by spinning individual ec2 instances (not in auto-scale cluster) so you can specify different attributes for each instance (like: instance type, naming etc.).
  * can be scaled up using the following command: `sabesp --aurora-stack=cantareira-stable jobs create prod downscale-ec2-model SLAVE_TYPE=model NODE_COUNT=1 --job-version="scale_cluster=d749aa4" --filename scale-ec2`

## Upgrading mesos version

- Find the new mesos version, you can use `apt-get update && apt-cache search mesos` inside an ubuntu docker.
- Bump mesos version in mesos-base dockerfile follow [this](https://github.com/nubank/dockerfiles/pull/760/files) example.
- Bump mesos-base dependencies [eg](https://github.com/nubank/dockerfiles/pull/761/files)
- Bump deploy version of mesos-master and slave [eg](https://github.com/nubank/deploy/pull/3277)
- Bump sabesp version of aurora-client [eg](https://github.com/nubank/sabesp/pull/80)
- Bump aurora-jobs versions of aurora-client and sabesp [eg](https://github.com/nubank/aurora-jobs/pull/709)
- Bump all models that depend on `nu-mesos-python` or `nu-mesos-python-spark` (*you can use [source graph](https://sourcegraph.nubank.com.br/search) to find the repositores and `sed` + `hub` to open the PRs*)
- Create a test cluster using deploy's console [see here](#deployment) 
- Run a successfull job in the new cluster (using sabesp + itaipu filtered run)
- Merge all the stuff
- Update cantareira-dev and cantareira-stable clusters (using deploy's console as well)

## Reverting changes of bump (in case of crash)
 - Revert and merge: 
   - `aurora-jobs`
   - `scale-cluster`
   -  deploy
 - Wait their pipelines to run in go run
 - Retrigger `dagao` and `dagao-deploy` to send the changes on the two repos to airflow
 - Update mesos cluster [see here](#deployment)

## Airflow

Airflow is the piece which controls when to execute, what to execute and what's the execution order. All code related to Airflow is a normal python code and is in the [airflow](https://github.com/nubank/aurora-jobs/tree/master/airflow) directory on [aurora-jobs](https://github.com/nubank/aurora-jobs/).

More stuff at [Airflow maintenance](./airflow.md)
