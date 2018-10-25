# Glossary

Work-in-progress, please add placeholders or info as you come across new terminology

* [Data infrastructure terms](#data-infrastructure-terms)
* [General infrastructure terms](#general-infrastructure-terms)

## Data infrastructure terms

#### transaction

A **metapod transaction** is a concept present in metapod, which is composed by a set of datasets and it's used to group those together in a logical semantic unit, such as a daily batch of data consumed and processed.

#### dataset

It is essentially a piece of data in a table-like structure.

It is usually, but not always, accompanied by metadata associated with it, such as the date (e.g. when it was produced, consumed, persisted, committed, or copied), where to find (e.g. S3 path) it and a name (e.g. `bills-past-due`). Services such as `metapod` can also track the schema for a dataset and any other metadata about it.

#### schema

The specification of some logical data structure, such as an event, a dataset, a Clojure map, etc. It can be used to set expectations of what the structure looks like (e.g. fields/columns and their types and length) and also to validate a given structure of the data. It is used pervasively across many different contexts.

For more info, see: https://github.com/nubank/playbooks/blob/master/docs/glossary.md#schemas

#### Permanence of a dataset

Datasets are marked as either `ephemeral` or `permanent`, and this dictacts what s3 bucket we place them in.
Ephemeral s3 buckets are configured to delete files that are over ~2 weeks old, while permantent datasets are kept forever

## General infrastructure terms

### Prototype / Shard

### Environment

### Stack

### Region

