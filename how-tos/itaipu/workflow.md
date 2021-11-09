---
owner: "#data-infra"
---

<!-- markdownlint-disable-file -->

# Contributing to Itaipu (workflow)

 * [Contracts Workflow](#contracts-workflow)
   * [Creating a New Contract](#creating-a-new-contract)
   * [Updating an Existing Contract](#updating-an-existing-contract)
   * [Limitations in Contract specifications](#limitations-in-contract-specifications)
 * [Datasets, Dimensions, and Fact Tables Workflow](#datasets-dimensions-and-fact-tables-workflow)
   * [Bus matrix](#bus-matrix)
   * [Databricks Approach](#databricks-approach)
   * [Creating a new dataset](#creating-a-new-dataset)
   * [Editing an existing dataset](#editing-an-existing-dataset)
   * [Make the dataset available in Google BigQuery](#make-the-dataset-available-in-google-bigquery)
 * [Running Tests](#running-tests)
 * [How Itaipu is deployed to the Dagao](#how-itaipu-is-deployed-to-the-dagao)
 * [Publishing an itaipu build](#publishing-an-itaipu-build)
   * [Locally](#locally)
   * [On GoCD](#on-gocd)
 * [Running a debug build](#running-a-debug-build)
 * [Other sources](#other-sources)
 * [Dependencies](#dependencies)
   * [Bumping libraries on itaipu](#bumping-libraries-on-itaipu)

## Contracts Workflow

### Creating a New Contract

Creating a new contract is different than updating an existing contract because you'll need to create some new files.

1. **On the relevant Clojure service**
    1. Create or edit the following files:
        - `contract/contract_main.clj`:

            1. Create it, if it doesn't exist, with the same content as [here](https://github.com/nubank/metapod/blob/master/contract/contract_main.clj))
        - `project.clj`:
            1. Add `:contract` to the `:profiles` ([example](https://github.com/nubank/metapod/blob/a889decd116c284e22692b2d492f134bb65effcf/project.clj#L63)), and `"gen-contracts"` to the `:aliases` ([example](https://github.com/nubank/metapod/blob/a889decd116c284e22692b2d492f134bb65effcf/project.clj#L79))
            1. Ensure the project is using the latest version of
            [`common-datomic`](https://github.com/nubank/common-datomic/blob/master/project.clj).
        - `src/[SERVICE-NAME]/db/datomic/config.clj`:

            1. Add the desired skeletons to `contract-skeletons` ([example](https://github.com/nubank/metapod/blob/a889decd116c284e22692b2d492f134bb65effcf/src/metapod/db/datomic/config.clj#L29)).
        - `src/[SERVICE-NAME]/models/*.clj`:
            1. Ensure every attribute in the `skeleton` has documentation (`:doc`)
            1. Ensure the skeleton itself has documentation (`(def skeleton ^{:contract/doc "Lorem ipsum"} ...)`)
            1. Potentially add:
                - `:contract/include false` if you want to remove the attribute from the ETL
                - `:contract/history true` if you want to include the historical values of that attribute (a separate
                table with columns `audit__cid`, `audit__tags`, `audit__user`, `audit__version`, `db__tx_instant`)
                - `:contract/clearance :pii` when the attribute is PII ([for more info](../data-deletion/pii_and_personal_data.md))
            - [Example](https://github.com/nubank/metapod/blob/master/src/metapod/models/transaction.clj#L13)
        - `test/unit/[SERVICE-NAME]/db/datomic/config_test.clj`
        or for old services
        `test/[SERVICE-NAME]/db/datomic/config_test.clj`:
            1. [if you are using midje] Add a call to function `common-datomic.contract.test-helpers/enforce-contracts! <country>` for each country that needs to have contracts. [Example](https://github.com/nubank/metapod/blob/master/test/unit/metapod/db/datomic/config_test.clj).
            2. [if you are using clojure.test] Add a deftest calling `common-datomic.contract.new-test-helpers/broken-contracts <db-name> <contract-skeletons> <country>` for each country that needs to have contracts. [Example](https://github.com/nubank/cerberus/blob/master/test/unit/cerberus/db/datomic/config_test.clj).
    1. Run `$ lein gen-contracts <country>` (for all countries) to generate the initial contracts in
`resources/nu/data/<country>/dbcontracts/<DB-NAME>/entities`.
        - If you receive the following error:

          ```
          java.lang.AssertionError: Assert failed: Either `:contract/ref-ids` or `:skeleton` must explicitly specified as metadata on a schema.
          ```

          It is probably because it cannot infer some references inside your skeletons. You can fix it by explicitly declaring it in your schema.
          Look at the file `src/tyriel/models/payment_source.clj` from this PR as a reference: <https://github.com/nubank/tyrael/pull/54>.
1. Open a pull request adding the generated files. [Example](https://github.com/nubank/escafandro/pull/37/files)

1. **Before Itaipu**
    1. Make sure that the database exists in prod and is being extracted before adding the contract to Itaipu.

    - [Example query of this on Thanos](https://prod-thanos.nubank.com.br/graph?g0.range_input=1h&g0.expr=max(datomic_extractor_basis_t%7Bdatabase%3D~%22metapod%22%7D)&g0.tab=0) You should see line chart showing the growing amount of data extracted with time. _NB. In this example we are referring to the `metapod` service. You have to replace it with the name of your service._

1. **On Itaipu**

    1. If this is the first contract for this database:
       1. _Create a new package_ (aka folder) under
    [itaipu/src/main/scala/nu/data/\<country\>/dbcontracts/\<database\>](https://github.com/nubank/itaipu/tree/master/src/main/scala/nu/data/br/dbcontracts) named
    after the new database. If the relevant folder already exists, proceed to the next step.
       1. _Create a Scala object for the database_ (using PascalCase, aka upper camel case) that will reference each of the
    contract entities - similar to [itaipu/blob/master/src/main/scala/nu/data/br/dbcontracts/metapod/Metapod.scala](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/dbcontracts/metapod/Metapod.scala).
            - Only if the database is not sharded (that is, it is mapped to global), add the `prototypes` attribute:
    `override val prototypes: Seq[Prototype] = Seq(Prototypes.global)`. Otherwise, leave only the attributes `name`,
    `entities` and `qualityAssessment`.
       1. _Modify_ the `nu/data/<country>/dbcontracts/V1.scala` [file](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/dbcontracts/V1.scala)
          by adding a reference to the database in the val `all` inside the V1 object and importing the DatabaseContract
          `import nu.data.br.dbcontracts.<dbcontract-name>.<database-object>`, eg:
          ```scala
            import nu.data.br.dbcontracts.metapod.Metapod
            import nu.data.br.dbcontracts.papers_please.PapersPlease
          ```
       1.  _Create a Scala object for each new contract entity you are adding_
            - The code should be a direct copy & paste from the contract Scala file(s) generated (with `lein gen-contracts`)
               in the Clojure project into `itaipu/src/main/scala/nu/data/<country>/dbcontracts/<DB-NAME>/entities/`.
                - The files are found in `resources/nu/data/<country>/<DB-NAME>/entities/*.scala` at the service repo.

    1. If this is not the first contract for this database:
       1. _Create a Scala object for the contract entity_
            - Follow step 3.i.d.
       1. _Ensure_ all objects are referenced by the `entities` [val](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/dbcontracts/metapod/Metapod.scala#L13) in the database object.

    1. Follow the instructions about [running tests](#running-tests)

    1. Open a pull request. There’s no need to ask for reviews on Itaipu, we monitor new PRs multiple times a day as the repo is very active.

    1. Follow the instructions about [merging pull requests](./opening_prs.md)

### Updating an Existing Contract

A Clojure service that already has generated contract Scala files will store them in `/resources/nu/data/<country>/dbcontracts/<DB-NAME>/entities/*.scala`.
When running unit tests on a service with generated contracts, any change to an attribute that is
included in a contract (or any addition of an attribute without `:contract/include false`) will
cause the generated Scala file to no longer match.

If you want to add, change or remove an attribute:

1. On the relevant Clojure service:
    1. Make the change you are proposing
    1. Make sure the Datomic model(s) has:
        - an example (`:eg`) and documentation (`:doc`)
        - possibly:
          - `:contract/name` (if you want to alias it for ETL purposes)
          - `:contract/include false` (to remove that attribute, because the default is to include
          them all)
          - `:contract/history true` (if you want to include the historical values of that attribute
          in a separate table with columns `audit__cid`, `audit__tags`,  `audit__user`,
          `audit__version`, `db__tx_instant`)
          - `:contract/clearance :pii` (if the attribute is PII - [for more info](../data-deletion/pii_and_personal_data.md))
    1. Run `$ lein gen-contracts <country>` (for all countries)
1. Paste the updated Scala files into a branch of Itaipu
1. Open pull requests for each and ask someone from data infra squad to review
1. [Merge and profit](./opening_prs.md)

### Limitations in Contract specifications

#### Nested component entities

In Datomic, if an entity only exists in the context of a parent entity, it is common to declare it as a [component entity][component-entity-blog-post].
In our skeleton schemas, an entity can be declared as a component by adding `:component true` to the schema declaration. See the [following example][component-skeleton-example].

Our contract system does not yet support more than 1 level of component entities. In other words, if your entity contains a component entity, that component entity cannot itself have a component entity.

#### Component entities with 1:N cardinality relationships

Our contract system does not yet support component entities that are used as [part of 1:N relationships][one-many-cardinality-example]. If you encounter this limitation, work around it using the steps that follow. We'll be using Ouroboros as an example, but the steps should be the same.

1. Create a `contract-*` skeleton for the entity. That skeleton is derived from the existing skeleton and [excludes the component field][exclude-component-metadata-example].
2. Use the newly created skeleton on your `contract-skeletons` definition [in the Datomic config][contract-skeleton-def-example].
3. Re-generate the contracts via `lein gen-contracts`. You should now see the contract for the component entity.
4. Create a new PR with the new contract on Itaipu.

#### Entities with tuple attributes

`common-datomic` allows you to specify attributes of type `CompositeTuple`, including for id attribute. Tuples are currently not supported in the ETL and trying to generate a contract for an entity with a composite tuple will fail with a compilation error. For this reason, when working with attributes of this type in your service, you'll need to remove them from the generated contract by adding `:contract/include false` on them ([example][exclude-composite-tuple-example]).

If the attribute was meant to be a primary key of the entity, you'll likely need to create an alternate primary key for your entity, which is more suitable for ETL processing, such as a UUID field.

#### Entities with more than one polymorphic attribute

An attribute is considered polymorphic if it is a reference attribute pointing to more than one entity type in your model (in your code, this will usually be attributes which use a conditional schema). When generating contracts for your service, the contract generator will generate one contract file per possible type of that attribute for your entity.

For example, we can imagine a data model where there is a `Request` entity with a `:request/source` attribute. If there are multiple possible sources for this entity, then the schema for `:request/source` will likely look something like `(s/conditional ... SourceType1 ... SourceType2)`. In such a case, the `:request/source` attribute is considered polymorphic (because there are more than one entity types it points to). As a result, Request entity will not have one but two contract files: `SourceType1Requests` and `SourceType2Requests`.

Because we generate one file per possible type of the polymorphic attribute, an entity can have at most 1 polymorphic attribute on its schema (to avoid combinatorial explosion). If your entity has more, you should either rework your data model to get back to having a single one, or exclude all but one of those attributes from the contract (and thus exclude them from the ETL). Attributes can be excluded from contracts by adding `:contract/include false` on their skeleton ([example][exclude-composite-tuple-example]).

#### Optional polymorphic attributes

When an attribute is polymorphic (see section above for detailed explanation), one contract file is generated per possible type of entity that the attribute points to. As a result, any instance of your entity that does not have a value for this attribute (i.e. where the value is missing in Datomic) will not have a corresponding contract file to generate a table in the ETL. Consequently, while there will be no errors when implementing your service and generating your contracts, the outcome is those entities where this particular attribute is missing will not appear in the ETL.

#### Cardinality-many PII attributes

Cardinality-many PII attributes are currently not supported due to a bug.

[component-entity-blog-post]: https://blog.datomic.com/2013/06/component-entities.html
[component-skeleton-example]: https://github.com/nubank/ouroboros/blob/3873ef74be7dc9bd6e1f545de1b19fd03f9f8d77/src/ouroboros/models/resource_group.clj#L31
[one-many-cardinality-example]: https://github.com/nubank/ouroboros/blob/3873ef74be7dc9bd6e1f545de1b19fd03f9f8d77/src/ouroboros/models/resource_group.clj#L30-L32
[exclude-component-metadata-example]: https://github.com/nubank/ouroboros/blob/3873ef74be7dc9bd6e1f545de1b19fd03f9f8d77/src/ouroboros/models/record_series.clj#L43-L48
[exclude-composite-tuple-example]: https://github.com/nubank/arnaldo/blob/a7bfdd87b2e28202e55ea7a1a56c7b7769ebfbf8/src/arnaldo/models/reissue_request.clj#L84
[contract-skeleton-def-example]: https://github.com/nubank/ouroboros/blob/3873ef74be7dc9bd6e1f545de1b19fd03f9f8d77/src/ouroboros/db/datomic/config.clj#L25

## Datasets, Dimensions, and Fact Tables Workflow

Creating datasets:

- [See quotes from Kimball on designing dimensional models here](../../tools/frozen_suite/iglu/kimball.md)

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
[itaipu/src/main/scala/nu/data/[country]/datasets/](https://github.com/nubank/itaipu/tree/master/src/main/scala/nu/data/br/datasets/):
    1. Create the (sub)folder, e.g., `folder_name`
    1. Create a package file called `package.scala` inside the new (sub)folder with the following content (assuming that
         the file that you will create in the next step is called `FileName.scala`):
        ```scala
        package nu.data.<country>.datasets.parent_folder_name_if_subfolder

        import common_etl.operator.SparkOp

        package object folder_name {

          // only if the new class receives inputs, e.g., `referenceDate` (String), `targetDate` (String),
          // `referenceLocalDate` (LocalDate), `targetLocalDate` (LocalDate)
          def allOps(referenceDate: String): Seq[SparkOp] = {
            val fileNameOp = FileName(referenceDate)
            Seq(fileNameOp)
          }

          // only if the new class doesn't receive inputs:
          def allOps: Seq[SparkOp] = {
            Seq(FileName)
          }

          // only if there are subfolders (assuming it receives `referenceDate` as input):
          def allOps(referenceDate: String): Seq[SparkOp] =
            subfolder1.allOps(referenceDate) ++
            subfolder2.allOps ++
            subfolder3.allOps(referenceDate)
        }
        ```
    1. Add `folder_name.allOps` to `all` in
         [itaipu/src/main/scala/nu/data/[country]/datasets/package.scala](https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/datasets/package.scala)
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

    - It's possible to [make the dataset available in Google BigQuery](#make-the-dataset-available-in-google-bigquery)
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
    [itaipu/src/test/scala/nu/data/[country]/datasets](https://github.com/nubank/itaipu/tree/master/src/test/scala/nu/data/br/datasets/). If the
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
1. Follow the instructions about [merging pull requests](./opening_prs.md)

### Make the dataset available in Google BigQuery

If you want to make the dataset available in Google BigQuery, you need to:
1. Override the `SparkOp` member `warehouseMode` with the value `WarehouseMode.Loaded`. [See the example](https://github.com/nubank/itaipu/blob/a206527f34acf419cdbb70acfbc145d5899d6be8/src/main/scala/etl/dataset/billing_cycles/BillingCycles.scala#L15).
2. [Extend the class](https://github.com/nubank/itaipu/blob/a206527f34acf419cdbb70acfbc145d5899d6be8/src/main/scala/etl/dataset/billing_cycles/BillingCycles.scala#L15) with the trait `DeclaredSchema`
3. [Override the `attributes` method](https://github.com/nubank/itaipu/blob/a206527f34acf419cdbb70acfbc145d5899d6be8/src/main/scala/etl/dataset/billing_cycles/BillingCycles.scala#L21-L34).

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
        > ~testOnly etl.dataset.folder_name.FileNameSpec
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
        sbt it:test | less -r
        ```
    1. Run the integration tests for a subset of SparkOps ("filtered run"):
        ```shell
        $ sbt
        > it:testOnly etl.itaipu.ItaipuSchemaSpec -- -DopsToRun=dataset-fact/prospect-junction,dataset-dimension/date
        ```
        or, from the command line directly:
        ```shell
        sbt "it:testOnly etl.itaipu.ItaipuSchemaSpec -- -DopsToRun=dataset-fact/prospect-junction,dataset-dimension/date"
        ```


## How Itaipu is deployed to the Dagao

Please see [Data Infra release engineering](../../infrastructure/data-infra/releng.md).

## Publishing an itaipu build

### Locally

You can follow [these instructions](../../onboarding/data-infra/dataset-exercise.md).

### On GoCD

1. Force-push your changes to the `debug-build` branch of `itaipu`
2. Trigger the [`itaipu-debug-build`](https://go.nubank.com.br/go/tab/pipeline/history/itaipu-debug-build) job on GoCD. This will build the image and once the downstream `itaipu-debug-build-publish` is done the image should appear on our image registry ECR.
3. You can get the image with the nucli command `nu registry list-images nu-itaipu`.

## Running a debug build

1. Follow the steps written out in the section [On GoCD](#on-gocd)
2. Then use `sabesp` to run a build with your image:

```shell
nu datainfra sabesp -- --aurora-stack=cantareira-dev jobs itaipu prod ARBITRARY_NAME s3a://nu-spark-metapod-ephemeral-1 s3a://nu-spark-metapod-ephemeral-1 10 --itaipu=YOUR_IMAGE_ID --scale=MOST_RECENT_SCALE_ID --filter-by-prefix=contract-aloka
```

Where:
`ARBITRARY_NAME` is how you identify your testrun in logs and metrics. E.g. [your.name]-test
`YOUR_IMAGE_ID` is found via nucli from the registry
`MOST_RECENT_SCALE_ID` can be found at #etl-updates channel in the first message by the aurora app each day (at 1:00 AM) with all the version details about the current run.


## Other sources

When you have a dataset that doesn't originate from a Datomic service and you
want to utilize Spark to process it (periodically), you can build with
`itaipu`.  See [`dataset-series`](../../data-users/etl_users/dataset_series.md) and `StaticOp` for more information.

Parquet files are mainly used for accessing data from Spark / Databricks. Avro files are used for loading into Google BigQuery.

## Dependencies

The dependencies are listed [here](https://github.com/nubank/itaipu/blob/2977173662217daee58adb75356834f20d215d89/build.sbt#L39). They typically follow the [format](https://www.scala-sbt.org/1.x/docs/Library-Dependencies.html#The++key) `groupID % artifactID % revision`.

To compile the main sources (in `src/main/scala` and `src/main/java` directories) and download the dependencies:
```shell
sbt compile
```
Reference: https://www.scala-sbt.org/1.x/docs/Running.html#Common+commands

Itaipu downloads them from [Maven](https://maven.apache.org/) and nu-maven (Nubank's private repo on AWS S3). To download from S3, itaipu uses the plugin [Frugal Mechanic SBT S3 Resolver](https://github.com/frugalmechanic/fm-sbt-s3-resolver).

To check the latest versions:
* In Maven: https://search.maven.org/

    * Go to the Advanced Search and use the GroupId and ArtifactId. It's possible that you need to append the Scala version to the `artifactID` (e.g., `_2.11` for Scala 2.11). For example: `g:"org.typelevel" AND a:"cats_2.11"`.
* In nu-maven:
    ```shell
    aws s3 ls s3://nu-maven/snapshots/common-etl/
    ```

### Bumping libraries on itaipu

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
