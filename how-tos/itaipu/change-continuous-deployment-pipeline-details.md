---
owner: "#data-infra"
---

# How to add a UNIT TEST of a subproject into Itaipu's continuous deployment pipeline

## Introduction

This document has been created based on [previous documentation](./change-continuous-deployment-pipeline.md), to provide more details on how to add a unit test in itaipu.

## Test Creation

It is important to highlight that there is a need of creating TWO files:

* OBJECT Scala (i.e.: `DatasetMetadataValidator.Scala`)
* CLASS Scala  (i.e.: `DatasetMetadataValidatorSpec.Scala`)

### Test Implementation

You can add unit tests in Itaipu in 3 different ways:

1. Create two objects inside the `itaipu/src/it/scala/etl/itaipu`.  

      * The Downside is: the test becomes part of the object that already exists, and therefore becomes a required unit test (non-desirable effect).

1. Implement the unit test inside [TektonCD](https://github.com/nubank/tektoncd), and define a CD pipeline + individual:  

      * [definitions-in-tektdoncd](https://github.com/nubank/tektoncd/pull/337)

      * The good side is - already integrated in `tektoncd pipeline` and is already how things has been done.  

      * The downside is:  

          * Might break something and crash itaipu's run.
          * According to tekton principles,  once a task fails, then all the tests  running on respective itaipu branch will stop. So, even in the case of a non-required unit test, the entire branch could potentially fail.

1. Implement the unit test using [Workflows](https://playbooks.nubank.com.br/cicd/workflows/quickstart/#introduction)  

      * The good side is - already integrated in `tektoncd pipeline` and is already how things has been done.
      * The downside is - If itaipu's build is inexistent, all should be built before one can only use them.

## Detailing the implementation of TektonCD and Workflows

### TektonCD
Edit the following files in the presented order:

* [TektonCD](https://github.com/nubank/tektoncd):
  * If you are creating a test other than a subproject one
    * use this PR as an example [definitions-in-tektoncd](https://github.com/nubank/tektoncd/pull/337)
  * Otherwise
    * Use the Template Created by @Florian, [accordingly to the example](https://github.com/nubank/tektoncd/blob/602d3ded4e4c9b1aaa3af5a55319f3c405271b2b/tekton/live/itaipu/pipelines/itaipu-ci.yaml#L344-L356)
    * Being aware of the SIZE of the machine declared by `itaipu-subproject-tests-{small, medium, large, xlarge}`
    * MAKE SURE that indentation levels are the same as other tests (it is a common mistake!! Trust us!)
  * Open a PR (as usual), but before submitting the template be sure that the      target is the branch `sandbox` (base:sandbox)
  * Request a Team Mate Review and or CICD team review
  * After approval, Squash and Merge them!

* [Itaipu](https://github.com/nubank/itaipu):
  * Adjust [bors-config](https://github.com/nubank/itaipu/blob/master/bors.toml)
  * Open a PR (as usual), but before submitting the template be sure that the target is the branch `sandbox` (base:sandbox)
    * NOTE: here that once you've open a PR everything will look the
      same only AFTER you MERGE this into `sandbox` that will trigger the new pipeline
  * Request a Team Mate Review and or someone in data-infra team review
  * After approval, Squash and Merge them!

It is important for first do the adjustments into Tekton, and merge into sandbox since
both sandbox are running the same specs. And after that you should be able to see your adjustments into
itaipu's pipeline.

### Workflows

* [Itaipu](https://github.com/nubank/itaipu):
  * Create the folders, if non existent:
        *`.nu/`
        * `.nu/workflows/`
  * Create the file as `.nu/workflows/YOURFILE.yaml` (remember to replace `YOURFILE.yaml` name)
    * You should use the [Workflows Quickstart](https://playbooks.nubank.com.br/cicd/workflows/quickstart/#introduction)
    * Important note: The `YOURFILE` should have less than 63 characters or will break:
            ```

            admission webhook "validation.webhook.workflows-system.workflows.dev" denied the request:
                validation failed:
                    not a DNS 1035 label:
                        [must be no more than 63 characters]: metadata.name
            ```
      * DISCLAIMER: if you are only planning on copy and paste from existing files (i.e.: `itaipu-ci.yaml`)
         there are some syntax differences!
        * For example `script -> run` and other minor changes.
  * After creating the file, you should open a PR (in any branch, including master)
    * Then you should be able to see your unit test into a new pipeline that will not affect previous one
  * You may face some errors, and you can reach out to CI/CD team!

Check the following example below, changing `{RANDOM_NUMBER => FOR_SOME_ACTUAL_NUMBER}`:

    ```
      yaml

      apiVersion: workflows.dev/v1alpha1
      kind: Workflow
      metadata:
        namespace: pipelines

      spec:
        branches:
          - "*"
          - "!staging.tmp"
          - "!trying.tmp"
          - "!staging-squash-merge.tmp"
          - "!master"

        events:
          - push

        tasks:
          dataconsumption-build:
            env:
              SBT_OPTS: "-Xms14G -Xmx14G -XX:-UseGCOverheadLimit -Dsbt.io.jdktimestamps=true"
              NU_COUNTRY: "BR"

            resources:
              cpu: 2
              memory: 16Gi

            steps:
              - uses: checkout

              - name: init-aws-credentials
                image: 193814090748.dkr.ecr.us-east-1.amazonaws.com/cicd/aws-credentials
                run: init

              - name: restore-cache
                image: 193814090748.dkr.ecr.us-east-1.amazonaws.com/cicd/cache:latest
                run: |
                  restore-cache \
                    --cache-key-template='itaipu-dataconsumption-test-RANDOM_NUMBER-{% checksum build.sbt %}-{% checksum project/plugins.sbt %}-{% checksum project/build.properties %}-{% checksum .tekton/cache_version %}'
              - name: build
                image: 193814090748.dkr.ecr.us-east-1.amazonaws.com/cicd/scala-builder
                run: sbt compile

              - name: build-test
                image: 193814090748.dkr.ecr.us-east-1.amazonaws.com/cicd/scala-builder
                run: sbt "; project shared-user-utils; compile; test:compile"

              - name: save-cache
                image: 193814090748.dkr.ecr.us-east-1.amazonaws.com/cicd/cache:latest
                run: |
                  #!/bin/bash
                  find . -name target -type d | sed -e "s/^/--folder=/" | \
                    xargs save-cache \
                    --cache-key-template='itaipu-dataconsumption-test-RANDOM_NUMBER-{% checksum build.sbt %}-{% checksum project/plugins.sbt %}-{% checksum project/build.properties %}-{% checksum .tekton/cache_version %}' \
                    --folder=~/.ivy2 --folder=~/.m2 --folder=~/.sbt
          dataconsumption-test:
            requires:
              - dataconsumption-build

            env:
              SBT_OPTS: "-Xms5G -Xmx5G -Dsbt.io.jdktimestamps=true"
              NU_COUNTRY: "BR"

            resources:
              cpu: 2
              memory: 7Gi

            steps:
              - uses: checkout

              - name: init-aws-credentials
                image: 193814090748.dkr.ecr.us-east-1.amazonaws.com/cicd/aws-credentials
                run: init

              - name: restore-cache
                image: 193814090748.dkr.ecr.us-east-1.amazonaws.com/cicd/cache:latest
                run: |
                  restore-cache \
                    --cache-key-template='itaipu-dataconsumption-test-RANDOM_NUMBER-{% checksum build.sbt %}-{% checksum project/plugins.sbt %}-{% checksum project/build.properties %}-{% checksum .tekton/cache_version %}'
              - name: subproject-unit-tests
                image: 193814090748.dkr.ecr.us-east-1.amazonaws.com/cicd/scala-builder
                run: sbt dataconsumption/test
    ```

#### How does it work?

1. Calling the current API `apiVersion: workflows.dev/v1alpha1`, builds a pipeline with 2 tasks:<br>

      i. dataconsumption-build <br>

      ii. dataconsumption-test

1. Each task had to get the aws credentials, so they were set using the step `init-aws-credentials`.
1. One can also notice that each of the tasks had their own resources explicitly declared,
   which is a good practice to be followed.
1. One minor thing to observe is the `CACHE-KEY-TEMPLATE`. We are using a new one in `itaipu-dataconsumption-test-`
   and this is intentional since we want to avoid any conflicts with current run introduced by our pipeline, so always
   create your own template.
1. After creating this document, just open a regular `PR` into any branch and you shall see your test running.
