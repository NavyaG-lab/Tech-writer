---
owner: "#data-infra"
---

# Setting up your environment

## `setupnu.sh`

To set up a new development environment, see [setupnu.sh](https://github.com/nubank/nudev#setting-up-a-new-development-machine). The `setupnu.sh` script is self-explanatory.

Before setting up, make sure you have gone through [Accounts and access permissions](introduction.md) to be in the **eng** IAM group, otherwise you will encounter problems using your aws key and secret access key while running `setupnu.sh`.

Now and then, people will find minor bugs on setupnu. It is a good opportunity to create your first PR.

### VPN

After running `setupnu.sh`, setup your VPN by following [steps mentioned in the Slack Channel](https://nubank.slack.com/archives/C024U9800/p1545380162000900).

### Validation

To validate the environment is working properly, you should clone a service repo and try to run its tests.

## Setting up scala

Scala 101: <https://wiki.nubank.com.br/index.php/Scala>

Independent of your editor choice, it is always recommended to use IDEA as your default when coding in **Scala**. Download it from here [https://www.jetbrains.com/idea/download/#section=linux](https://www.jetbrains.com/idea/download/#section=linux). You can use the community edition, which is free and works well with **scala** .

After installing IDEA, let's set up our main project, [Itaipu](https://github.com/nubank/itaipu/) :

1. You must already have **[nucli](https://github.com/nubank/nucli/)** installed, so let's use it.
1. Using the `nu projects clone itaipu` command, you can clone Itaipu into your **$NU_HOME**.
1. Now `cd` into itaipu's dir, and run `sbt test it:test` sbt is going to download all necessary dependencies and run Itaipu's tests.

      **Note:** If you've installed `sbt` via Homebrew, you might encounter an sbt failure with cryptic errors. To fix the error, refer to:
      - <https://nubank.slack.com/archives/C20GTK220/p1587130367199700>
      - <https://stackoverflow.com/questions/61271015/sbt-fails-with-string-class-is-broken>
      - Or, pick the version you want to have as default, then change `/usr/local/bin/sb` to `JAVA_HOME="/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home"`.

### Importing Itaipu on IDEA

1. Open IDEA, click on **Configure -> Plugins**.

  ![Config](https://static.notion-static.com/d90d9310dc1642249a992163f8d72c81/Screenshot_2017-12-01_11-58-00.png)

1. Browse Repositories -> Type Scala in the search box, and install the **Scala Language** plugin (you can further add IDEA features by following the instructions in section 7 of wiki's [useful programs](https://wiki.nubank.com.br/index.php/Programas_%C3%BAteis)).

  ![Config](https://static.notion-static.com/6224eb2fb911420bbafca0019e283e0a/Screenshot_2017-12-01_12-00-42.png)

1. Restart IDEA.
1. Click on **Import Project** and select **itaipu's directory**.

  ![menu](https://static.notion-static.com/83b9fb8bf0384dafb15400821f4af401/Screenshot_2017-12-01_12-01-54.png)

1. Select **Import Project from external Model -> SBT**.

  ![menu](https://static.notion-static.com/c5d12ddcbd2f45c1a76f6a6515fe6526/Screenshot_2017-12-01_13-53-31.png)

1. Select the Java SDK that is installed on your machine. If you don't have one, click on **NEW** and select from your local machine.

  ![Import](https://static.notion-static.com/7a4b466d0c1a4ce1be1bf78122f7abc0/Screenshot_2017-12-01_13-56-33.png)

1. Click **Next**, **Next**, and **Finish**. Wait-a-while for IDEA to download all dependencies and build the project.
1. Repeat the process with **common-etl**

Awesome!! You're all set to get started with your onboarding exercises.

## Data Infra's Onboarding Exercise

The goal of this exercise is to make you familiar with Nubank's general and data infrastructures. The exercise is split up into two parts, _Part I_ is ["Creating a dataset"](dataset-exercise.md) and _Part II_ is ["Creating a service to expose a dataset via API"](service-exercise.md).

### Other resources

- [This wiki page](https://wiki.nubank.com.br/index.php/Programas_%C3%BAteis) lists
additional programs not covered by the setup script that you can install and configure.
- [hexagonal-architecture-article](https://alistair.cockburn.us/hexagonal-architecture/)
- [code-organization-glossary](https://github.com/nubank/playbooks/blob/502cd385d5c30f13405f9b481d0557d793c61279/docs/code-organization.md#hexagonal-architecture)
