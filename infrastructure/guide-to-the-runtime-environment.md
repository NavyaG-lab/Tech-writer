# Cantareira's Runtime Environment

The runtime relies on [Apache Mesos](mesos.apache.org) for managing the resources, every ec2 instance that we use in the [Nightly Run](https://github.com/nubank/data-infra-docs/blob/master/monitoring_nightly_run.md) register itself as a Mesos Slave, and its resources becomes available in the Mesos's pool of resources. For running jobs [Apache Aurora](https://github.com/nubank/aurora-jobs/blob/master/README.md#whats-aurora) is used, which register as a [Mesos Framework](http://mesos.apache.org/documentation/latest/architecture/) and accept Mesos offers. 

When creating a Aurora Job, you need to specify the resources that this job is going to use, Aurora manages to accept offers from Mesos and run this process on a slave with enough capacity. More on this [Resource Isolation](http://aurora.apache.org/documentation/latest/features/resource-isolation/) [Constraints](http://aurora.apache.org/documentation/latest/features/constraints/).


## Deployment

Creating a `MesosCluster` is done using the [Deploy](https://github.com/nubank/deploy)

## Types of Mesos Slaves

* **Fixed Instances** - Created by the `MesosFixed` recipe, those instances doesn't scale up and down when we scale the cluster, that's the instance type that you want to use when your job is not fault tolerant. 
* **General On Demand Instances** - Created by the `MesosOnDemand` recipe, those instances are spin scaling up the `mesos-on-demand` auto-scaling group, every `MesosCluster` has an On Demand autoscaling group.
* **Spot Instances** -  Created by the `MesosMultiAZSpotInstances` recipe, same as the on-demand but spins up spot-instances.
* **Specific On Demand Instances** - Those instances are created using the [scale-cluster](https://github.com/nubank/scale-cluster) `scale-ec2` enstrypoint, this differs from the other slaves by spinning individual ec2 instances (not in auto-scale cluster) so you can specify different attributes for each instance.







## Dag Level


## Job level

### Creating a new Job

### Submitting a job to the cluster

### Killing a job

### Restarting a Job
