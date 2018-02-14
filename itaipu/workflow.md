# Contributing to Itaipu (workflow)

## Contracts Workflow

### Creating a New Contract

Creating a new contract is different than updating an existing contract because you'll need to create some new files.

1. On the relevant Clojure service:
    1. Create or edit the following files (there is an example [here](https://github.com/nubank/forex/pull/93)):
        - `contract/contract_main.clj`:
            1. Create it if it doesn't exist, with the correct content
        - `project.clj`:
            1. Add `:contract` to the `:profiles`, and `"gen-contracts"` to the `:aliases`
            1. Ensure the project is using the latest version of
            [`common-datomic`](https://github.com/nubank/common-datomic/blob/master/project.clj).
        - `src/[SERVICE-NAME]/db/datomic/config.clj`:
            1. Add the `contract-skeletons` to the `schemata`
        - `src/[SERVICE-NAME]/models/*.clj`:
            1. Annotate the relevant Datomic models with contract attributes as appropriate, similar to
            [this](https://github.com/nubank/forex/pull/93))
            1. Ensure every attribute in the `skeleton` has an example (`:eg`) and documentation (`:doc`)
            1. Potentially add:
                - a `:contract/name` if you want to alias the attribute for ETL purposes
                - `:contract/include false` if you want to remove the attribute from the ETL
                - `:contract/history true` if you want to include the historical values of that attribute (a separate
                table with columns `audit__cid`, `audit__tags`, `audit__user`, `audit__version`, `db__tx_instant`)
        - `test/[SERVICE-NAME]/db/datomic/config_test.clj`:
            1. Add a call to function `common-datomic.contract.test-helpers/enforce-contracts!`
    1. Run `$ lein gen-contracts` to generate the initial contracts in `resources/contract/[DB-NAME]/`. Give the data
    infra squad a heads up that you are working on it, and then answer `Y` to the command line prompt.
    1. Open a pull request similar to [this one](https://github.com/nubank/forex/pull/93).

1. Make sure that the database exists in prod before adding the contract to Itaipu.

1. On Itaipu create a Scala object for the database:
    1. If this is the first contract for this database, create a new package (aka folder) under
    [itaipu/src/main/scala/etl/contract](https://github.com/nubank/itaipu/tree/master/src/main/scala/etl/contract) named
    after the new database. If the relevant folder already exists, proceed to the next step.
    1. Create a Scala object for the database (using PascalCase, aka upper camel case) that will reference each of the
    contract entities - similar to
    https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/contract/proximo/Proximo.scala.
    1. Only if the database is not sharded (that is, it is mapped to global), add the `prototypes` attribute:
    `override val prototypes: Seq[Prototype] = Seq(Prototype.Global)`. Otherwise, leave only the attributes `name` and
    `entities`,

1. Create a new Scala object for each new contract entity you are adding.
    1. The code should be a direct copy paste from contract Scala file(s) generated in the Clojure project (generated
    using `$ lein gen-contracts` and found in `resources/contract/[DB-NAME]/*.scala`) into folder
    `itaipu/src/main/scala/etl/contract/[DB-NAME]`.
    1. Ensure all objects are referenced by the `entities` val in the database object (mentioned in the previous step).

1. If this is the first contract for this database, add a reference to the database object to
[`allDatabases` in `contract/package.scala`](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/contract/package.scala)

1. Follow the instructions about [running tests](#running-tests)

1. Open a pull request on Itaipu and ask someone from data infra to review it alongside the PR on the Clojure service.

1. Follow the instructions about [merging pull requests](#merging-pull-requests)

### Updating an Existing Contract

A Clojure service that already has generated contract Scala files will store them in `/resources/[DB-NAME]/*.scala`.
When running unit tests on a service with generated contracts, any change to an attribute that is included in a contract
(or any addition of an attribute without `:contract/include false`) will cause the generated Scala file to no longer
match.

If you want to add, change or remove an attribute:

1. On the relevant Clojure service:
    1. Make the change you are proposing
    1. Make sure the Datomic model(s) has:
        - an example (`:eg`) and documentation (`:doc`)
        - potentially a `:contract/name` (if you want to alias it for ETL purposes), `:contract/include false` (to
        remove that attribute, because the default is to include them all) and `:contract/history true` (if you want to
        include the historical values of that attribute in a separate table with columns `audit__cid`, `audit__tags`,
        `audit__user`, `audit__version`, `db__tx_instant`)
    1. Run `$ lein gen-contracts`
1. Paste the updated Scala files into a branch of Itaipu
1. Open pull requests for each and ask someone from data infra squad to review
1. [Merge and profit](#merging-pull-requests)


## Datasets, Dimensions, and Fact Tables Workflow

Creating datasets:
- [See quotes from Kimball on designing dimensional models here](dimensional_modeling/kimball.md)

### Bus matrix

Find the bus matrix WIP here (for the time being—until we find a better place):
https://docs.google.com/spreadsheets/d/1K5IqTTT2L56QVRve-Q8eSl7IfQipBQb1u7hTELP4m3Q/edit#gid=0

### Databricks Approach

There are some tips and useful commands, including templates to create datasets and tests, here:
https://wiki.nubank.com.br/index.php/Databricks_Notebook.

From within a Databricks notebook, it is possible to:

1. List the available tables. For now, Euclides is manually running a job to refresh this list after each successful
daily ETL run (of DAGão). In the future, this would become an automated part of a successful ETL run.

    The relevant commands are:
    ```sql
    %sql show tables in contract
    %sql show tables in dataset
    %sql show tables in raw
    ```

    Example output:
    ```
    database | tableName            | isTemporary
    ---------|----------------------|--------------
    contract | customers__customers | FALSE
    ```

1. Access the tables listed:
    
    ```scala
    val customers = spark.table("contract.customers__customers")
    ```
    
    ```sql
    %sql select * from contract.customers__customers
    ```
    
    ```scala
    val customers = spark.sql("select * from contract.customers__customers")
    ```

1. Create and edit datasets. You can use an IDE (such as IntelliJ) or text editor to write code, then copy it to the
Databricks notebook to inspect the output. This workflow provides a faster iterative process. It will be best explained
below.

### Creating a new dataset

1. If the folder or subfolder which will contain the dataset doesn't exist in
[itaipu/src/main/scala/etl/dataset/](https://github.com/nubank/itaipu/tree/master/src/main/scala/etl/dataset):
    1. Create the (sub)folder, e.g., `folder_name`
    1. Create a package file called `package.scala` inside the new (sub)folder with the following content (assuming that
    the file that you will create in the next step is called `FileName.scala`):
        ```scala
        package etl.dataset.parent_folder_name_if_subfolder
        
        import common_etl.operator.SparkOp
        import etl.itaipu.avroizeWithSchemaFunctor
        
        package object folder_name {
          
          // only if the new class receives inputs, e.g., `referenceDate` (String), `targetDate` (String),
          // `referenceLocalDate` (LocalDate), `targetLocalDate` (LocalDate)
          def allOps(referenceDate: String): Seq[SparkOp] = {
            val fileNameOp = FileName(referenceDate)
            Seq(fileNameOp, avroizeWithSchemaFunctor(fileNameOp))
          }
   
          // only if the new class doesn't receive inputs: 
          def allOps: Seq[SparkOp] = {
            Seq(FileName, avroizeWithSchemaFunctor(FileName))
          }
          
          // only if there are subfolders (assuming it receives `referenceDate` as input):
          def allOps(referenceDate: String): Seq[SparkOp] =
            subfolder1.allOps(referenceDate) ++
            subfolder2.allOps ++
            subfolder3.allOps(referenceDate)   
        }
        ```
    1. Add `folder_name.allOps` to `opsToRun` in
    [itaipu/src/main/scala/etl/itaipu/Itaipu.scala](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/itaipu/Itaipu.scala)
1. Create the dataset file in the same folder as the package file
    - The filename must be in PascalCase format (e.g., `FileName.scala`) and must be the same as the object name
1. Create the dataset object:
    - To create a dataset basically you need to create a SparkOp, which has mainly 3 methods:
        - `name`: the dataset name (e.g. `dataset/settled-transactions`)
        - `inputs`: a set of inputs (typically table names)
        - `definition`: turns one or multiple inputs (i.e. Spark DataFrames) into an output (i.e. Spark DataFrame)
    - Write the code for the new dataset following the code from existing datasets or use the template shown here:
    https://wiki.nubank.com.br/index.php/Scala
1. Add the object to the output of `allOps` in the `package.scala` file
    - It's possible to [make the dataset available in Redshift](#make-the-dataset-available-in-redshift)
1. Follow the instructions about [editing datasets](#editing-an-existing-dataset)

### Editing an existing dataset
For a faster iterative process, run the code from Itaipu directly in the Databricks notebook:
1. Paste the raw Itaipu Scala code into a cell in the Databricks notebook
    - **Important:** Remove the package name from the top of the file
1. Manually set up the `df` value. For example, assuming your object name is `Whatever`:
    ```scala
    
    // Option 1:
    val df = Whatever.definition(Map(
      "contract-customers/customers" -> spark.table("contract.customers__customers"),
      "contract-acquisition/account-requests" -> spark.table("contract.acquisition__account_requests")))
    
    import etl.databricks.DatabricksHelpers.{translateName, opToDataFrame}
    
    // Option 2:
    val df = Whatever.definition(Map(
      "contract-customers/customers" -> spark.table(translateName("contract-customers/customers")),
      "contract-acquisition/account-requests" -> spark.table(translateName("contract-acquisition/account-requests"))))
    
    // Option 3:
    val df = opToDataFrame(spark, Whatever)
    ```
    If the class receives an input value, such as `refereceDate`, replace `Whatever` with `Whatever(referenceDate)`.
    
    A more complete example: https://nubank.cloud.databricks.com/#notebook/47345
1. Inspect if the values in `df` are correct. If you want to change something, edit the code in the IDE (it's better to
edit in an IDE because of type checking, autocompletion, etc.), then go back to step 1.
1. Unit tests:
    1. The functions that you created in the dataset need to have unit tests in
    [itaipu/src/test/scala/etl/dataset](https://github.com/nubank/itaipu/tree/master/src/test/scala/etl/dataset). If the
    corresponding folder for your dataset doesn't exist, create it with the same name and subfolder structure as in
    [itaipu/src/main/scala/etl/dataset/](https://github.com/nubank/itaipu/tree/master/src/main/scala/etl/dataset).
    1. The filename must be the same as the object name plus `Spec`, e.g., `WhateverSpec.scala`
    1. Write the code for the test file following the code from existing tests or use the template shown here:
    https://wiki.nubank.com.br/index.php/Scala.
1. *(Optional)* Check the null values:
    ```scala
    import etl.databricks.DatabricksHelpers.validateNotNull
    validateNotNull(Whatever, df)
    ```
1. *(Optional)* Save the data to query with SQL:
    ```scala
    runOpAndSaveToTable(spark, Whatever, "choose_a_schema_name", "choose_a_table_name")
    val df = spark.sql("SELECT * FROM choose_a_schema_name.choose_a_table_name")
    ```
1. Follow the instructions about [running tests](#running-tests)
1. Open a pull request on Itaipu and ask someone from data infra to review it
1. Follow the instructions about [merging pull requests](#merging-pull-requests)

### Make the dataset available in Redshift

If you want to make the dataset available in Redshift, you need to create Avro files from it:
1. In the package file `package.scala`, add a call to `avroizeWithSchemaFunctor` in the output of `allOps`


## Running tests

Run the unit and integration tests for Itaipu and ensure both pass. Before running the tests, make sure you are inside the `itaipu` folder in the terminal.

Tips:
- If the tests fail, it is useful to display the expected value and the function result inside the test. For example, if
you write `result.show()` or `println(result)`, sbt will display the values for your inspection.
- Prefacing a command with a tilde (`~`) will make it run again every time the source files change.


Running the tests:
1. Unit tests (repeat the commands if you have max open file errors).
    1. Run all tests: `$ sbt test` or
        ```shell
        $ sbt
        > test
        ```
    1. Use [testOnly](http://www.scala-sbt.org/0.13/docs/Testing.html#testOnly) to run unit tests for a specific test
    file (passing the filename), and watch for updates in that file (using the tilde):
        ```shell
        $ sbt
        > ~test-only etl.dataset.folder_name.FileNameSpec
        ```
    1. Use [testQuick](http://www.scala-sbt.org/0.13/docs/Testing.html#testQuick) to run:
        - specific tests
        - only the tests that failed in the previous run
        - tests that were not run before
        - tests that have been affected by changes in the source code
    
        `$ sbt testQuick`. You can also pass a filename and use tilde to run the tests in a loop if the source code
        changes:
        ```shell
        $ sbt
        > ~testQuick etl.dataset.folder_name.FileNameSpec
        ```
1. Integration tests:
    1. Run all tests:
        ```shell
        $ sbt it:test | less -r
        ```
    1. Run the integration tests for a subset of SparkOps ("filtered run"):
        ```shell
        $ sbt
        > it:testOnly etl.itaipu.ItaipuSchemaSpec -- -DopsToRun=dataset-fact/prospect-junction,dataset-dimension/date
        ```
        or, from the command line directly:
        ```shell
        $ sbt "it:testOnly etl.itaipu.ItaipuSchemaSpec -- -DopsToRun=dataset-fact/prospect-junction,dataset-dimension/date"
        ```


There is a build pipeline for Itaipu, so merging master does not guarantee that the master version will run at night -
itaipu unit and integration tests need to pass, and the version needs to be explicitly promoted on the Go build pipeline
(https://go.nubank.com.br/go/tab/pipeline/history/itaipu and https://go.nubank.com.br/go/tab/pipeline/history/dagao).


## Other sources

When you have a dataset that doesn't originate from a Datomic service and you
want to utilize Spark to process it (periodically), you can build with
itaipu.  See `curva-de-rio`, `dataset-series`, and `StaticOp` for more information.

Parquet files are mainly used for accessing data from Spark / Databricks. Avro files are used for loading into Redshift.

## Bumping libraries on itaipu

Since `itaipu` has code that runs on Spark, we need to keep in mind that some dependencies need to be excluded from packaging, as to not cause conflicts with dependencies that are already brought in by Spark into the classpath.

Itaipu uses `common-etl` [(code)](https://github.com/nubank/common-etl), which carries over dependencies such as `jackson` and the AWS Java SDK. These libraries are also provided by Spark, pinned at a specific version, so in order to avoid conflicts, we need to do the following in itaipu's `build.sbt` [(code)](https://github.com/nubank/itaipu/blob/master/build.sbt#L44-L49):

```
  "common-etl" %% "common-etl" % "9.1.0" excludeAll(
    ExclusionRule(organization="ch.qos.logback"),
    ExclusionRule(organization="org.slf4j"),
    ExclusionRule(organization="com.fasterxml.jackson.core"),
    ExclusionRule(organization="com.fasterxml.jackson.dataformat"),
    ExclusionRule(organization="com.fasterxml.jackson.databind")),
```

And then declare the appropriate dependency versions:
```
"com.fasterxml.jackson.module" %% "jackson-module-scala" % "2.7.2",
"org.slf4j" % "slf4j-log4j12" % "1.7.25",
```

To check which libraries are provided by our Spark runtime, and their versions, have a look at our Spark `pom.xml`: https://github.com/nubank/spark/blob/nubank-2.2.0/pom.xml
