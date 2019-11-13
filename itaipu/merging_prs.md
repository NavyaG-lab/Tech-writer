# Merging a PR on Itaipu

## bors

`bors` is a merge automation tool that helps merging several PRs at the same time. It's an open source tool available [here](https://github.com/bors-ng/bors-ng).

For an updated documentation on bors, please check: https://bors.tech/

## Deploy

`bors` is hosted on the Mobile Platform's Kubernetes cluster. It lives on the `staging` prototype, stack id `indigo` and shard `mobile`.

To update bors, you can follow the instructions [here](https://github.com/nubank/mobile-k8s-recipes/blob/master/recipes/bors/README.md) and simply killing the pod should be enough to update it to the latest version. `bors` maintain its state in a Database, so there isn't any problem in killing the pod.

## Interface

`bors` has an UI to interact with it and to check the queue status: https://bors.nubank.com.br/repositories/8

The [history tab](https://bors.nubank.com.br/repositories/8/log) should provide status and errors if there are any when interacting with `bors`. Feel free to reach #squad-data-access in Slack if you have any questions.

## Itaipu

Currently, `bors` is being used as the only to get a PR merged in [Itaipu](https://github.com/nubank/itaipu/). You can check the configuration used by `bors` here: https://github.com/nubank/itaipu/blob/master/bors.toml

`bors` enforces the [Github Labels](https://github.com/nubank/data-platform-docs/blob/master/itaipu/pr_review.md#github-labels) are properly set, if there are at least a [CODEOWNER](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/about-code-owners) review before allowing a PR to enter its queue.

## Code Owners

Itaipu uses a [CODEOWNERS](https://github.com/nubank/itaipu/blob/master/.github/CODEOWNERS) file to validate if a user can approve a PR or not . The later entries have precedence over the ones inserted first. You can check more about Code Owners [here](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/about-code-owners).


## Permissions

Any user that has access to Itaipu, should be able to interact with `bors`. If you are not able to interact with it, bors will comment the following:

```
🔒 Permission denied

Existing reviewers: click here to make <user_name> a reviewer
```

This will redirect, to a page: https://bors.nubank.com.br/repositories/8/add-reviewer/<user_name> where you can just hit `ok` to add the user.

The user can also be added to the Reviewers list in the settings: https://bors.nubank.com.br/repositories/8/settings

## CircleCI

We use CircleCI for ensuring tests are run for every PR on Itaipu. Currently, `bors` is responsible to ensure all the tests are run in CircleCI before merging to `master`.

`bors` uses the `staging` branch to batch PRs and run all the tests before merging the PR. We only run all the tests on this branch, so in the Github Interface you might not see all tests we run on `staging`. `bors` will report all the tests in a comment before merging your PR. 

The reason we did this is because we have a lot of users creating PRs and pushing to several branches and running tests for everyone is very costly. So we reduced the amount of tests running in users' branches. 

## Commands

`bors` by receiving commands done by commenting in PRs. Any user can use any command:

| Syntax | Description |
|--------|-------------|
| bors r+ | Run the test suite and push to master if it passes. Short for "reviewed: looks good."
| bors merge | Equivalent to `bors r+`.
| bors r- | Cancel an r+, r=, merge, or merge=
| bors try | Run the test suite without pushing to master.
| bors try- | Cancel a try
| bors ping | Check if bors is up. If it is, it will comment with _pong_.
| bors retry | Run the previous command a second time.
| bors p=[priority] | Set the priority of the current pull request. Pull requests with different priority are never batched together. The pull request with the bigger priority number goes first.
| bors r+ p=[priority] | Set the priority, run the test suite, and push to master (shorthand for doing p= and r+ one after the other).

## bors try

`bors try` is a special command. In our setup, you only need to use if you working on subprojects inside of Itaipu and want to run the tests through Github/Circle CI.
