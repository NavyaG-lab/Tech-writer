---
owner: "#data-infra"
---

# A deep dive into tekton <> itaipu

If you require deeper knowledge on how tekton works in the context of itaipu
tests, this is the right place. Data infra has recently taken more direct
charge of maintaining the tests and bors. As a consequence, this document aims
to enable data infra engineers to understand the test setup deeply enough to
fix and improve it.

**NOTE**: We are currently (2021-05-21) working with the CICD team to get a new
abstraction for running tests going. Once that happens, tests will be declared
within itaipu itself and not in the separate `tektoncd` repo. If you find this
to be the case, this article is (at least partly) outdated! It is also outdated
if we have an sbt caching server set up.

## Caches

Whenever test tasks need to compile the same artifacts in order to run tests,
we save time by creating a build-cache task that compiles the artifacts and
saves them in s3 under a certain key. Subsequent tasks load this cache and can
start the tests right away. The caching process is compiling a set of projects
and creating a (zip-compressed) tarball of the `target` folders of the
(sub-)projects. A `restore-cache` tasks loads and unpacks those folders again.
Sbt is then smart enough to only incrementally compile changes of the current
codebase to the target classes (or nothing at all if the cache is up-to-date).
This simple process has a few intricacies that make it more complex and should
be borne in mind when working with the caches:

### Two kinds of cache keys

There are two fundamentally different kinds of cache usages:

#### 1. Caches that you want to carry over from a recent PR to the current PR

These kinds of caches are obviously not entirely up-to-date but they form a
good basis for the creation of a current cache to start. In an ideal world, you
would always take the cache from the last PR that was merged into master so
that incremental compilation has as little work to do as possible. However,
with BORS (our merge tool) it is impossible to know the specific key of that
last cache. So we create a cache key that can easily be found like so:


```
--cache-key-template=v1-itaipu-dependencies-{% checksum build.sbt %}-{% checksum project/plugins.sbt %}-{% checksum project/build.properties %}-{% checksum .tekton/cache_version %}
```

This cache-key changes only when one of the files used to create it changes.
Unfortunately, if a cache key doesn't change, the files are never updated in s3. This
means our new PR cannot overwrite the old cache with its new incremental
compilations. So the longer none of these files change, the slower and slower
each new build task based on this cache will be. So it's a good idea to bump
the `.tekton/cache_version` file if the initial `itaipu-build` tasks slowly
starts to get very slow.

Another implication of this is that the first build task after changes to these
files has no prior caches available. So don't test changes on caching with the
first PR after changing these files. The build step _must_ be slower there.

#### 2. Caches from the same run (aka `revision`)

In the addition to the above-mentioned carry-over caches, caches are stored a
second time for reuse within the current cicd run. This uses a different key:

```
--cache-key-template=v1-itaipu-dependencies-$(params.revision)
```

`Revision` is the SHA1 of the commit object of the branch. Having this value
available allows us to share the specific caches for this PR with subsequent
steps.

### Sbt scopes: test, it and main

There are different build tasks for different 'scopes' (sbt lingo): main, test
and it. These correspond to the folder structure under `src` in your repo. Sbt
is smart about the dependency structure between projects and scopes. While
principally good, it also means the designer of a cache task has to be smart.
An example to illustrate:

Subprojects depend on `common-etl`. Subproject tests depend on abstractions
from `common-etl/it` and `common-etl/test`. So our subproject cache takes on
subproject and compiles its tests with `sbt "; project shared-user-utils;
compile; test:compile"`. In the intial version of this task,
`shared-user-utils` test scope depended on `common-etl/test` **but** it didn't
import anything from there. Hence, to our surprise, the task did not compile
`common-etl/test` but only `common-etl/it` from which we imported an
abstraction. So the smartness of sbt can cause surprising results and
careful checking is required to ensure it does what you think it does.

### Evolving subproject structure

What exactly a good task to build caches is, changes dynamically with our recent
changes to subproject structure and might need regular updates. An example:

`itaipu-build` task compiles 'everything'. It's the basic first cache that we
run that most other tasks and further caches depend on. The task to create the
cache is: `sbt compile` which means: Run the `compile` task for the `main`
scope of `itaipu` and everything that depends on it. This means we will not
compile any `test` and `it` scopes and need to do that in separate projects.
Also, it means that it will only compile subprojects that itaipu depends on.
This is the case for all projects but our `jirau` subproject. So our current
'build everything' cache does not build all subprojects.

Also, there is an explicit list about which projects' target folders to store
in the tarball. So if a subproject is added in itaipu but the list isn't
updated in `tektoncd`, no caches are saved.

### Load multiple caches

When you load multiple tarballs from multiple caches, they 'merge' fine. File
conflicts mean that the secondly unpacked version is taken but different files
in the same folder structure are just combined. To me, at least, that was
unexpected behavior.


## How the current structure looks

To see the current structure of subprojects and test tasks, check this [miro
board](https://miro.com/app/board/o9J_lDKNVv8=/).

### Subprojects structure

1. **Common-etl** is our project for shared code and abstractions that data infra
   maintains. It is itself dependent on two metadata projects (about squad
   structure and access control) but principally it is our root project. All
   other projects depend on it.
2. **Platform** Subprojects in this category (blue frames) are also owned and
   maintained by data infra. They hold other runners than itaipu that are
   necessary for the platform to work. We plan on moving more of our runners
   from common-etl into this space soon.
3. **Contrib** subprojects are frameworks created by our users.
4. **User defined datasets**: These subprojects hold user-defined datasets/ops
   and are the core reason for the new structure: We are splitting itaipu into
   smaller chunks that go here. The subprojects have their own project for
   shared code (`shared-user-utils`) that all projects depend on. The
   difference with `common-etl` is that this project is not maintained by data
   infra.
5. **Itaipu**: Itaipu itself depends on all the aforementioned projects except
   for `jirau`, a special **platform** project for data infra CLI interfaces.

### Task and cache-structure

We have a few tasks that run immediately without depending on any cache. This
is because they are static checks that don't rely on compiled artifacts.
Examples are the `formatting` checks for the scala code and the
`static-validator`, which contains simple rule-checks like 'No spark actions
can be called in sparkOps'.

#### Cache: Itaipu-build

This is the first cache-building task. It compiles itaipu `main` scope and
hence compiles all projects (except jirau). It uses the PR-carry-over cache as
its basis and saves the first `revision`-based cache.  All subsequent caches
depend on it.

#### Cache: Itaipu-build-integration-tests

This test runs a non-existing integration test in order to make itaipu compile
the `it` scope. I am not convinced this is necessary but investigating in `sbt "; it:compile"`
would have done the job was not important enough against all the other stuff
that required fixing.

The caches are used in four expensive integration test tasks which are
currently our bottleneck in terms of overall CICD speed. Integration tests are
followed by small `staticOp-tests` for `br` and `data` account.

#### Cache: Itaipu-build-unit-tests

Like the above test, this runs a non-existing unit-test to make the
`test` scope compile. This is by far the most resource-intensive job and the
main reason we went into splitting itaipu into subprojects. So as sparkOps move
out into subprojects over time, this job will become less and less resource
intensive and critical. It is definitely one to watch as we might soon be able
to trim it down along with the sucessor tasks:

**Unit test tasks**: Currenly, there are 12 unit test jobs. They list all
`Spec` files in the itaipu `test` folder, sort them by size and then each take
one 12th of them in a round-robin fashion and runs them.

#### Cache: Itaipu-build-common-etl-unit-tests

This cache is helpful not only for common-etl but for all subprojects we have.
So the name is not apt anymore and only remains as it is for lack of time to
move it from its historical origin into something more fitting. It runs the
`shared-user-utils` project in `main` and `test` scopes. This is also commonly
needed for all user defined subprojects and it means that common-etl is
compiled in all scopes.

**Subproject aggregator**: A noteworthy follow-up task of this are the
`subproject-aggregator-[unit/it]-tests`. These are tests for a subproject stub
that is really only an sbt
[aggregation](https://www.scala-sbt.org/1.x/docs/Multi-Project.html#Aggregation)
of other projects. It has no code of its own and any tasks run on this project
are run on all projects that it aggregates. As subprojects grow, we will shard
them out into several such aggragetor projects just like the itaipu unit tests
are split. The improvement is that this respects the project structure. Also,
this means that we can just add a new subproject to the last aggregator project
in itaipu's `build.sbt` and it is run in tekton without touching the `tektoncd`
repo directly.

#### Other tasks depending on itaipu-build

We have a group of sachem schema checking tasks as well as a PII-checking task.
Lastly, there is an `itaipu-package` job that assembles the uberjar for itaipu.


## Resources for tasks

### Memory: On and off-heap

A lot of the maintenance work around failing tests is increasing the resources
for the tests as the projects grow. For subprojects, there are already pre-made
task types `itaipu-subproject-tests-[small,medium,xlarge]`. One can often just
switch the problematic subprojects to these larger settings. If you need to
bump resources directly, the most important thing to keep in mind is to set
both memory on the container as well as on the jvm. Also, the container needs a
decent amount of off-heap memory, i.e. memory that is not assigned to the jvm.
Otherwise, you will still run out-of-memory even if you increase the jvm
memory. There is no exact formula for this, just look at other tasks to get a
feel for what's a good difference. I'd say between 10-20% of off-heap memory is
a good thing.

Also, remember to set the `-Xms` and `-Xmx` flag to the same value to ensure
that the memory for the jvm is not assigned dynamically but always there.
Dynamic allocation has apparently caused issues in the past.

### Cores

We try to keep the amount of cores small, likely for cost reasons. Due to the
fact that we need to keep test execution serial for sparkContext integrity
safety, a single core is all that is needed in most test tasks. It is important
to note though that no parallel compilations are used in cache tasks (and some
non-spark tests). Parallel work can only be performed if you do not limit your
task to a single core.

## Other jvm flags

1. `UseGCOverhead`: Some tasks fail because the garbage collector has too much
   work to do and the jvm fails in such cases. This flag allows a task to
   continue in such cases, trading speed for the ability to compile with lower
   memory. We just use it everywhere ever since it turned out to be helpful.
   This is a decision that can be revisited. It doesn't always make sense to
   just set little memory and then this flag. One could just use more memory in
   the first place. Definitely think about this in case of bottleneck tasks in
   terms of duration.
2. `Dsbt.io.jdgtimestamps=true` This is a patch setting for intermediate sbt
   versions that stopped working with the caches while in a container. I think
   the tarball unpacking cut some precision from the `lastModified` timestamps
   (from ms to s) and so sbt refrained from using the caches. This setting made
   the cache use work again. With the current sbt version, it shouldn't be
   necessary any longer but since it isn't harmful and we had other things to
   do, it is still used. Consider revisiting this in the future.
