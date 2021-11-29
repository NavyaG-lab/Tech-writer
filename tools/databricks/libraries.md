---
owner: "#data-infra"
---

# Libraries

<https://nubank.cloud.databricks.com/> --> `Workspace` --> `Libraries`

Folder organization:

1. Java/Scala JAR files attached to most of the clusters
1. `00_adhoc`: Java/Scala JAR files attached to a few clusters or used for tests
1. `00_nubank`: Nubank Java/Scala libraries
1. `00_python`: Python libraries attached to most of the clusters
    1. `00_adhoc`: Python libraries attached to a few clusters or used for tests
    1. `00_nubank`: Nubank Python libraries
1. `00_unused`: Java/Scala JAR or Python files not attached to any cluster
    1. `00_nubank`: unused Nubank Java/Scala libraries
        1. `common-etl`: common-etl JAR files
        1. `itaipu`: itaipu JAR files
        1. `metapod-client`: metapod-client files
        1. ...
    1. `00_python`: unused Python libraries
        1. `00_nubank`: unused Nubank Python libraries

Obs.: Using the prefix `00_` to make the folders appear in the beginning of the list.
