---
owner: "#squad-analytics-productivity"
---

# Guide

As of now, Ice Mold is a passive layer of data modeling, 
which means that we have created the tools to create models inside it, 
but there is still no way to properly consume the modeling information from it (WIP). 
The tools available here refer to how to increment our data model in terms of adding attributes, 
adding connections between attributes, 
tagging attributes and linking connections between attributes to SparkOps.

### Creating a new attribute

A new attribute can be created by using the trait NuAttribute:

```scala
  object CustomerName extends NuAttribute {
    override def name: String             = "customer__name"
    override def logicalType: LogicalType = LogicalType.StringType
    override def tags: Set[Tag]           = Set(Tag.Core, Tag.PersonalData)
    override def description: String      = "Full name of the customer"
  }
```

- Attributes represent **nodes** in our graph model

- Names are unique, and they should be prefixed by a namespace if 
your attribute has a restricted application 
(ex: `aml/customer__status`).
Core attributes don't need any namespacing.

- A LogicalType is related to the metapod data type for that given attribute. 
Some examples: IntegerType, DoubleType, ArrayType(StringType), UUIDType.

- Tags are a collection of tags that can be attributed to a given attribute. 
The current list of available tags can be found 
[here](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/gelinho/Tag.scala). 
Examples: Core, PersonalData, PII, Dimension, Fact, etc.

- Remember to add very complete descriptions, 
which should make reusing an attribute simple and clear.

### Creating a new tag

Tags are usually created to add business related metadata to a given attribute. 
Creating a new tag can be done by using the trait Tag:

```scala
case object PII extends Tag {
  override def name: String = "pii"
  override def description: String =
    "Tag used to mark PII attributes."
}
```

- Be very descriptive on your tags and make sure they are easily discoverable 
by using good documentation and names

### Creating a new resolver

Creating a new resolver can be done by using the trait NuResolver:

```scala
  case object ProspectIdToName {
    override def from: Set[NuAttribute] = Set(ProspectAttributesV2.ProspectIdAttribute)
    override def to: Set[NuAttribute]   = Set(ProspectAttributesV2.NameAttribute)
  }
```

- Resolvers represent **edges** in our graph model
- They are used to link semantically two sets of attributes
- In order to link resolvers to transformations, refer to the section below

### Linking a resolver to a SparkOp

In order to link a resolver to a table (SparkOp), 
one must extend the trait Transformation, as in:

```scala
  case object ProspectIdToName extends NuResolver with Transformation {
    override def from: Set[NuAttribute] = Set(ProspectAttributesV2.ProspectIdAttribute)
    override def to: Set[NuAttribute]   = Set(ProspectAttributesV2.NameAttribute)
    override def source(params: ExecutionParams): SparkOp = YourSparkOp
    override def sourceSchema: Schema = Schema.Tabular
  }
```
 
- If your SparkOp uses any execution parameter such as TargetDate and ReferenceDate, 
you can access those values inside the ExecutionParams argument

- sourceSchema indicates the schema of the table where the link between the attributes exist. 
For tabular representations, where attribute names are columnar, refer to Schema.Tabular, 
for EAVT representations, refer to Schema.EAVT.
