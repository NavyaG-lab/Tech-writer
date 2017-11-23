# Cantareira's Runtime Environment

The runtime relies on [Apache Mesos](mesos.apache.org) for managing the resources, every ec2 instance that we use in the [Nightly Run](https://github.com/nubank/data-infra-docs/blob/master/monitoring_nightly_run.md) register itself as a Mesos Slave, and its resources becomes available in the Mesos's pool of resources. For running jobs [Apache Aurora](https://github.com/nubank/aurora-jobs/blob/master/README.md#whats-aurora) is used, which register as a [Mesos Framework](http://mesos.apache.org/documentation/latest/architecture/) and accept Mesos offers. 

When creating a Aurora Job, you need to specify the resources that this job is going to use, Aurora manages to accept offers from Mesos and run this process on a slave with enough capacity. More on this [Resource Isolation](http://aurora.apache.org/documentation/latest/features/resource-isolation/) and [Constraints](http://aurora.apache.org/documentation/latest/features/constraints/).


## Deployment

Creating a `MesosCluster` is done using the [Deploy](https://github.com/nubank/deploy), follow the guide in the project's README to install it. 

1. Start the console using the cantareira environment `./console cantareira`
2. To create/update the cluster just type: `MesosCluster.create!("test")`.
3. To update individual Slaves you can type: `MesosFixed.create!("test")`, `MesosOnDemand.create!("test")`

## Updating Mesos IAM Roles

IAM roles are stored in a separate project [iam-policies](https://github.com/nubank/iam-policies), to update them you need to change the file that corresponds the slave you want to change (or change all of them) files are:
* [Mesos Fixed Role](https://github.com/nubank/iam-policies/blob/master/mesos-fixed.json) 
* [Mesos On-Demand Role](https://github.com/nubank/iam-policies/blob/master/mesos-on-demand.json) 
* [Mesos Spot Multi Az Role](https://github.com/nubank/iam-policies/blob/master/mesos-spot-multi-az.json) 
* [Mesos Master Role](https://github.com/nubank/iam-policies/blob/master/mesos-master.json) 

Policies for mesos are inside the mesos [directory](https://github.com/nubank/iam-policies/blob/master/policies/mesos/).

After you make a change, you need to deploy the changes, to do that you need to call a manual command on deploy (that's because mesos is a service apart from the common services, and no one automated it's deploy), to do that do:
```
[1] CANTAREIRA> stack = Stack.new(env: "cantareira", service: "mesos-fixed", prototype: nil, id: "stable")

[1] CANTAREIRA> Roles.upsert_roles!(stack, false) 
```

Done, now the iam-role for **mesos-fixed** in the stack **stable** is updated.

## Types of Mesos Slaves

We have severeal types of mesos slaves, one for each kind of workload. They're can be specified when running a job by defining [Constraints](http://aurora.apache.org/documentation/latest/features/constraints/) in the aurora job file, eg: `constraints={'slave-type': 'mesos-fixed'}`.

* **Fixed Instances** - Created by the `MesosFixed` recipe, those instances doesn't scale up and down when we scale the cluster, that's the instance type that you want to use when your job is not fault tolerant. 
* **General On Demand Instances** - Created by the `MesosOnDemand` recipe, those instances are spin scaling up the `mesos-on-demand` auto-scaling group, every `MesosCluster` has an On Demand autoscaling group.
  * can be scaled up using the following command: `sabesp --verbose --aurora-stack=cantareira-stable jobs create prod scale MODE=on-demand N_NODES=0 SCALE_TIMEOUT=5 --job-version scale_cluster=df8da67`
* **Spot Instances** -  Created by the `MesosMultiAZSpotInstances` recipe, same as the on-demand but spins up spot-instances.
  * can be scaled up using the following command: `sabesp --verbose --aurora-stack=cantareira-stable jobs create prod scale MODE=spot-only N_NODES=0 SCALE_TIMEOUT=5 --job-version scale_cluster=df8da67`
* **Specific On Demand Instances** - Those instances are created using the [scale-cluster](https://github.com/nubank/scale-cluster) `scale-ec2` enstrypoint, this differs from the other slaves by spinning individual ec2 instances (not in auto-scale cluster) so you can specify different attributes for each instance (like: instance type, naming etc.).
  * can be scaled up using the following command: `sabesp --aurora-stack=cantareira-stable jobs create prod downscale-ec2-model SLAVE_TYPE=model NODE_COUNT=1 --job-version="scale_cluster=d749aa4" --filename scale-ec2`

## Job level

### Creating a new Job

### Submitting a job to the cluster

### Killing a job

### Restarting a Job


## Dag Level

### Adding a new Job to the DAG

### Running the DAG locally
