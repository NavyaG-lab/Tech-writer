---
owner: "#data-infra" "#Analytics-productivity"
---

<!-- markdownlint-disable-file -->

# Step 5 - How to write tests for your dataset

Imagine if someone updated a dataset with incorrect code, then this will mess your dataset and add more work for you to figureout the issue and a solution to fix it. Therefore writing tests for your dataset can help you to avoid the given situation. The tests ensure that your dataset won't actually be updated unless all the tests are passed.

Here's what a test looks like. You can save this template IntelliJ under `Name: ETL - Scala Class Test` and `Extension: scala`
 ```scala
 package etl.dataset.${PACKAGE_NAME}

import etl.NuDataFrameSuiteBase
import etl.TestHelpers.checkDataFrameAssertion
import etl.implicits._
import org.scalatest.{FlatSpec, Matchers}

class ${NAME} extends FlatSpec with NuDataFrameSuiteBase with Matchers {
  import spark.implicits._

  "methodName" should "do something" in {
    val date   = nuSQLDate"2016-10-31"
    val number = 1L
    val amount = big"1337"
    val someId = "some-id"
    
    val input = ""

    val result = className.methodName(input)

    val expected = Seq(
      (1, "foo"))
      .toDF("num", "text")

    checkDataFrameAssertion(
      assertDataFrameEquals,
      expected,
      result)
  }
}
 ```
 The tests for your newly generated class are going to be *almost* at the same path as your class, except you're going to change the folder `main` to `test`. So if your class is in `src/main/scala/etl/nu/br/dataset/folder_name/` then your test class will be in `src/test/scala/etl/nu/br/dataset/folder_name/`. The test class should have the same name as the original class + Spec in the end. So `YourDataset` has the test `YourDatasetSpec`.
 
 !!**Important**

 _*When you decide to create real datasets, you'll divide your code into several functions, as to not create one single huge function that does everything. To ensure that every part works, you'll create tests for each one of these parts. In our case, though, since it is a small and simple query, we only have the filterCalls function to test.*_
 
 ```scala
 "filterCalls" should "take only calls from 08008870463 and from after 2017-02-01" in {

    //checkDataFrameAssertion(assertDataFrameEquals, expected, result)
  }
 ```
 
 - What inputs does `filterCalls` need? Just the Calls ContractOp. So we're making a fake Calls table, with just the important fields, and feeding it to the function.
 
 ## Write test cases for your dataset (SparkOp)

 **What cases can we test?** Well, we need test cases. What could make a record in our Calls table not appear in our OuvidoriaCalls table? 
 1 - Calls happened after "2017-02-01"
 2 - Calls having a NULL call__reason
 3 - The number being different to "08008870463"

 So we'll create the following tests:
 
 | id  | time        | our_number  | reason                 |
 | --- |:-----------:| -----------:|:----------------------:|
 | 1   | 2016-10-13  | 11111111111 | call_reason__logistics |
 | 2   | 2017-10-13  | 11111111111 | call_reason__logistics |
 | 3   | 2016-10-13  | 08008870463 | call_reason__logistics |
 | 4   | 2017-10-13  | 08008870463 | call_reason__logistics |
 | 5   | NULL        | 08008870463 | call_reason__logistics |
 | 6   | 2017-10-13  | NULL        | call_reason__logistics |
 | 7   | 2017-10-13  | 08008870463 | NULL                   |
 
 - id `1` won't pass because it has a wrong date and number. 
 - id `2` has a right date, but wrong number. 
 - id `3` has the right number, but wrong date. 
 - id `4` should pass. 
 - id `5` has NULL time, which is before "2017-02-01" , so it's out. 
 - id `6` has a NULL number, so out too. 
 - id `7` has a NULL reason, so out.
 
 So let us make our test. 
 - First thing to know is that, to create a date easily, you can use nuSQLDate"date_here". 
 - Second, when you have a null field, you have to worry about NullPointers. Anyone that has ever come a meter away from a Java programmer knows how bad those are. So, we _*don't use `null` when creating a table, we use `None`*_. But to make sure that the rest of the field has the same type, we wrap them up.

### Create DataFrame and add column names

 We also have to transform it into a DataFrame and give the column names. Like this:
 
 ```scala
 val fakeCalls = Seq(
      ("1", Some(nuSQLDate"2016-10-13"), Some("11111111111"), Some("call_reason__logistics")),
      ("2", Some(nuSQLDate"2017-10-13"), Some("11111111111"), Some("call_reason__logistics")),
      ("3", Some(nuSQLDate"2016-10-13"), Some("08008870463"), Some("call_reason__logistics")),
      ("4", Some(nuSQLDate"2017-10-13"), Some("08008870463"), Some("call_reason__logistics")),
      ("5", None,                        Some("08008870463"), Some("call_reason__logistics")),
      ("6", Some(nuSQLDate"2017-10-13"), None,                Some("call_reason__logistics")),
      ("7", Some(nuSQLDate"2017-10-13"), Some("08008870463"), None)
    ).toDF("call__id", "call__started_at", "call__our_number", "call__reason")
 ```
 Now we pass this fake DataFrame to the `filterCalls` function.
 ```scala
 val result = OuvidoriaCalls.filterCalls(fakeCalls)
 ```
 We define what we expect as output, that being a table just with entry 4, with its fields properly renamed.
```scala
val expected = Seq(
      (nuSQLDate"2017-10-13", "4", "08008870463", "call_reason__logistics")
    ).toDF("time", "call_id", "our_number", "reason")
```
Then we compare them.
```scala
checkDataFrameAssertion(assertDataFrameEquals, expected, result)
```

## The Final Test

Here's the final test.

```scala
import etl.NuDataFrameSuiteBase
import etl.TestHelpers.checkDataFrameAssertion
import etl.implicits._
import org.scalatest.{FlatSpec, Matchers}

class OuvidoriaCallsSpec extends FlatSpec with NuDataFrameSuiteBase with Matchers {

  import spark.implicits._

  "filterCalls" should "take only calls from 08008870463 and from after 2017-02-01" in {

    val fakeCalls = Seq(
      ("1", Some(nuSQLDate"2016-10-13"), Some("11111111111"), Some("call_reason__logistics")),
      ("2", Some(nuSQLDate"2017-10-13"), Some("11111111111"), Some("call_reason__logistics")),
      ("3", Some(nuSQLDate"2016-10-13"), Some("08008870463"), Some("call_reason__logistics")),
      ("4", Some(nuSQLDate"2017-10-13"), Some("08008870463"), Some("call_reason__logistics")),
      ("5", None,                        Some("08008870463"), Some("call_reason__logistics")),
      ("6", Some(nuSQLDate"2017-10-13"), None,                Some("call_reason__logistics")),
      ("7", Some(nuSQLDate"2017-10-13"), Some("08008870463"), None)
    ).toDF("call__id", "call__started_at", "call__our_number", "call__reason")

    val result = OuvidoriaCalls.filterCalls(fakeCalls)

    val expected = Seq(
      (nuSQLDate"2017-10-13", "4", "08008870463", "call_reason__collections_bills")
    ).toDF("time", "call_id", "our_number", "reason")

    checkDataFrameAssertion(assertDataFrameEquals, expected, result)
  }
}
```
Also, remember to format everything with scalafmt.

## Step 6 - Running tests
***
First, [install sbt](https://www.scala-sbt.org/1.0/docs/Setup.html).

Now that you have `sbt` installed, run it.
```
sbt
```
Then, in sbt, run
```
testOnly etl.dataset.folder.YourDatasetSpec
```
If the test runs successfully, run all the tests (to check if you have managed to somehow break something else) with
```
test
```
and
```
it:test
```

There's a chance that you will have problems with "GC overhead limit excedeed" errors. In order to solve that via terminal, you need to launch your sbt with `sbt -mem 9000` to set your GC memory limit. This number is arbitrary but should work for most cases.

Also, you can create a file on the `/usr/local/bin` directory with the name `sbtopts` and write `-mem 9000` inside it, so everytime you launch `sbt` it will automatically add the flag.

## Step 7 - Adding your dataset (SparkOp) to Itaipu
***
Thought we were done? Think again. Don't worry, though, we're almost there.
Now that we created the Dataset and its tests, we need to add them to Itaipu. There are two possibilities on what you needed to do, depending on where you put your new class.
 - [If you created a new folder](#if-you-created-a-new-folder)
 - [If you used an existing folder](#if-you-used-an-existing-folder)

### If you created a new folder

If you have created your new Scala class in a new folder, then you need to create a new file called `package.scala` in the same folder. It will be like this:

```scala
//If it is a subfolder of dataset, use this
package etl.dataset
//If not, use this
package etl.dataset.parent_folder_name

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
If you're a subfolder of a `dataset` subfolder, then you'll need to add folder_name.allOps to the allOps of the parent folder.
If you're simply a subfolder of `dataset`, Then you will need to add folder_name.allOps to opsToRun in [itaipu/src/main/scala/etl/itaipu/Itaipu.scala](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/itaipu/Itaipu.scala). 
Do try, in both cases, to simply add a new line and not change any of the existing ones. That means, if you have:
```scala
folder1.allOps ++
folder2.allOps ++
folder3.allOps)
```
Do this:
```scala
folder1.allOps ++
folder2.allOps ++
your_folder.allOps ++
folder3.allOps)
```
Instead of this
```scala
folder1.allOps ++
folder2.allOps ++
folder3.allOps ++
your_folder.allOps)
```
!! **Important**
_*To try to avoid branch conflicts. Also, remember to format everything with scalafmt.*_

### If you used an existing folder
If you used an existing folder, all you have to do is go to the folder's `package.scala` file and add your subfolder.allOps to its allOps.

Do try to simply add a new line and not change any of the existing ones, and keep it into alphabetical order. That means, if you have:
```scala
a_subfolder1.allOps ++
b_subfolder2.allOps ++
d_subfolder3.allOps)
```
Do this:
```scala
a_subfolder1.allOps ++
b_subfolder2.allOps ++
c_your_subfolder.allOps ++
d_subfolder3.allOps)
```
Instead of this
```scala
a_subfolder1.allOps ++
b_subfolder2.allOps ++
d_subfolder3.allOps ++
c_your_subfolder.allOps)
```
!! **Important**
_*To try to avoid branch conflicts. Also, remember to format everything with scalafmt.*_

## Mandatory Verification Checklist before creating a PR

Here's a quick list to check before asking for a PR - [CHECKLIST FOR CREATING A NEW DATASET](dataset-verification-checklist.md).

## Step 8 - Create a Pull Request (PR)

Now that you've done all that, pass one more time if you've formatted everything with scalafmt, create a new branch and push your commit, then ask for a pull request. We'll try to review it as soon as possible, but please remember that we have other things to do. 

!! Important: Refer to **[How to open a PR?](../../how-tos/itaipu/opening_prs.md)** guide.

That is all for now! See you next dataset!

### What's Next?
- [How to debug dataset issues using Databricks?](debug-datasets.md)
- [How to optimize your SparkOp (dataset)?](../../data-users/etl_users/optimizing_your_sparkop.md))
- [How to check your dataset status on ETL run?](check-dataset-output.md)
