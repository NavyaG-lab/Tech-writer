# multi-country

## Overview

[this slide deck](https://docs.google.com/presentation/d/17c2l00x6rdO9bt2C3ZD2P_Gn2G1so7BXEyFwY_gaky0/edit#slide=id.g7e12e10c74_0_14]) explains a lot of the changes needed to run our data infrastructure on the data aws account.

**Please note that mesos-master and aurora-scheduler are already isolated on the Data account, and have distinct DNS addresses.** This means that we no longer need to specify the port in their URLs (see the corresponding sections below).
In Brazil, even though they are already running in isolated instances too, for the time being the port still needs to be specified.

In order to set up access to the multiple countries, follow [these instructions][multi-country-setup].


## Aurora

Aurora (aurora-scheduler) provides access to the Aurora Scheduler UI.

`aurora-scheduler` on the Data account is currently available at [https://prod-foz-aurora-scheduler.nubank.world/](https://prod-aurora-scheduler.nubank.world/)

## Mesos
Mesos (mesos-master) provides access to the Mesos UI, and allows you to see lower level details of the jobs. It is usually recommended to interface directly with Aurora whenever possible.

`mesos-master` on the Data account is currently available at [https://prod-foz-mesos-master.nubank.world/](https://prod-foz-mesos-master.nubank.world/)

## Airflow

Airflow on the Data account is available at [https://airflow.nubank.world/admin/](https://airflow.nubank.world/admin/)

### DAGs

The daily etl run on the data account, which currently includes mexico datasets is called `daguito`.

Other dags also run in the data account, such as the dag that sends progress announcements to slack.
Here is an [example of moving a dag to run on the data account](https://github.com/nubank/aurora-jobs/pull/1125).

[multi-country-setup]: ./multi_country_setup.md
