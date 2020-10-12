---
owner: "#data-infra"
---

# Databricks API

To interact with [Databricks REST API 2.0](https://docs.databricks.com/api/latest/index.html) use [Databricks Command Line Interface (CLI)](https://github.com/databricks/databricks-cli). The README contains installation instructions and how to set up authentication

Example of available commands:

```
$ databricks
Usage: databricks [OPTIONS] COMMAND [ARGS]...

Options:
  -v, --version   0.8.1
  --debug         Debug Mode. Shows full stack trace on error.
  --profile TEXT  CLI connection profile to use. The default profile is
                  "DEFAULT".
  -h, --help      Show this message and exit.

Commands:
  clusters   Utility to interact with Databricks clusters.
  configure  Configures host and authentication info for the CLI.
  fs         Utility to interact with DBFS.
  groups     Utility to interact with Databricks groups.
  jobs       Utility to interact with jobs.
  libraries  Utility to interact with libraries.
  runs       Utility to interact with the jobs runs.
  secrets    Utility to interact with Databricks secret API.
  stack      Utility to deploy and download Databricks resource stacks.
  workspace  Utility to interact with the Databricks workspace.
```
