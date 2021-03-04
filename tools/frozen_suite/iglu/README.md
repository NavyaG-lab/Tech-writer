---
owner: "#squad-analytics-productivity"
---

# Iglu

Iglu library is a collection of abstractions that helps us to do Dimensional Modeling right.
The focus is on composability: defining logic in small chunks 
and allowing the developer to lazily combine them into dimension and fact tables. 
Materialize as you see fit.

You can read more about iglu on its own [README](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/iglu/README.md) and also in the [technical docs](technical_docs.md) file.

## Background

We've seen in the past that the first dimensional modeling abstraction at Nubank was unsuccessful.

A few architectural mishaps are accountable for that:

1. The necessity for atomic deployments because of non-deterministic surrogatekeys. 
Check out this [ADR](https://github.com/nubank/data-infra-adr/blob/master/adr/adr-003.md) for more information.

2. Ever increasing complexity centered into a few SparkOps:
one for each dimension and fact.
When a single SparkOp has to encompass all information related to an entity,
it becomes very hard to understand all the transformations applied to each attribute.
Here are a few examples:
[legacy prospect dimension](https://github.com/nubank/itaipu/blob/7bf0b570442245af5a1bf9ade256f60c9dcf0f15/src/main/scala/etl/dataset/dimension/ProspectDimension.scala)
and [legacy credit card account dimension](https://github.com/nubank/itaipu/blob/5681bf800dece6ff69699fd4cab732f261779e15/src/main/scala/etl/dataset/dimension/CreditCardAccountDimension.scala).
They are massive and hard to understand.
Especially because they contain certain DM patterns like slowly changing dimensions.

3. Dimensions were not conforming i.e.
they were not designed in a way such that attributes have consistency across different dimensions.
This goes against best practices for an effective data governance in our business.

This library addresses these mishaps.
First, it kills the need for atomic deployment 
by encouraging denormalizing dimensions into the fact tables that they relate to.
As an added bonus, denormalized tables give great query performance on distributed
data processing tools like Databricks
and BigQuery---[Google Recommends](https://cloud.google.com/solutions/bigquery-data-warehouse).

Also, it's possible to denormalize dimensions into each other,
which addresses the the conforming dimensions issue
and guarantees attributes are consistent across dimensions.


Second, you'll find the traits `DimensionAttribute`
and `TableAttribute` that accept metadata for a maximum of one column;
and the trait Resolver,
that allow you to isolate each attribute's logic
and assemble it to a fact or dimension.

This should prevent exploding complexity like we've seen in the first shot
at a DM abstraction and keeps logic nicely isolated.

## Why use it?
Due to the growing need of Data Governance in Nubank,
Dimensional Modeling appears as a compelling solution.

By using Iglu, the tables you create on your domain will have more structure
in an underlying skeleton of dimensions and facts, 
which also contribute to a more centralized centralized analytics environment,
favoring documentation and shared concepts between tables.

It also provides a place for additional metadata and consistency checks,
which force contributors to more often think about the relationships between their tables in a broader sense.

In summary:

- Iglu gives the ability to connect
and denormalize dimensions reinforces sharing business concepts between teams (or even inside a team) 
as well as reuse data
- The traits that compose this abstraction favors data organization,documentation
and enables a variety of integrity checks to be made to a guaranty data consistency and quality
- The abstraction works with EAVT Logs which enables the generation of daily snapshots 
making historical data easy to be used for analytical purposes

## How to use it?

The implementation of Iglu in Nubank is described on this 
[document](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/iglu/README.md)

## Elements of Iglu
### DataMart
A data mart is a subset of tables in a data warehouse,
usually containing data from a specific business line.

In Iglu's DataMart you can define which fact tables
and dimension tables are contained in your data mart
and what type of relationship they have.

When establishing a connection,
Iglu gives the power of pulling attributes from one table into another (moredetails below).
Plus it has a series of checks to help in data governance
such as avoiding repeated attribute names.


### DimensionTables
Dimension tables are the main entities that provide structure to a data mart.
They are related to the main
entities on a given business area,
and, simply put, consist of a list of attributes
and some metadata.

Dimensions are also the abstractions responsible for consolidating
and centralizing documentation
and logic in an attribute level.
You can read more
about dimensions in [Kimball](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/dimension-table-structure#).

### FactTables
Fact tables are tables associated with a given grain
and a given business process (you can read more about then in [Kimball](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/fact-table-structure).
Facts are usually also connected to a dimension table,
for instance, a fact table with a line per credit card purchase can be connected 
to a Customer dimension,
to a Date dimension, etc,
as in a star schema (you can read more about star schemas [here](https://en.wikipedia.org/wiki/Star_schema)).

### TableConnection
The connections allow you to denormalize dimensions into facts
or dimensions into other dimensions.
This is where you define *how* your table connects to a dimension
or how a dimension connects to another one.

For that, you must define what is the RelationshipType between your table
and the dimension (OneToOne, ManyToOne, OneToMany, ManyToMany),
and which attributes are used to connect to it.
You can connect both a dimension to another dimension
or a dimension to a fact table.
In this case you have to define which attributes (columns) you want to pull from the dimension into your SparkOp,
using the AttributeSelector.

### Snapshots
Snapshots are a possibility of materialization for the DimensionTables.
The use of EventLogRows (rows in an [EAVT schema](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/inuit/README.md#eavts-and-resolvers)) 
allows not only a temporal connection of a dimension to a fact 
but also the generation of **daily snapshots**,
which provides a handy daily history of the data in the dimensions.
Plus there are the **current snapshots**,
which contain is a snapshot of the most recent data.


### Metadata
Iglu provides a variety of traits that allow your Data Mart to have a rich source of metadata
and guarantee that important business definitions are in place.
As example: for each DataMart,
it generates a BusMatrix -- a table with general information about the data mart.

Plus, tables must have explicit definition of grain, primary key and description 
while attributes must have description, data type and changing type.
