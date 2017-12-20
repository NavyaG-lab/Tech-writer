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

## Airflow

Airflow is the piece which controls when to execute, what to execute and what's the execution order. All code related to Airflow is a normal python code and is in the [airflow](https://github.com/nubank/aurora-jobs/tree/master/airflow) directory on [aurora-jobs](https://github.com/nubank/aurora-jobs/).


### Updating Airflow

To update Airflow you need to first bump it's [Dockerfile](https://github.com/nubank/dockerfiles/blob/master/airflow/Dockerfile), merge it and wait until go has finished building it, then, you need to change the version on [deploy](https://github.com/nubank/deploy/blob/master/lib/recipes/airflow.rb#L21), open the deploy console in the cantareira environment and run:

`Airflow.create!("x")`

Wait until it's created and you can access https://cantareira-x-airflow.nubank.com.br/admin/ and then you can upsert the new airflow to the main DNS.

`Airflow.upsert_alias!("x")`

then you need to delete the old airflow

`Airflow.delete!("x")`

### Running tests for the Airflow DAGs

Running the command below, will spin a environment similiar to the production one, and will run and check all tasks in the `main.py` dag.

```
./script/test integration
```
