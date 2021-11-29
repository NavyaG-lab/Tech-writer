---
owner: "#data-access"
---

# Known Issues

## `aml_tintin__investigation_actions`

Reported on [this](https://nubank.slack.com/archives/C06F04CH1/p1600982483038800) Slack thread on #data-help.

When trying to commit to the `belomonte_custom_queries` project, users may encounter LookML errors pointing to an unknown view named `aml_tintin__investigation_actions`, located on the `Aml.model`.
That view was created on the `belomonte` project, so the erros are raised when the `belomonte` project is not up to date on the local user branch.

To solve this issue, it is necessary to also pull from production on the `belomonte` project before validating the LookML on the `belomonte_custom_queries` project.
