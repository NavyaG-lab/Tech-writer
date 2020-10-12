---
owner: "#data-infra"
---

# Mergulho

Mergulho is a package within
[itaipu](https://github.com/nubank/itaipu) to increase observability of
our semantic data processing by computing metadata for our data.

## Rationale

As our data volume grows, we are faced (among others) with two problems around
_observability_:

1. We (data tribe as well as stakeholders) do not know what data exists
   anymore. Anyone who needs a dataset for some task has a really hard time
   figuring out if such a dataset exists or something close to it that would be
   a good place to start. The current solution is asking on slack and relying
   on tribal knowledge or building everything you need directly from the
   contract layer, which leads to redundancy in storage and processing of data.
2. Even if a nightly ETL run works well on the processing (syntactic) level, we
   have no way of checking whether the data were processed correctly on a
   content (semantic) level. We have logging and alert systems in place for the
   syntactic level but checking if the processed data makes sense is often done
   incidentally by stakeholders using visual inspection and asking on slack.

The scope of Mergulho is to tackle both of these issues. The solution is to
compute summary metrics of all the data being processed each day. This reduces
the enormous amount of data to a more manageable amount of **metadata** which
can be queried and explored, used for a catalogue system of our data as well as
automated data sanity checks that trigger alerts in case of failures.

This approach is well in line with current trends in the industry: For
catalogue systems with metadata, see

* [Google Goods](https://research.google.com/pubs/pub45390.html)
* [Ground](http://cidrdb.org/cidr2017/papers/p111-hellerstein-cidr17.pdf)
* [LinkedIn WhereHow's](https://github.com/linkedin/WhereHows)

For sanity checks on summary statistics, check out [deequ](https://github.com/awslabs/deequ).

**If you feel this is something you want for your data, feel free to skip ahead
to [here](#i-want-mergulho-run-on-my-data).**

## Design

A basic set of [Metrics](#metrics) is available and there is a small
API to run these metrics on a single column of interest or an entire
dataset.

### Metrics

Mergulho defines a set of [metrics](https://github.com/nubank/itaipu/blob/master/common-etl/src/main/scala/nu/data/infra/mergulho/metrics/Metric.scala)
that can currently be selected to run on our data. Moreover, these metrics are
grouped into subsets that are sensible for certain content types of data. These
subsets are selected by Mergulho as described [below](#metric-application).
Available metrics are currently limited in the following ways:

* There are only metrics for the most basic data types (no nested types for example)
* Metrics only return a single value (no intervals such as an inter-quartile range)
* Metrics are first pass metrics. That means that more complex metrics that
  involve multiple runs over the data or metrics that are based on other
  metrics are not implemented as of now.
* There are only metrics for entire datasets or single columns. Metrics for
  multiple columns (correlation) or specific values contained in columns are planned for
  later.

Each metric defines:

1. A name
2. A compute mechanism which **must be expressed as a Spark transformation**.
3. What data it is valid for
4. Its scope (Dataset, SingleColumn...)
5. Its output type as a `common-etl.schema.LogicalType`

Applying a metric returns an 7-column dataframe with the following columns:

1. Metapod transaction id
2. Dataset name
3. Metric scope
4. Column name (`ALL_COL` for dataset metrics)
5. Metric name
6. Metric output type
7. Metric value (serialized as string)

Other columns might be added but they are enrichments for convenience. These
seven output columns are intended to be reduced to a Datomic-like
EntityAttributeValue (EAV) structure, where columns 1-2 define the entity, 3-5
the attribute and 6-7 make up the value.

### Metric application

[API](https://github.com/nubank/itaipu/blob/master/common-etl/src/main/scala/nu/data/infra/mergulho/internal/MetricsCollector.scala)

There are currently four ways to get Mergulho to run metrics on your data:

1. You know a dataset that interests you and want to run all sensible metrics
   on it: `allMetricsOnDataset` will use heuristics to select the most
   appropriate metrics for you. This is the default that is used when applying
   Mergulho to new datasets automatically.
2. You know a set of metrics that interest you and a dataset:
   `selectedMetricsOnDataset` will run all metrics that are valid for a column
   on each of the columns and also run dataset metrics on the dataset.
3. You know a set of metrics and a specific column that these metrics should be
   run for. This is the most specific case that you can use if you really know
   what you want: Use `selectedMetricsOnColumn` and be aware that it will only
   run metrics that are valid for the type of the column.
4. `allMetricsOnColumn` can be used to run all appropriate metrics on a single
   column. This behaves much like `allMetricsOnDataset` and uses the same
   heuristics.

Mergulho decides what metrics to run on which column mainly based on the type
of data contained in that column. There are however three heuristics in place
to adjust that behavior:

1. If a column name ends in `__id`, Mergulho will treat it as a dimension even
   if it contains numbers.
2. If a column is not nullable, no null-checks are run. This is deferred to our
   syntactic checks in the ETL.
3. If a numeric column has less than `CUTOFF` values in it (low cardinality),
   it is considered a dimension column where the category levels are expressed
   as numbers. The current `CUTOFF` is set at `20`.

## Current deployment state

Mergulho code is in [Itaipu](https://github.com/nubank/itaipu). The
metrics described above are collected daily at each run and then
stored in [Escafandro](https://github.com/nubank/escafandro).

## Roadmap

Currently, we are running Mergulho on more and more datasets to
observe if and how it scales. The plan is to have it running on all
contract tables and all tables that stakeholders ask us about. If
scaling works well, we will add automatic running of metrics to the
`ContractOps` and also add mechanisms for other `SparkOps`. For these
datasets, we then perform [a set of anomaly
checks](https://github.com/nubank/itaipu/blob/master/common-etl/src/main/scala/common_etl/evaluator/steps/mergulho/DatasetSelector.scala).

The result of these checks are published in Slack. Currently, the
message is posted on [the #etl-integrity-checks
channel](https://nubank.slack.com/archives/CGBLGLYFK) through Splunk.

Another direction of progress is the extension of the set of metrics as well as
sanity checks based on the metrics.

## I want Mergulho run on my data

If you want Mergulho to be run on your data, you need to open a PR
againts [Itaipu](https://github.com/nubank/itaipu). In particular, you
will need to add an entry to [the
`DataseSelector.defaultWhitelist`](https://github.com/nubank/itaipu/blob/master/common-etl/src/main/scala/common_etl/evaluator/steps/mergulho/DatasetSelector.scala)
like the following:

```
"<dataset name>" -> AnomalyChecks(Set(<check1, check2, ...>), <LogWarning | FailHard>)
```

for example:

```scala
"nu-br/core-alpha/credit-card-billing-cycles" -> AnomalyChecks(Set(IncreasingRowCountChecker), LogWarning)
```

If you as a stakeholder have needs/suggestions for extending Mergulho
to make it helpful for you, feel free to contact data infra. For
example, you can suggest new metrics or to send us a PR with the newly
proposed metrics for review.

## Resources

Here is a link to a
[talk](https://docs.google.com/presentation/d/1EVG6_zpc_79txV-CB4Jr5L0zV-_-JFzryQlbSekC8ic/edit#slide=id.p)
I gave in the Data Tribe all-hands about mergulho. Note that you need
access to the data tribe shared drive to access this.
