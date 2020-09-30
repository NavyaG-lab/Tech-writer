# Overloaded Cluster

## When is the cluster overloaded?

There are several reasons for the cluster to stop working. To ensure that it’s particularly due to an overload of spark jobs, ensure these two conditions are met:
1. **The cluster is fully upscaled** - First find the max number of machines set in the cluster details page, and then go to the Cluster’s event logs tab and you should notice that there is a UPSIZE_COMPLETED event with the max number of workers set on the cluster. Make sure there is no message like “Failed to acquire nodes”.
2. **There is an over-utilisation of resources** - Now go to the Ganglia UI or in case if this can’t be opened (because of a severed connection with the driver), go to the last historical metrics snapshot and check the graph CPU and Memory charts. If you notice the red line in the CPU chart is crossed or the memory is fully utilised, this confirms the cluster is overloaded.

## How to recover the cluster from this situation?

The fast and easy way is to restart the cluster but that will cause all executions to stop and all notebooks to get detached from the cluster. But to cause minimum impact, find the jobs that are most affected by the overload and kill.

To do this, go to the **Cluster -> SparkUI -> Job -> Active Jobs (tab)** and under the Tasks column in Active Jobs you’d notice that spark jobs are failing with the error : `(136 killed: preempted by scheduler)` like in the following image:

![preemption-ui](../images/spark-ui-debug.png)

A spark job consists of tasks. If a few tasks in the spark job continuously fail, these jobs can take a very long time to recover, and in an overloaded cluster, they will take forever.

You should also make sure these spark jobs have been running for a long time so as to kill only those jobs that are affected the most.
Go ahead and kill the jobs by clicking the “Kill” button next to the code of the command next to the description column.
Give this a few minutes and the cluster should recover back to normal.
