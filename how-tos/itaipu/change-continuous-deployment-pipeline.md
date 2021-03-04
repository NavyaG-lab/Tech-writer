---
owner: "#data-infra"
---

# How to add/change Itaipu's continuous deployment pipeline

## Introduction

The purpose of creating this document is that the CD for Itaipu is specially
complex and require additional steps, when compared to a conventional Clojure
service at Nubank.
Additionally, with the large amount of contributors and rate of change that
Itaipu undergoes, the impact of a misconfiguration can be significant.

## Context

The following pieces play an important role in Itaipu's continuous deployment pipeline:

- [TektonCD](https://github.com/nubank/tektoncd), for defining the CD pipeline along with the indivual task that
  compose it.
    - [definitions-in-tektoncd]: https://github.com/nubank/tektoncd/pull/337

- GitHub, for defining the branch protection rules that ensure what tasks need
    to run before merging is allowed.
    - [branch-protection-rules]: https://github.com/nubank/itaipu/settings/branch_protection_rules/505139

- Bors, to manage the process of integrating changes in Itaipu.
    - [bors-config]: https://github.com/nubank/itaipu/blob/master/bors.toml 

It's worth noting that TektonCD, is still in early development and undergoing
constant change, so the aspects connected to it might get outdated rapidly.
For example, foundation is working on a tool that will allow pipeline and task
definitions to live in each repository. Once this tool is in place, this process
should become simpler.

## Process

1. Update the [pipeline, task definitions and customize config in TektonCD][definitions-in-tektoncd](https://github.com/nubank/tektoncd/pull/337).
2. Update the status list in [the Bors configuration file][bors-config](https://github.com/nubank/itaipu/blob/master/bors.toml) to include the
   added/changed tasks
3. If any of the added/changed tasks is required, update [the branch protection rules for
   Itaipu][branch-protection-rules](https://github.com/nubank/itaipu/settings/branch_protection_rules/505139 ), in GitHub.

After performing these changes, new PRs on Itaipu should include the new task
defintion and work without problems. In the case of PRs that were already open
and using the previous task definitions, it might be necessary to push a new
commit to refresh the task definitions.

If you still encounter problems, then the new configurations might not have been applied
to Tekton, in which case opening a ticket with #Foundation-Tribe is necessary. Besides, you might need to revert the changes while the problem is
fixed exactly for the reason mentioned earlier. Itaipu is an important work tool
for a lot of people and having it misconfigured can cause significant impact. So, be mindful of your changes to the PRs.

In order to mitigate the above stated issues, it is recommended that these changes are applied
during Berlin's morning time, when the impact for users would be minimal.
