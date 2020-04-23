# multi-country

## overview

[this slide deck](https://docs.google.com/presentation/d/17c2l00x6rdO9bt2C3ZD2P_Gn2G1so7BXEyFwY_gaky0/edit#slide=id.g7e12e10c74_0_14]) explains a lot of the changes needed to run our data infrastructure on the data aws account.

## mesos
mesos on the data account can be found using the naming scheme:

```
prod-foz-white-mesos-master
prod - env
foz - prototype
white - layer
mesos-master - service name
```

So for example, currently it is at: [https://prod-foz-mesos-master.nubank.world:8080/scheduler/jobs/prod] (note the `layer` isn't required)

## airflow

[Airflow running on the data account](https://airflow.nubank.world/admin/)

### dags

The daily etl run on the data account, which currently includes mexico datasets is called `daguito`.

Other dags also run in the data account, such as the dag that sends progress announcements to slack.
Here is an [example of moving a dag to run on the data account](https://github.com/nubank/aurora-jobs/pull/1125).
