---
owner: "#data-infra"
---

# Using test Docker images with ECR

## Intended audience and scope

Data Infra engineers that need to test a custom Docker image, usually
`itaipu` and, more rarely, `scale-cluster`. In addition to that, the
only supported use is through `sabesp`.

## Create the test image

Please refer to [this guide][1] for the details.

In the specific case of Itaipu, you can create a local image by running
the following script

```bash
./local/itaipu-docker-build.sh # assumes that you are in Itaipu's repo root dir
```

The script will automatically tag the image and print it to stdout (e.g.,
`nu-itaipu:jtorres-9086d1dbb23`). Use that tag for the remaining steps.

## Use the test image

Before proceeding, you can check whether your image is there with:

```
nu-<country> registry list-images test/<docker image>
```

Where `<docker image>` is either `itaipu` or `nu-scale-cluster`.

The rest should be staightforward, just change any of the following
arguments for `sabesp` by prepending the `test/` namespace:
  * `--itaipu=test/<YOUR TAG>` or
  * `--scale=test/<YOUR TAG>`

## Examples

Let’s give some examples for the two main use cases described above:
  * **Testing a custom `itaipu` image**. Some of the changes you made
    are not covered by automated tests. For example, you want to test
    an integration with an external service.
  * **Testing a custom `scale-cluster` image**. Scaling machines is a
    small, but crucial part of our infrastructure. Given that
    `scale-cluster`’s test coverage is rather inadequate and its core
    functionality is effectful, sometimes we need an end-to-end test
    to make sure everything works correctly.

In both cases we’ll use Sabesp, with something like:[^1]

```
./bin/sabesp \
    --aurora-stack=cantareira-dev \
    jobs itaipu staging <MY JOB NAME> \
    s3a://nu-spark-metapod-ephemeral-1/ \
    s3a://nu-spark-metapod-ephemeral-1/ 3 \
    --filter-by-prefix=contract-aloka \
    --instance-type=r5.4xlarge \
    --itaipu=<ITAIPU TEST IMAGE TAG> \
    --scale=<SCALE-CLUSTER TEST IMAGE TAG>
```

Please note that you don’t have to change _both_ `--itaipu` and
`--scale`. Usually, you are testing either a change in `itaipu` or
`scale-cluster`, not both.[^2]


[1]: https://playbooks.nubank.com.br/cicd/ecr/push-test-images-to-ecr/

[^1]: This is just an example. You will probably want to change most
    of the parameters for your concrete use case.

[^2]: And testing two changes at the same time it’s not a good idea
    anyway.
