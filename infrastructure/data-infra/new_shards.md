---
owner: "#data-infra"
---

# Deployment of data infrastructure in a new prototype

This document describes the steps required to deploy components of
data infrastructure in a new prototype or shard for a country.

## Glossary

The following parameters are used through this document:
  * `country`: the country where the data platform is being deployed
  * `env`: the used environment. Normally `staging` or `prod`.
  * `prototype`: logical groups of services that have similar security/deployment requirements. For instance, `global`, or shards (`s0` ... `s14`). Normally, new countries only have `global` and `s0`.


### Spinning up Barragem in a new shard/prototype in the BR environment - known caveats
 
#### Spinning up Aurora DB in the new prototype

Prerequisites:
  * You need the following temporary permissions
      * `barragem-aurora-spin`
      * `barragem-aurora-enhanced-monitoring`
      * `barragem-aurora-db-access`
  * Your AWS profiles should be correctly set up. This is also why we
    do not use something like `nu aws ctl`: with profiles in place
    there is no need to (plus `nucli` doesn’t actually play well with
    roles, at the moment, forcing you to hard code the region).

#### Security group

Create the security group.
```shell
aws --profile $country-$env \
    ec2 create-security-group \
    --group-name $env-$prototype-barragem-aurora \
    --description 'Barragem AuroraDB' \
    --vpc-id <vpc-id>
```

The command will return the ID of the security group, which you can
then use for the next step. You will also need to look up the security group id for
`prod-long-lived-resources-kubernetes-nodes-sg` in the AWS console and pass it in as the source-group option:

```shell
aws --profile $country-$env \
    authorize-security-group-ingress \
    --group-id <sg-id> \
    --protocol tcp \
    --port 5432 \
    --source-group <source-group-id>
```
#### Cluster and instance

Get the DB password using the following command:

```shell
export DB_PASSWORD=$(nu-br aws ctl -- s3 cp s3://nu-secrets-br-prod/barragem_secret_config.json - | jq -r '.["rdb-password"]')
```
We can now create both the cluster and the instance. Set the db password obtained from the previous step. 
Use the security group id of the  security group that you created :

```shell
aws --profile $country-$env \
    rds create-db-cluster \
    --backup-retention-period 7 \
    --db-cluster-identifier $env-$prototype-barragem-aurora \
    --engine aurora-postgresql \
    --engine-version 10.11 \
    --storage-encrypted \
    --no-enable-iam-database-authentication \
    --master-username postgres \
    --master-user-password $DB_PASSWORD \
    --db-subnet-group-name $env \
    --db-cluster-parameter-group-name $env-barragem-aurora-postgres10-cluster \
    --deletion-protection \
    --vpc-security-group-ids <sg-id> \
    --database-name postgres \
    --port 5432 \
    --engine-mode provisioned
```

Lookup the monitoring-role-arn using the AWS console. Look under IAM, roles for 
`rds-barragem-aurora-enhanced-monitoring` for the arn. It should read something like this
`arn:aws:iam::XXXXXXXXXXXX:role/rds-barragem-aurora-enhanced-monitoring`

```shell
aws --profile $country-$env \
    rds create-db-instance \
    --db-cluster-identifier $env-$prototype-barragem-aurora \
    --engine aurora-postgresql \
    --db-instance-identifier $env-$prototype-barragem-aurora-instance \
    --db-instance-class <instance-type> \
    --db-subnet-group-name $env \
    --db-parameter-group-name $env-barragem-aurora-postgres10-instance \
    --auto-minor-version-upgrade \
    --no-publicly-accessible \
    --storage-encrypted \
    --enable-performance-insights \
    --monitoring-interval 60 \
    --monitoring-role-arn <rds-barragem-aurora-enhanced-monitoring ARN>
```

#### Spinning up the Barragem service in the new prototype

Once the RDS is created on the prototype/shard start the _Barragem_ service using Nimbus.

Check the status of the  service and the connectivity to database using the health check endpoint. You should see 
`"postgresql_db":{"healthy":true,"checks":{}}` being reported.

```shell
nu-$country ser curl get $prototype barragem /api/version
```
