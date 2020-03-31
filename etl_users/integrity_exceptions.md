### About this document ###

Here are the steps to follow to get an early warning on Slack when
your dataset is failing because of an integrity exception.

  1. Make sure you have declared a default Slack channel in
     [definition][2]. See [this example][3].
  2. Invite the app `@data_infra_monitoring` in the same channel

After this, if anything goes wrong, you should see a message like the
following in your channel (line wraps added for clarity):

```
SparkOp dataset/collections-history written at \
s3a://nu-spark-metapod-ephemeral-1/CcrVO_y0Sq-Tk38EUPxVWQ \
failed to commit in transaction b32b138f-5285-5ec6-902b-8fdb95ab3b62 \
due to integrity check error: columns [collection__id, date] are not unique
```

If we cannot find the Slack channel associated with the failing
dataset, the message will be posted on
[#etl-integrity-checks][1].

[1]: https://nubank.slack.com/archives/CGBLGLYFK
[2]: https://github.com/nubank/definition
[3]: https://github.com/nubank/definition/blob/master/resources/br/squads/data-infra.edn
