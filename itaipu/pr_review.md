## Service Level Agreement (SLA)

Data access squad will review PRs in [itaipu](https://github.com/nubank/itapu) during business days, from 9 am until 7 pm, except on days when the squad is not in the office. Some PRs may take up to 2 business days to be reviewed. On Fridays, we will avoid merging changes that may have a negative effect in the ETL run.

If you expect to open a PR after that time, but need it to be merged on the same day, post a message on #guild-data-eng with reasonable notice (e.g., before 4 pm).

Examples of behavior you should avoid:
* Open a PR at 7:30 pm, and send a direct message or message in `#guild-data-eng` (maybe with `@here` or `@channel`), asking for an urgent review and approval, so that the PR can be merged in the same day.
    * What we expect. During the morning or early in the afternoon you post a message on `#guild-data-eng` explaining that you are working on a code change that will need to be merged on that day, and telling the reasons why you didn't do it before. When you open the PR, you can notify `@data-access` in the thread of the PR on `#guild-data-eng`.
* Messages such as:
    * "Can you merge?"
    * "It's only a small change"
    * "It's a simple PR"
    * "Please review"
    * "It's urgent”

## GitHub Labels

### Issues

0 to 4 scale of priority:
* 0 very low priority
* 1 low priority
* 2 medium priority
* 3 high priority
* 4 very high priority

### Pull Requests

Label names start with "-PR" to make the labels appear on the top of the list.


* <b>-PR Changes Requested</b>
    * Description: Someone requested for changes
    * When to add:
        * "Request changes" In the review; or
        * Comment asking for changes
    * When to remove:
        * When the person who chose "Request changes" approved; and
        * Comments were addressed
    * Who should add:
        * Anyone

* <b>-PR Hold</b>
    * Description: Don't merge the PR
    * When to add:
        * There are blockers 
    * When to remove:
        * There are no blockers
    * Who should add:
        * Anyone

* <b>-PR Old</b>
    * Description: PR is some days old
    * When to add:
        * Nothing happens in the PR for many days
    * When to remove:
        * Activity is restored in the PR
    * Who should add:
        * Maintainers

* <b>-PR Ready For Merge</b>
    * Description: PR is ready to be merged by the maintainers 
    * When to add:
        * PR is approved by the maintainers and possibly by teammates; and
        * Tests pass; and
        * There are no blockers; and
        * No more changes are going to be made
    * When to remove:
        * To replace with another label, but this should be an exception.
    * Who should add:
        * Anyone

* <b>-PR Review Requested</b>
    * Description: PR needs reviewing
    * When to add:
        * No more changes;
        * Tests pass
    * When to remove:
        * PR approved or changes requested;
        * Update with master makes tests fail or create merge conflict
    * Who should add:
        * Commiter

* <b>-PR Teammate Review Requested</b>
    * Description: PR needs reviewing by teammate
    * When to add:
        * 
    * When to remove:
        * 
    * Who should add:
        * Anyone

* <b>-PR WIP</b>
    * Description: Work in progress
    * When to add:
        * Tests are not passing; or
        * There are conflicts with master; or
        * Changes are still being made
    * When to remove:
        * No more changes; and
        * Tests pass
    * Who should add:
        * Commiter

### Label workflow

1. -PR WIP
2. -PR Review Requested
    * -PR Ready For Merge; or
    * -PR Changes Requested → -PR Ready For Merge

In addition to the labels above, use -PR Hold and/or -PR Old when necessary.

## Communication

### Direct messages on Slack

Don't send.

### Slack Channels

#### Description

* `#data-access-alarms:`
    * Alarms for squad data-access: aws-cloud-watch-alarm (mordor), MetaBot, Promotion (go), Security Bot, Service cycler/scale (metabase, mordor), Tio Patinhas
    * Mostly for internal use (data-access and data-infra squads)
* `#data-announcements`:
    * Announcements about ETL runs, Mordor, Belomonte, Metabase, Databricks, etc.
* `#data-crash`:
    * For issues in the ETL (failure, updates and actions taken)
    * https://github.com/nubank/data-infra-docs/blob/master/squad/hausmeister.md#visibility
* `#data-help`:
    * Questions about Python, Scala, SQL, Datalog, Belomonte, Metabase, Databricks, Mordor, Spark
* `#etl-updates`:
    * Automated updates regarding the ETL pipeline
* `#guild-data-eng`:
    * Where you can ask or request about your PRs (???)
* `#guild-data-eng-prs`:
    * Mostly PRs opened and merged in GitHub repositories related to the ETL (e.g., itaipu and common-etl)
* `#guild-data-support`:
    * Specific discussions of the guild, whose interest is share knowledge related to accessing data and writing code
* `#learn-code`:
    * Announcements and requests for classes related to programming and data access
* `#squad-data-access`:
    * Squad specific discussion (dailies, OKRs, presentations, etc)
    * Ask for access to specific S3 buckets
    * Integration with GitHub repositories owned exclusively by data-access
* `#squad-data-infra`:
    * Questions, requests, comments, issues, … related specifically with data infra, such as cantareira's runtime environment and the ETL serving layer
* `#squad-di-alarms`:
    * Alarms for squad data-infra: aws-cloud-watch-alarm (Redshift), Databricks Loader, OpsGenie, Promotion (go), Service cycler (mesos-master), Splunk
    * Mostly for internal use (data-infra squad)

#### How to use

* You have a question: post on `#data-help`
* You want your PR to be reviewed and merged: wait
* You want to see if there is a problem with the ETL run: check on `#data-announcements`
* You want to see if there is any change in the ETL or in the tools: check on `#data-announcements`
* You want to check the status of the DAG (when it started to run, which datasets were computed and loaded already): check on `#etl-updates`
* You want to see if there is something wrong with the data infrastructure: check on `#data-access-alarms` and `#squad-di-alarms`
* You don't exactly a question, but want some advice, want make a comment, a suggestion, .... If you know it's related to the data access squad, post on `#squad-data-access`; if it's related to the data infra squad, post on `#squad-data-infra`; if you're not sure, post on `#squad-data-access`, and someone will redirect the message to the adequate channel.
* You want to see what the plans are for new classes: check on `#guild-data-support`
* You want to see what classes related to programming and data are being taught: check on `#learn-code`

## Github Pull Request Reviews

* Dataset:
    * All Datasets must have tests
    * All `MetapodAttribute` must have a description
    * Your DataSet must have the SparkOp properties: `description`, `ownerSquad`, `qualityAssessment`
    * If it is a new Dataset or `StaticOp`, add it to `allOps` or `allStaticsof` the corresponding `package.scala` file
* Code style:
    * Use IntelliJ's plugin scalafmt
    * [Indentation](https://docs.scala-lang.org/style/indentation.html):
        * Indent with 2 spaces; no tabs
        * Avoid long lines (>  ~100 characters); wrap the expression across multiple lines when necessary
        * Try to avoid any method which takes more than two or three parameters
    * [Naming conventions](https://docs.scala-lang.org/style/naming-conventions.html):
        * Avoid underscores ( _ ) in names, but use in DataFrame column names
        * Use UpperCamelCase in names of classes, traits, objects
        * Use lowerCamelCase in names of methods (def), value (val) and variable (var), but UpperCamelCase for constants (member is final, immutable and belongs to a package object or an object)
        * Don't use symbolic (`+`, `<`, `*`, ...) method names, unless they are well-understood and self documenting
        * Use short names, few local names (including parameters)
    * [Types](https://docs.scala-lang.org/style/types.html):
        * Use type inference where possible, but put clarity first
        * Don't annotate the type of a private field or a local variable, unless it has a complex or non-obvious form
        * Type annotations: `value: Type`
        * Type ascription: `Nil: List[String]`, `Set(values: _*)`, `"Daniel": AnyRef`
        * Functions: use a space between the parameter type, the arrow and the return type; parentheses should be omitted wherever possible: `def foo(f: Int => String) = ...`, `def bar(f: (Boolean, Double) => List[String]) = ...`
    * [Nested blocks](https://docs.scala-lang.org/style/nested-blocks.html):
        * Opening curly braces (`{`) must be on the same line as the declaration they represent
    * [Files](https://docs.scala-lang.org/style/files.html):
        * Class, trait or object called `MyThing` in package `my.cool.thing` should be in path `src/main/scala/my/cool/thing/MyThing.scala`, except for subtypes of sealed superclasses (and traits)
    * [Control structures](https://docs.scala-lang.org/style/control-structures.html):
        * All control structures (`if`, `for`, `while`) should be written with a space following the defining keyword
        * `for`-comprehension with `yield` clause: `for (one generator) yield ...` (with parentheses) or `for {more than one generator split by line} yield ...` (with curly-braces)
        * `for`-comprehension without `yield` clause: `for (...) { … }`
        * `for`-comprehensions are preferred to chained class to `map`, `flatMap` and `filter`
        * Short `if/else` expression: `val res = if (foo) bar else baz`
    * [Method invocation](https://docs.scala-lang.org/style/method-invocation.html):
        * Use 1 space after the comma, and 1 space on either side of the equals sign in named parameters: `foo(42, bar)`, `target.foo(42, bar)`, `target.foo()`, `foo(x = 6, y = 7)`
        * Arity-0 methods: `pureFunction` (no parentheses), `withSideEfffects()`
        * Infix notation:
            * Symbolic-named methods and maybe operator-like methods like `max`, especially if commutative: don't use punctuation and use 1 space around it: `a + b`, `a max b`
            * Alphabetic-named method: use dot and parentheses: `names.mkString(",")`
        * Postfix notation: `names.toList`
    * [Declarations](https://docs.scala-lang.org/style/declarations.html):
        * Class/Object/Trait constructors should be declared all on one line, unless the line becomes “too long” (about 100 characters). In that case, put each constructor argument on its own line, indented 4 spaces and 2 spaces for extensions.
        * All class/object/trait members should be declared interleaved with newlines, except `var` and `val` only if none of the fields have Scaladoc and if all of the fields have simple (max of 20-ish chars, one line) definitions.
        * Fields should precede methods in a scope, except if the `val` or `lazy val` has a block definition (more than one expression) and performs operations which may be deemed “method-like” (e.g. computing the length of a `List`).
        * Local methods or private methods may omit their return type
        * Method modifiers should be given in the following order (when each is applicable):
            * Annotations, each on their own line
            * Override modifier (`override`)
            * Access modifier (`protected`, `private`)
            * Implicit modifier (`implicit`)
            * Final modifier (`final`)
            * `def`
              ```
              @Transaction
              @throws(classOf[IOException])
              override protected final def foo(): Unit = {
                ...
              }
              ```
            * Spacing:
                * There should be no space between parentheses and the code they contain: `(a, b)`
                * Curly braces should be separated from the code within them by a one-space gap or a line-break: `{ a, b }`
                ```
                class Person(
                    name: String,
                    age: Int,
                    birthdate: Date)
                  extends Entity
                  with Logging
                  with Serializable {
                  val bar = 42
                  val baz = "Daniel"
                
                  def doSomething(): Unit = { ... }
                
                  def add(x: Int, y: Int): Int = x + y
                
                  def foo(x: Int = 6, y: Int = 7): Int = x + y
                  
                  private def foo(x: Int = 6, y: Int = 7) = x + y
                
                }
                ```
    * [Scaladoc](https://docs.scala-lang.org/style/scaladoc.html):
        * Document all classes, objects, traits and methods
        * Text begins on the first line of the comment
        * All lines of text are aligned on column 5
        * Try to format the first sentence of a method as `"Returns XXX"`
        * The same goes for classes: `"Does XXX"`
        * The first sentence should be a summary of what the element does. Subsequent sentences explain in further detail.
        * Create links to referenced Scala Library classes using the square-bracket syntax, e.g. `[[scala.Option]]`
        * Use the annotations `@param`, `@tparam` (type parameter),  `@return` (summary of the return value; don't use if documentation is in one line)
        * Gutter asterisks can be aligned in column 2 or 3. Example below in column 3:
          ```
          /** Provides a service as described.
            *
            * This is further documentation of what we're documenting.
            * Here are more details about how it works and what it does.
            */
          def member: Unit = ()
          
          /** Does something very simple */
          def simple: Unit = ()
          ```
        * Packages:
            * First document what sorts of classes are part of the package. Secondly, document the general sorts of things the package object itself provides.
            * It should provide an overview of the major classes, with some basic examples of how to use the classes in that package. Reference classes using the square-bracket notation:
        * Methods and other members: 
    * Optimize imports
* Followed instructions in the PR template

