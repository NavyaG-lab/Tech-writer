---
owner: "#data-infra"
---

# Debugging Dataset Series (DSS) data loss issues

This playbook has data-infra as their primary audience. The goal here is to enable other engineers to debug potential data loss issues with the current DSS ingestion system. This playbook has been written to ease this debugging process with similar upcoming queries.

[Here](https://nubank.slack.com/archives/C06F04CH1/p1633360516293500) is an example thread in `#data-help` slack  channel where the users were suspecting of DSS data loss. With this plabook, it should be easier and more straight forward to resolve such issues in the future. 

## Pre-requisites 

- Make sure to get the following information: 
  1. Confirm that there are no schema mismatches - [See DDS FAQ](../../data-users/FAQs/dataset-series.md)
  2. Confirm that there are no deduplication issues - [See DDS FAQ](../../data-users/FAQs/dataset-series.md)
  3. Make sure the series in question ingestion metadata turned on - Every event-based dataset series has additional ingestion-related metadata that can be made visible by overriding the flag `DatasetSeriesContract.addIngestionMetadata` and setting it to `true`.
  4. The series name - this playbook will use `"series/personal-loan-parameters"` as an example
  5. `CID` of the missing message. Ideally you should be able to get ahold of the log line which produced the message to the `EVENT-TO-ETL` topic. If a user reported the suspected data loss, they should provide this CID before you start your investigation.
  6. The name of the service which allegedly produced the message.
  7. The `shard/prototype` on which this message was produced
  8. The date of when the missing message supposedly was transmitted to the ETL

Before anything else, running a simple query in BigQuery allows you to validate that we indeed don't have the message related to this `CID` ingested and processed by our ETL.

```sql
select *
from `nu-br-data.series_contract.<the_series_name>`
where series_event_cid LIKE '<THE_PROVIDED_CID>%';
```

If, as a result of the query above, nothing is returned, then it indeed is a case where data may have been lost and we need to understand where.

**Optional**: For cases where the missing records are so old that their log lines are not available in Splunk anymore, it's recommended to install [ripgrep](https://github.com/BurntSushi/ripgrep) as it is generally a lot faster than the good old `grep` to perform searches on your local file system. (And it made the waiting times of this kind of investigation bearable)

## Check whether the message was handled by Riverbend OR Alph

Beginning of October 2020, we started to migrate Dataset Series from Riverbend to Alph.

Any record date before October 2020 was handled by Riverbend, a system that has been sunset exactly due to the fact that data loss were occurring with an undesirable frequency. Therefore, anything prior this date is not even worth the effort and we can assess along with the users whether re-transmitting that message is an option.

Messages transmitted between October 09th up to November 20th should be first validated against this [Google Doc](https://docs.google.com/document/d/1nmTEpeByUI5q0vmxoL4h4HmDzm69CFZneLrpHMLRugY/edit) where it is possible to find which and when DSSs have been migrated to Alph.

If the date that the message was published matches with Alph being the current DSS ingestion service. Follow to the next section.

## Check the end-to-end flow of the message

This playbook aims to validate the end-to-end of DSS messages through system logs. The log lines that have to be checked in order are as follows:
1. From the origin system, the log line `:log :out-message` with `:topic "EVENT-TO-ETL"` attribute
2. From [Alph](https://github.com/nubank/alph), the log line `:log :event-to-etl-handler` with `:topic "EVENT-TO-ETL"` and its associated `:batch-cid` asserts that Alph consumed the published message
3. Still from Alph, the log line `:log :upload-to-s3` as well as another log line `:log :out-message` with `:topic "NEW-SERIES-PARTITIONS"` attribute along with its associated `:cid` asserts that Alph published the message to notify Ouroboros
4. From [Ouroboros](https://github.com/nubank/ouroboros), the log line `:log :ouroboros.db.datomic.resource-group/resource-appended!` asserts that the batch of data processed by Alph is made available to be processed by the ETL (a.k.a [Itaipu](https://github.com/nubank/itaipu))

This playbook will guide you through the steps to trace the end-to-end flow of DDS messages. While following these steps, in case you fail to assert the expected results described in each of the sections the owner of the system in check should review its codebase to identify possible reasons for the failure of the said flow.

From this point of this playbook on, let's a situation where:
1. `DEFAULT.XLLK2.AJYB6.4GSZK.MFPSB.XLRU6.D6XVH.35YY5.JS2DT.WZ46H.UEZ7Q.F6NN3.DWVWC.2021-06-12.personal-loan-policy.RSFSU.MAKYK.NAK3L.KLO34.KFR7P.44Z5Y.WCWD3` is the CID we're looking for
2. `consigliere` is the name of the service which produced the missing records.
3. `s2` is the prototype on which the records were produced.
4. `2021-06-12` is the date when the records were produced.

**Important note**: For cases where the missing records are fresh and their log lines are still available in Splunk, please skip to the [Trace the origin system by using the provided CID](#trace-the-origin-system-by-using-the-provided-cid) section. Make use of the search patterns in the follow-up sections to search for the log lines in Splunk. Adapting them to your needs should be straight forward.

**Important note 2**: For cases where log lines are still available in Splunk and that the data is coming from `curva-de-rio`, you can use this [Splunk dashboard](https://nubank.splunkcloud.com/en-US/app/search/dssingestiondebug?form.global_time.earliest=-24h%40h&form.global_time.latest=now) to debug such cases.

For the purpose of this guide, we adopted a date that is too old and therefore not available in Splunk. Because of this, the log lines for tracking the propagation of our records will not be available on Splunk anymore. In this case, we first need to download the relevant Splunk logs for our service and Alph.

### Get Splunk logs backup from S3

Before anything, make sure you have access to the backup bucket you're interested in. Here is the list of backup bucket paths per countries:
- br   -> `nu-log-bkp`
- co   -> `nu-log-bkp-co`
- data -> `nu-log-bkp-data`
- ist  -> `nu-log-bkp-ist`
- mx   -> `nu-log-bkp-mx`

Normally, as a data-infra engineer you can simply request to one of our `@data-infra-perm-admins` the following inline-policy: `nu-<country> iam allow your.user generic data-infra read-nu-log-bkp-<country>-<environment> --until=Xdays`.

And, in case you are NOT a data-infra Engineer, you should reach out to InfoSec through [this form](https://nubank.atlassian.net/servicedesk/customer/portal/1/group/6/create/97) and request the following permission: `nu iam allow <user.name> read bucket <path>` - e.g. `nu iam allow john.doe read bucket nu-log-bkp-mx/prod/*`.

For the purpose of this playbook example, the Splunk logs that we need to fetch from S3 are related to the year-month `2021-06` for the following services:
- `consigliere` as the service owned by our users. 
- `alph` and `ouroboros` being the services owned by data-infra.

```bash
# Create parent directory to store debugging data:
mkdir $HOME/dss-debug
# and then let's access this directory
cd $HOME/dss-debug

# Create a some directories to store Splunk logs for each of the services
mkdir consigliere-logs consigliere-gzs
mkdir alph-logs alph-gzs
mkdir ouroboros-logs ouroboros-gzs

# Download splunk logs backup from S3 for consigliere
aws s3 sync --profile br-prod \
--exclude "*" \
--include "*2021-06-12*.gz" \
s3://nu-log-bkp/prod/2021/06/s2/blue/consigliere/ consigliere-logs

# Access & decompress the downloaded logs for consigliere
cd consigliere-logs && gunzip -dk *.gz

# and move the gz files elsewhere
mv *.gz ../consigliere-gzs

# Download splunk logs backup from S3 for alph
aws s3 sync --profile br-prod \
--exclude "*" \
--include "*2021-06-12*.gz" \
s3://nu-log-bkp/prod/2021/06/s2/blue/alph/ alph-logs

# Also download for the 13th 
# as it depends on the time that the message have been consumed 
# by Alph. Think of possible lag that the service may have faced 
# at that day
aws s3 sync --profile br-prod \
--exclude "*" \
--include "*2021-06-12*.gz" \
s3://nu-log-bkp/prod/2021/06/s2/blue/alph/ alph-logs

# Access & decompress the downloaded logs for alph
cd ../alph-logs && gunzip -dk *.gz

# and move the gz files elsewhere
mv *.gz ../alph-gzs

# Download splunk logs backup from S3 for ouroboros (which is not a sharded service)
aws s3 sync --profile br-prod \
--exclude "*" \
--include "*2021-06-13*.gz" \
s3://nu-log-bkp/prod/2021/06/global/blue/ouroboros/ ouroboros-logs

# Access & decompress the downloaded logs for ouroboros
cd ../ouroboros-logs && gunzip -dk *.gz

# and move the gz files elsewhere
mv *.gz ../ouroboros-gzs
```
From this point, Splunk logs from all the involved services, in their respective shards, and at certain dates are available locally.

### Trace the origin system by using the provided CID

**Note**: From here onwards, it's assumed that have installed [ripgrep](https://github.com/BurntSushi/ripgrep)

The first verification we want to make is that `consigliere` published the alledgedly lost message to `EVENT-TO-ETL`

```bash
# Access consigliere-logs dir
cd $HOME/dss-debug/consigliere-logs

# Search for the provided CID
rg "DEFAULT.XLLK2.AJYB6.4GSZK.MFPSB.XLRU6.D6XVH.35YY5.JS2DT.WZ46H.UEZ7Q.F6NN3.DWVWC.2021-06-12.personal-loan-policy.RSFSU.MAKYK.NAK3L.KLO34.KFR7P.44Z5Y.WCWD3" *
```

You should find a log line similar to this one:
```log
311250:2021-06-13T03:44:08.105Z [consigliere:async-thread-macro-6] INFO  c.interceptors.observability - {:line 55, :cid "DEFAULT.XLLK2.AJYB6.4GSZK.MFPSB.XLRU6.D6XVH.35YY5.JS2DT.WZ46H.UEZ7Q.F6NN3.DWVWC.2021-06-12.personal-loan-policy.RSFSU.MAKYK.NAK3L.KLO34.KFR7P.44Z5Y.WCWD3.JMBOD", :topic "EVENT-TO-ETL", :log :out-message, :par 17, :offset 176346205}
```

Like it can be seen in the log line above, to assert that the system has done its job correctly we should look for a log message of type `:out-message` flagging that a message has been published to the `:topic "EVENT-TO-ETL"`.

From here on, it's possible to use the `CID` found in the message to keep digging.

### Trace Alph by using the follow-up CID

```bash
# Access alph-logs dir
cd $HOME/dss-debug/alph-logs

# Search for the follow-up CID
rg "DEFAULT.XLLK2.AJYB6.4GSZK.MFPSB.XLRU6.D6XVH.35YY5.JS2DT.WZ46H.UEZ7Q.F6NN3.DWVWC.2021-06-12.personal-loan-policy.RSFSU.MAKYK.NAK3L.KLO34.KFR7P.44Z5Y.WCWD3.JMBOD" *
```

Now, we're looking for the evidence that Alph consumed that message from `EVENT-TO-ETL`. The following log lines confirms this while bringing us additional data to keep digging:

```log
306779:2021-06-13T03:44:08.111Z [alph:clojure-agent-send-off-pool-266] INFO  alph.diplomat.consumer - {:line 16, :cid "DEFAULT.XLLK2.AJYB6.4GSZK.MFPSB.XLRU6.D6XVH.35YY5.JS2DT.WZ46H.UEZ7Q.F6NN3.DWVWC.2021-06-12.personal-loan-policy.RSFSU.MAKYK.NAK3L.KLO34.KFR7P.44Z5Y.WCWD3.JMBOD.UDGVM.SH22A", :topic "EVENT-TO-ETL", :log :event-to-etl-handler, :batch-cid "DEFAULT.XUNUQ", :commit-group "async-thread-macro-3"}

306780:2021-06-13T03:44:08.111Z [alph:clojure-agent-send-off-pool-266] INFO  alph.controllers.process - {:line 41, :cid "DEFAULT.XLLK2.AJYB6.4GSZK.MFPSB.XLRU6.D6XVH.35YY5.JS2DT.WZ46H.UEZ7Q.F6NN3.DWVWC.2021-06-12.personal-loan-policy.RSFSU.MAKYK.NAK3L.KLO34.KFR7P.44Z5Y.WCWD3.JMBOD.UDGVM.SH22A", :topic "EVENT-TO-ETL", :log :alph.controllers.process/handle-message!, :series-name "series/personal-loan-parameters", :data-size 1}
```

If you didn't find similar log lines as the ones above, you will have to investigate whether there is something wrong with the [event-to-etl-handler](https://github.com/nubank/alph/blob/master/src/alph/diplomat/consumer.clj#L13-L24) function.

The `:event-to-etl-handler` log line confirms that Alph handled the message. This does not mean that the message was successfully processed, as messages are accumulated into a buffer in Alph which needs to be flushed for a message to be available in the ETL. `:batch-cid` is the CID of the batch accumulation and flushing process. We must use this new CID to follow up on what happened to our records after Alph received them as it enables use to correlate with Alph's action to upload a batch of messages to S3. And it also allows us to assert that a message to `NEW-SERIES-PARTITIONS` topic related to `:series-name "series/personal-loan-parameters"` has been published.

To continue digging Alph's logs:
```bash
rg "DEFAULT.XUNUQ" | rg "series/personal-loan-parameters"
```

Which should yield similar log lines like these:

```log
prod-s2-blue-alph-deployment-797575b599-jt9qr_alph-application.log.2021-06-13-00:2021-06-13T03:46:55.892Z [alph:clojure-agent-send-off-pool-262] INFO  alph.controllers.commit - {:line 55, :cid "DEFAULT.XUNUQ.V4AWK", :log :upload-to-s3, :dataset-name "series/personal-loan-parameters", :file-size 465970, :num-events 1803, :file "dataset-7904288516998730339.avro"}

prod-s2-blue-alph-deployment-797575b599-jt9qr_alph-application.log.2021-06-13-00:2021-06-13T03:46:56.541Z [alph:clojure-agent-send-off-pool-262] INFO  c.interceptors.observability - {:line 54, :cid "DEFAULT.XUNUQ.V4AWK.3YCKW", :log :out-message, :topic "NEW-SERIES-PARTITIONS", :subtopic :series/personal-loan-parameters, :size 1631, :par 29, :offset 959180}
```

This time around, if you didn't find similar log lines as the ones above, you will have to investigate whether there is something wrong with the [event-to-etl-pre-commit](https://github.com/nubank/alph/blob/master/src/alph/diplomat/consumer.clj#L26-L38) function.

The two most important pieces of evidence that we found are:
- The `:upload-to-s3` log. This line indicates that Alph has successfully uploaded a batch of messages to S3.
- And the `:out-message` log indicates that Alph has successfully published a message to `NEW-SERIES-PARTITIONS`. 
  
With the assert facts that Alph has indeed uploaded the file to S3 and that Alph has successfully published the message to `NEW-SERIES-PARTITIONS` topic. Alph's job is done here.

The follow-up is to look into Ouroboros logs.

### Trace Ouroboros by using the follow-up CID

The evidence we have so far is that the data was correctly handled by Alph and written to a file on S3. Alph then sent a message to `Ouroboros` to register the file in the ETL. We're now going to look for evidence that Ouroboros correctly handled this message.

```bash
# Access ouroboros-logs dir
cd $HOME/dss-debug/ouroboros-logs

# Search for the follow-up CID
rg "DEFAULT.XUNUQ.V4AWK.3YCKW" | rg ":ouroboros.db.datomic.resource-group/resource-appended"
```

The command above should yield a simiar output:

```log
prod-global-blue-ouroboros-deployment-d45db795d-7x424_ouroboros-application.log.2021-06-13-00:2021-06-13T03:46:56.757Z [ouroboros:async-thread-macro-1] INFO  ouroboros.db.datomic.resource-group - {:line 208, :cid "DEFAULT.XUNUQ.V4AWK.3YCKW.UIVQS.DRGJA", :topic "NEW-SERIES-PARTITIONS", :log :ouroboros.db.datomic.resource-group/resource-appended!, :record-series-name "series/personal-loan-parameters", :record-series-type :events, :resource-group-id #uuid "60c53b74-2b2e-44a7-946f-3cef15917e84", :resource-group-format :avro, :schema-id #uuid "6038165a-86c5-4ef0-87c2-550e65192acb", :schema-hash -791323958, :schema-attribute-count 35, :resource-id #uuid "60c57fb0-41e6-4c6f-9b5d-ff5764a1b0ea", :resource-committed-at #nu/time "2021-06-13T03:46:56.543Z", :location-type :single-path, :location-path "s3://nu-spark-metapod-dataset-series/prod/s2/3f747ba6-a47d-429c-85b5-c70e851eb330/3f747ba6-a47d-429c-85b5-c70e851eb330.avro"}
```

If you didn't find similar log lines as the ones above, you will have to investigate whether there is something wrong with the [new-series-partitions!](https://github.com/nubank/ouroboros/blob/master/src/ouroboros/diplomat/consumer.clj#L34-L49) function.

The `:ouroboros.db.datomic.resource-group/resource-appended!` log is the evidence proving that the message has been sucessfully consumed by Ouroboros. Additionally, it tells us exactly where the data is finally stored in S3. In this case, its location is `:location-path "s3://nu-spark-metapod-dataset-series/prod/s2/3f747ba6-a47d-429c-85b5-c70e851eb330/3f747ba6-a47d-429c-85b5-c70e851eb330.avro"`

From this point on, the data must be in the ETL. And, once again, if that is not the case please reach out to data-infra via #data-help slack channel.

At this point, if you run the following SQL query in BigQuery you should get the record corresponding to the message that is allegedly missing.

```sql
select *
from `nu-br-data.series_contract.personal_loan_parameters`
where series_event_cid = 'DEFAULT.XLLK2.AJYB6.4GSZK.MFPSB.XLRU6.D6XVH.35YY5.JS2DT.WZ46H.UEZ7Q.F6NN3.DWVWC.2021-06-12.personal-loan-policy.RSFSU.MAKYK.NAK3L.KLO34.KFR7P.44Z5Y.WCWD3';
```

The query above returned exactly the one record we were looking for. 🎉
