# Set up access to the multiple countries

The set up process is described in detail in this [playbook][international-setup-pb]. This document is just meant to be a bookmark that points the reader in the right direction and helps test the setup once it is completed.
For further details  about the multi-country infrastructure and its current state, check out [this presentation][multi-country-infra-presentation]. The details on this document were extracted from it.

## Setup Data account

The following instructions assume that your environment is fully setup for Brazil and that you have a security profile, so feel free to disregard that part.

1. Follow the steps related to the AWS account in the "Before you begin" section of the general [international setup playbook][international-setup-pb]. These steps ensure that you have your AWS account configured for the Data country.
2. Follow the "Nucli" section of the same playbook to ensure that your `nucli` is ready to use the details of the Data account.

### Testing the setup

1. In order to test the set up, we have to first get our first authentication tokens for the country.

```
nu-data auth get-refresh-token --env prod
nu-data auth get-access-token --env prod
```

2. Check whether you can reach services

```
nu-data ser curl GET global metapod /ops/health | jq .
# Example response:
#
# [
#   true,
#   {
#     "http": {
#       "healthy": true,
#       "checks": "ok"
#     },
#     "datomic": {
#       "healthy": true,
#       "checks": {}
#     },
#     "consumer": {
#       "healthy": true,
#       "checks": {
#         "local_state": [
#           true,
#           {
#             "healthy_groups": {
#               "METAPOD-RANDOM-5DVBXWXV": "running",
#               "METAPOD": "running"
#             }
#           }
#         ],
#         "remote_state": [
#           true,
#           {
#             "healthy_groups": {
#               "METAPOD": "running",
#               "METAPOD-RANDOM-5DVBXWXV": "running"
#             }
#           }
#         ]
#       }
#     },
#     "rollout": {
#       "healthy": true,
#       "checks": {
#         "disabled_features": [],
#         "disabled_files": []
#       }
#     }
#   }
# ]
```

3. Check whether you can access S3

```
nu-data aws s3 nu-tmp-data
# This should start the S3 interactive browser, showing what paths there are in the bucket.
```

[international-setup-pb]: https://github.com/nubank/playbooks/blob/master/squads/international/dev-env.md
[multi-country-infra-presentation]: https://docs.google.com/presentation/d/17c2l00x6rdO9bt2C3ZD2P_Gn2G1so7BXEyFwY_gaky0/edit#slide=id.g52bc7810fa_0_231
