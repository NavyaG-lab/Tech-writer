---
owner: "#data-infra"
---

# Itaipu CI

## Overview

The integration between Github and Tekton was made through webhooks. 
How does it work? In each push event, Github sends an HTTP post payload to the Tekton webhook's URL. It will create a pipelinerun that starts the tasks defined on it.

As soon as the tasks start, they will be updated in the Checks tab on the Pull Request page. At the moment, inside Github page we can access this in three different ways:

- on each check on the Pull Request page, by clicking in `Details` link:

![PR page](images/pr_page.png)

- in the popup on the `Commits` tab:

![Commits page](images/commits_page.png)

- and also in the `Checks` tab:

![Checks page](images/checks_page.png)

On the Checks page (image above), we can navigate through the tasks and visualize the details for each one of them. The task's details contain the steps, params, and the configuration defined for it at the moment of the execution.

## How to check the logs?

Logs are available for each step of each task. To access them, click on the link in step name, and it will redirect to the Splunk page with the query related to this specific step.

For example, to read the logs from a step that failed:

1. On the Pull Request page, click in `Details` link:

![Check failed](images/check_failed1.png)

2. On the `Checks` tab, there is a summary and a table that are indicating whether something goes wrong. To investigate that in the logs, click on the step name link, as it is highlighted in the image, to access the Splunk page.

![Step failed](images/check_failed2.png)

3. On Splunk, the logs showed belongs to the step selected. There advantage here is that all the features from Splunk can be accessed, such as the pagination bar, the format menu:

![Splunk page](images/check_failed3.png)

## Pipeline and task structure

Each commit made in the Itaipu's repository will be verified by the tasks that were set in the [itaipu-ci.yaml](https://github.com/nubank/tektoncd/blob/master/tekton/pipelines/itaipu-ci.yaml) file.

The tasks are defined in `yaml` files, they are located in [tektoncd's repository](https://github.com/nubank/tektoncd/tree/master/tekton/tasks/itaipu). Some tasks are dependents on others. And when the main task failed it will not start the dependent one.
To know more about the structure and its details, access [Itaipu CI documentation](https://github.com/nubank/tektoncd/blob/master/docs/pipelines/itaipu-ci.md).

## I need more information

If you still have questions or need additional information, please reach out to #data-help and you will have the appropriate support provided.
