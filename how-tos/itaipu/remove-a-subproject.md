---
owner: "#data-infra"
---

# Steps to remove a subproject

Removing a subproject involves different steps depending on what kind of
project it is. In some cases, you need to merge a series of PRs in the correct
order to ensure the tests do not break.

Removing a subproject we assume that you have removed all code dependencies,
imports and other references already, so the project can really be removed
without breaking other projects.

## Project from `contrib` or `platform`

1. itaipu PR: remove the task from the `bors.toml` file -> tests aren't run in
   bors anymore.

2. tektoncd PR: remove the test task from [itaipu-ci](https://github.com/nubank/tektoncd/blob/master/tekton/live/itaipu/pipelines/itaipu-ci.yaml) -> tests aren't run in CICD anymore.

3. itaipu PR: remove the project files and folders. Remove the project from the
   `build.sbt`. Remove the project definition as well as all `dependsOn`
   statements that reference it. **Careful**: If your project was bringing in
   other dependencies as transitive dependencies to itaipu, you might need to
   add these to itaipu directly. Example: `itaipu` depended on `reconciliation`
   but not on `heterogeneous-fixture` directly. When removing `reconciliation`,
   we had to add `heterogeneous-fixture` to `itaipu`'s `dependsOn` for it to
   still be available in itaipu.

## Project from `user-defined-datasets`

This can all be done within a single PR:

* Remove from the `bors.toml` file.
* Remove the files and folders
* Remove the project from the `build.sbt`:
    * Remove the declaration of the project
    * Remove it from itaipu's `dependsOn`
    * Remove it from a `subproject-aggregator` project's `aggregates`
        statement.

Nothing to do in `tektoncd`?

No. Tektoncd runs the subproject tests by running a subproject-aggregator task.
That will run all the tests for the subprojects it aggregates. Since you don't
remove the aggregator itself, tektoncd need not be touched.
