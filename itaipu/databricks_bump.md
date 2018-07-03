numpy, pandas, plotly, scikit-learn, scipy


# Bumping Itaipu on Databricks

Bumping the version of Itaipu that's running on Databricks involves these
steps:

1. Get a packaged JAR of Itaipu
1. Install the library into Databricks
1. Delete or detach the previous version
1. Restart the cluster(s)

## Getting a JAR

### Via CircleCI

One way to get a JAR is through Circle CI. Circle CI packages Itaipu
during every build that successfuly ran its tests.

1. Generally you want to grab the JAR from the last successful master build,
which you can find here: https://circleci.com/gh/nubank/itaipu/tree/master.
Click on `build_test_package` of the most recent one; or click on the build number,
then on `build_test_package` under "Workflow".
1. Click on the `package` step in the workflow (it should be green). You
will see something like this: ![](../images/circleci_workflow.png)
1. Download the JAR by going to the `Artifacts` tab: ![](../images/circleci_artifacts.png)
1. Rename it from `itaipu_2.11-1.0.0-SNAPSHOT.jar` to `itaipu_2.11-1.0.0-SNAPSHOT-<YYYYMMDD>-<GITSHA>.jar`, where `<YYYYMMDD>` is the current date, and `GITSHA` are the first 7 characters of the git commit SHA (in the case shown in the figure, `103f895`).

### Via sbt

The alternative is to create the file locally:
```bash
$ cd itaipu/
$ git checkout master
$ git pull origin master
$ sbt clean
$ sbt package
$ mv target/scala-2.11/itaipu_2.11-1.0.0-SNAPSHOT.jar target/scala-2.11/itaipu_2.11-1.0.0-SNAPSHOT-$(date +'%Y%m%d')-$(git rev-parse --short=7 HEAD).jar
```
Explanation:
- `sbt clean` removes all generated files from the target directory.
- `sbt package` creates a JAR file containing the files in `src/main/scala`,
`src/main/java`, and resources in `src/main/resources`.
- The last part adds the current date and git commit SHA to the filename. The name comes from variables
`name`, `version` and `scalaVersion`
in [build.sbt](https://github.com/nubank/itaipu/blob/28a63912d5d49b382bd0dcae41eccb4db7b4bb37/build.sbt#L1).
If it is different, you need to change it accordingly.
- Don't use `sbt assembly` (instead of `sbt package`), which uses the
[sbt-assembly plugin](https://github.com/sbt/sbt-assembly), because it will create
the file `target/scala-2.11/etl-runner.jar` (as defined in
[build.sbt](https://github.com/nubank/itaipu/blob/28a63912d5d49b382bd0dcae41eccb4db7b4bb37/build.sbt#L8)).
This file is a fat JAR (aka uber JAR) of your project with all of its dependencies.
Databricks already contains these dependencies in separate JAR files.

## Install into Databricks

1. Go directly to [Databricks](https://nubank.cloud.databricks.com/#create/library/499); or
--> `Workspace` --> `Libraries` --> `Create` (in the dropdown in the top)
--> `Library`: ![](../images/databricks_libraries.png)
1. Don't enter a name for the new library yet, but drag the JAR into the page
instead. The filename will appear automatically after uploading. If it doesn't
have a unique name (e.g., with a timestamp as a suffix), edit it to avoid a
naming conflict (e.g., `itaipu_2.11-1.0.0-SNAPSHOT-20180515.jar`).
1. Click on `Create Library` and check `Attach automatically to all clusters`
(note: sometimes when people run custom Itaipus this could be undesirable; 
so this requirement is debatable).

## Delete or detach the previous version

1. Go to [Databricks](https://nubank.cloud.databricks.com/)
--> `Workspace` --> `Libraries`
1. Click on the previous itaipu version, and uncheck from the cluster(s)
that you want to remove
1. To delete the JAR file: `Workspace` --> `Libraries` --> click on the
dropdown menu next to the filename --> `Delete`

## Restart cluster(s)

Go to the [`Clusters` page in Databricks](https://nubank.cloud.databricks.com/#setting/clusters)
and restart the clusters that need access to the new Itaipu.
