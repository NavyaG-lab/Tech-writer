# Libraries

https://nubank.cloud.databricks.com/ --> `Workspace` --> `Libraries`

Folder organization:

- Java/Scala JAR files attached to most of the clusters
- `00_ad-hoc`: Java/Scala JAR files attached to a few clusters or used for tests
- `00_python`: Python libraries attached to most of the clusters
    - `00_ad-hoc`: Python libraries attached to a few clusters or used for tests
- `00_unused`: Java/Scala JAR files not attached to any cluster
    - `00_Nubank-lib`: Nubank libraries
        - `common-etl`: common-etl JAR files
        - `itaipu`: itaipu JAR files
        - ...
    - `00_python`: Python libraries


Obs.: Using the prefix `00_` to make the folders appear in the beginning of the list.
