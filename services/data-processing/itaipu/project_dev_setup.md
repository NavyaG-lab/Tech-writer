---
owner: "#data-infra"
---

# Itaipu project development setup

## Prerequisites

- Make sure you have completed the general Nu [dev setup](https://github.com/nubank/nu-setup)
- Install [SBT and scala](https://www.scala-lang.org/download/)


### Configure IntelliJ

* IntelliJ should be installed if you followed the Nu dev setup

1. Open IntelliJ, click on **Configure -> Plugins**.

  ![](https://static.notion-static.com/d90d9310dc1642249a992163f8d72c81/Screenshot_2017-12-01_11-58-00.png)

2. Browse Repositories -> Type Scala in the search box, and install the **Scala Language** plugin.

  ![](https://static.notion-static.com/6224eb2fb911420bbafca0019e283e0a/Screenshot_2017-12-01_12-00-42.png)

3. Restart IDEA.
4. Open IDEA, click on **Configure -> Preferences**.
5. Navigate to **Build, Execution, Deployment -> Compiler -> Scala Compiler -> Scala Compiler Server**.
6. Change **JVM maximum heap size, MB** to `8192`.
7. Restart IDEA.

## Setup Itaipu

### Clone repository

```bash
nu project clone itaipu
```

### Setup Itaipu with IntelliJ

1. Start IntelliJ by opening it from the terminal inside the Itaipu folder. This way environment variables configured by Nu CLI are used by IntelliJ.

```bash
idea
```

2. Once the IDE is open, select **Import project** and select the sbt file.

3. Selection option **Import as project**, it will take some time to setup as it has to download dependencies and build the project.

4. If prompted, choose to use scalafmt for formatting.

5. Wait until the build of the project is complete.

#### Running sbt tasks inside IntelliJ (Optional)

Typically users prefer to use sbt from the terminal and not from IntelliJ, but still you can configure it.

1. Open Itaipu Project Preferences or use shortcut `cmd + ,` then select Build, Execution, Deployment -> sbt.

2. Select the Java SDK that is installed on your machine. If you don't have one, click on **NEW** and select from your local machine.

3. On **General settings**, change **Maximum heap size, GB** to at least `9`.

4. Uncheck **Allow overwriting sbt version**, this way the IDE runs sbt with the project version.

5. Click Apply.

- If you get errors related to dependencies of the project, force IntelliJ to reload sbt Project: Go to menu **View --> Tool Windows --> sbt** and click on the button to Refresh (arrows in a circle).


### Setup Itaipu with SBT from the terminal

1. Start sbt.

```bash
export SBT_OPTS="-Xms512M -Xmx9G" sbt
```

2. Once SBT has started, compile the code.

```bash
compile
```

3. Run tests.

```bash
test
```

4. Check available tasks.

```bash
tasks
```

### Troubleshooting


#### SBT startup error

```bash error while loading String, class file '/modules/java.base/java/lang/String.class' is broken
(class java.lang.NullPointerException/null)
[error] java.io.IOError: java.lang.RuntimeException: /packages cannot be represented as URI`
```

- Check if the env var of `JAVA_HOME` is configured and pointing to the Java version installed in your local setup
- Check the sbt version you have installed in your local setup compared to the sbt version in the sbt file from Itaipu

#### Build error GC overhead


```java
java.lang.OutOfMemoryError: GC overhead limit exceeded
```

- Increase the JVM Xmx memory configuration.

#### Dependencies errors

```bash
Error downloading metapod-client:metapod-client:3.1.0
```

- Refresh your aws credentials `nu aws credentials refresh`
- Check if you have access to the s3 bucket `nu-maven` by running the command `nu-br aws ctl -- s3 ls s3://nu-maven` in your terminal. If this fails, review if you have completed the nu [setup](https://github.com/nubank/nu-setup) successfully and reach out to #squad-itops.
- If errors are present in IntelliJ, restart IDE from the terminal.
