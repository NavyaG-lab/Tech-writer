### Troubleshooting Schema Validation Failures

If your dataset has a declared `metapod` schema, it is expected that it matches the dataset's actual (Spark SQL) schema. In case it does not match during a run, Itaipu posts alerts about it on [#squad-di-alarms](https://nubank.slack.com/messages/C51LWJ0SK/). For example,
```
Schema validation for series-raw/aws-cur-test-contract-avro, owned by DataInfra failed.
```

The fix for such inconsistencies in the schema is usually a simple one. The most common scenario is that you missed to declare a particular attribute of the dataset in the declared schema. This is defined in your `SparkOp`, as a field called `attributeOverrides` (you can see an example of this [here](https://github.com/nubank/itaipu/blob/583492a5bda37a5ddc2d098878b05db74589ed7e/src/main/scala/etl/dataset/rollout_distribution/RolloutFeatureDistribution.scala#L23-L27)).

To look at the actual validation error, you can follow the following steps:
- Go to this [Splunk query](https://nubank.splunkcloud.com/en-GB/app/search/search?s=%2FservicesNS%2Fnobody%2Fsearch%2Fsaved%2Fsearches%2FETL%2520-%2520%2520Schema%2520Validation%2520Failures&display.page.search.mode=smart&dispatch.sample_ratio=1&q=search%20index%3Dcantareira%20%22Schema%20validation%20%22%20%7C%20rex%20%22failed%20for%20(%3F%3Copname%3E.*)%20from%20squad%20(%3F%3Csquad%3E.*)%20with%20the%20following%20errors%3A%20(%3F%3Cerrors%3E.*)%22%20%7C%20stats%20count%2C%20max(_time)%20as%20time%20by%20opname%2C%20squad%2C%20errors%20%7C%20fieldformat%20time%20%3D%20strftime(time%2C%20%22%25Y-%25m-%25d%22)%20%7C%20where%20(opname%3D%22dataset%2Fprospect-key-integrity-avro%22)&earliest=-7d&latest=now&display.page.search.tab=statistics&display.statistics.format.0=color&display.statistics.format.0.scale=sharedCategory&display.statistics.format.0.colorPalette=sharedList&display.statistics.format.0.field=squad&sid=1559305199.714510).
- Replace the `opname` in the query to filter for your dataset (eg. `dataset/prospect-key-integrity-avro`). 
- This will display the validation errors for this particular dataset under the column name `errors`. It will look something like this:
```
NonEmptyList(DiscordantTypeError(StructField(cpf_added_at,StringType,true),Attribute(name = "cpf_added_at", logicalType = LogicalType.TimestampType, nullable = Some(true), primaryKey = Some(false))))
```

This might look incomprehensible, but trust me, it's not ;) . Each `DiscordantTypeError` you see here is an error you have in your dataset. So if the error column for your dataset has multiple `DiscordantTypeError`, they each point to a different schema issue in your dataset. Since, in most cases, these errors are independent of each other, you can fix them one-at-a-time.

Let's see how to read an individual `DiscordantTypeError` with the same example as above:
```
DiscordantTypeError(StructField(cpf_added_at,StringType,true),Attribute(name = "cpf_added_at", logicalType = LogicalType.TimestampType, nullable = Some(true), primaryKey = Some(false)))
```

- The `DiscordantTypeError` above describes an inconsistency for an attribute called `cpf_added_at`. `StructField` above describes the actual (Spark SQL) schema which was encountered during run-time, while `Attribute` represents the attribute from the declared schema of the dataset.
- In this particular case, `cpf_added_at` has a run-time type `StringType` while it was declared to be a `LogicalType.TimestampType`.
- That's it. You now know the reason behind the validation error. Fixing it, however, is a different ball-game. It requires knowledge of the semantics of the attributes, and how it should be represented. That is why you, the creator/owner of the dataset, are best positioned to fix this issue.
- To take an example, in the above case, the fix could either be changing the type of `cpf_added_at` in the declared schema to `StringType`, or investigating why `cpf_added_at` is `StringType` at run-time, instead of `TimestampType`. It depends of the exact semantics of the `cpf_added_at`.
