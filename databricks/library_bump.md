# Bumping and adding Nubank's Java/Scala libraries in Databricks

The most common use case is to bump [itaipu](https://github.com/nubank/itaipu).

Adding or bumping the version of the library that's running on Databricks
involves these steps:

1. Get a packaged JAR of the library
1. Install the library into Databricks
1. Delete or detach the previous version
1. Restart the cluster(s) (optional)
1. For relevant lib bumps, test that things still work.

## Getting a JAR

### Itaipu

#### Via CircleCI

One way to get a JAR is through Circle CI. Circle CI packages
[itaipu](https://circleci.com/gh/nubank/itaipu/tree/master) during every build that successfully ran
its tests.

1. Generally you want to grab the JAR from the last successful master build, which you can find
here: https://circleci.com/gh/nubank/itaipu/tree/master
1. Click on `build_test_package` (in the column on the right side) of the most recent build; or
click on the build number, then on `build_test_package` under "Workflow" (in the top of the page).
1. Click on the `package` step in the workflow (it should be green). You
will see something like this: ![](../images/circleci_workflow.png)
1. Download the JAR by going to the `Artifacts` tab: ![](../images/circleci_artifacts.png)

#### Via sbt

The alternative is to create the file locally (example below with `itaipu`, but
works with any Scala project):

```bash
cd $NU_HOME/itaipu
git checkout master
git pull origin master
sbt clean
sbt package
mv target/scala-2.11/itaipu_2.11-1.0.0-SNAPSHOT.jar target/scala-2.11/itaipu_2.11-1.0.0-SNAPSHOT-$(date +'%Y%m%d')-$(git rev-parse --short=7 HEAD).jar
```
Explanation:
- `sbt clean` removes all generated files from the `target` directory.
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

### common-etl library

#### Via S3

Assuming it's being compiled against the `2.11` scala version, replace `VERSION` with what's in the `build.sbt` in the root of the `common-etl` repo, to download the jar in a folder (using `~/Downloads` as an example):



```
aws s3 cp s3://nu-maven/releases/common-etl/common-etl_2.11/VERSION/common-etl_2.11-VERSION.jar ~/Downloads
```

Another way to check what is the exact location of the jar is by looking at the log output in the `common-etl-release` pipeline in GoCD: https://go.nubank.com.br/go/tab/pipeline/history/common-etl-release

- Click the Info icon for details of the pipeline run

![Pipeline details page](https://user-images.githubusercontent.com/1674699/53018459-b3cc8b00-3452-11e9-9e2c-45c08123bdd8.png)

- Click on the release under the Passed section of the JOBS sidebar
![release job page](https://user-images.githubusercontent.com/1674699/53018389-854eb000-3452-11e9-8964-930a3884105f.png)

- Check the log output for the location of the file on S3:

![Log output](https://user-images.githubusercontent.com/1674699/53018372-7b2cb180-3452-11e9-91ac-34bf0d80622c.png)

- Download the file using the location you found and the `aws s3` command above, and proceed to the steps below.

## Install into Databricks

1. Go to [Databricks](https://nubank.cloud.databricks.com/) --> `Workspace` --> `Libraries` -->
navigate to the [appropriate folder](libraries.md) --> `Create` (in the dropdown in the top)
--> `Library`: ![](../images/databricks_libraries.png)
1. Don't enter a name for the new library yet, but drag the JAR file into the page instead. The
filename will appear automatically after uploading. If it doesn't have a unique name (e.g., with a
timestamp as a suffix), edit it to avoid a naming conflict (e.g., `itaipu_2.11-1.0.0-SNAPSHOT-20180515.jar`).
1. Click on `Create Library` and check `Attach automatically to all clusters` or choose the cluster(s)
    1. Be careful when attaching to all clusters a custom library or a custom version of itaipu,
because you may affect other people's work
1. If any dependency versions have been changed, you must upload those new versions.
For instance, if you bump `circe` in `common-etl` ([for example](https://github.com/nubank/common-etl/pull/195/files#diff-fdc3abdfd754eeb24090dbd90aeec2ceR36)), then you must upload the new versions of `circe`.
1. Confirm that common operations work after adding the new libraries and restarting the cluster. Running something like `metapodClient.getTransaction` ([see here](https://nubank.cloud.databricks.com/#notebook/422548/command/422549)) will test this.

## Delete or detach the previous version

1. Go to [Databricks](https://nubank.cloud.databricks.com/) --> `Workspace` --> `Libraries`
1. Click on the previous library version, and uncheck from the cluster(s) that you want to remove
1. To delete the file: `Workspace` --> `Libraries` --> right-click on the filename or click on the
dropdown menu next to the filename --> `Move to Trash`
    1. To keep the old version, you can `Move` the file to the [appropriate folder](libraries.md).

## Restart cluster(s)

It is possible to attach a new version and detach an old version of a library, but you may see the
message `Detach pending a cluster restart` (or something similar) in the libraries page of the
cluster (`https://nubank.cloud.databricks.com/#/setting/clusters/<cluster-id>/libraries`).

Go to the [`Clusters` page in Databricks](https://nubank.cloud.databricks.com/#setting/clusters)
and restart the clusters that have some kind of warning or error message in libraries page.
