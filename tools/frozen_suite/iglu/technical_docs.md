---
owner: "#squad-analytics-productivity"
---

# Iglu Technical Docs

Iglu (blueprint and factory).
Iglu is a tool used to generate quality tables in an efficient and modular way.
It is particularly efficient for big, wide and denormalized tables.
It uses concepts from Kimball related to dimensions and facts and
applies those to generate snapshot tables.

Iglu is divided into a

- **Declarative layer**, which is used to mount dimensions and facts
(these are mainly the traits used to create a star schema (**blueprint**)
- **Pipeline**, which reads from the declarative layer and creates tables (SparkOps) from it (**factory**)

The interface on how to use Iglu is under migration,
the legacy way of defining the declarative part of Iglu used to be done
accessing Iglu classes directly, and the code for this interface can be found here
(<https://github.com/nubank/itaipu/tree/master/src/main/scala/etl/warehouse/inuit>),
and an example of its implementation can be found here
(<https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/br/core/dimensions/customer/CustomerDimension.scala>).

The new way of accessing Iglu is through Ice Mold + proper attribute tagging.
That is, in order to define which attributes will compose a dimension,
users must declare Attributes in Ice Mold, and tag them with the Dimension tag.
The code for this interface can be found here
(<https://github.com/nubank/itaipu/tree/master/src/main/scala/etl/warehouse/iglu>)
and an implementation of this new interface can be found here
(<https://github.com/nubank/itaipu/tree/master/src/main/scala/nu/data/mx/core/v2>).

## Dimensional Modeling Tool Concepts

### DimensionTables

Dimension tables are the main entities that provide structure to a data mart. They are related to the main
entities on a given business area, and, simply put, consist of a list of attributes and some metadata.
Dimensions are also the abstractions responsible for consolidating and centralizing documentation and logic in an attribute level.
You can read more
about dimensions in [Kimball](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/dimension-table-structure#).

Here at Nubank, we can also automatically create snapshot tables from dimensions, a daily snapshot and a current snapshot, which are basically the
states of the dimensions every day and on the last ETL run, respectively (the snapshots are taken on time 23:59:59.999999).

### FactTables _(SparkOp with DeclaredDimensionalModel)_

Fact tables are tables associated with a given grain and a given business process (you can read more about then in [Kimball](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/fact-table-structure).
Facts are usually also connected to a dimension table, for instance, a fact table with a line per credit card purchase can be connected to a Customer dimension, to a Date dimension, etc, as in a star schema (you can read more about star schemas [here](https://en.wikipedia.org/wiki/Star_schema)).

When implementing a SparkOp with DeclaredDimensionalModel, you must also define the following:

```scala
def grain: Grain                                  // e.g.: OneRowPer("customer__id", "date")
def businessProcess: BusinessProcess              // e.g.: BusinessProcess("purchase-event")
def connections: Seq[NuFactToDimensionConnection] // e.g.: override def connections: Seq[NuFactToDimensionConnection] = Seq(
                                                  //      ConnectionBuilder.connectToCurrentState(CustomerDimension, AttributeSelector.All, joinKey = "customer__id"))
def denormalizeMode: DenormalizeMode              // e.g.: DenormalizeMode.Off
```

Please also refer to [DeclaredDimensionalModel](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/DeclaredDimensionalModel.scala).

### EAVTs and Resolvers

Dimension tables consist of a collection of attributes plus some metadata.
The attributes ("customer__name", "customer__limit", etc) from a dimension receive data from resolvers.
EAVT is the DataFrame schema used to feed resolvers with data.
A DataFrame in EAVT schema contains the following columns:

|   | E  | A  | V  |  T |
|---|---|---|---|---|
| type  |  string | string  |  array(string)* |   timestamp|
|  description |  entity identifier (e.g.: customer__id) |  name of the attribute (e.g.: customer__name) | value of the attriubte (e.g.: "John Doe")  |  timestamp in which that value started being valid for that entity |

\*we require V to be an array of strings since we support attributes with array types

Example of an EAVT DataFrame:

| E  | A  | V  |  T |
|---|---|---|---|
|   d0199b1a-f3dc-4024-b7ad-951d336f49c3 | customer__name  |  [John Do] |   2020-01-01 10:05:23|
|   d0199b1a-f3dc-4024-b7ad-951d336f49c3 | customer__name  |  [John Doe] |   2020-01-01 10:10:04|
|   3c96db7b-8683-424a-ab41-219c1494f11c | customer__name  |  [Janie Do] |   2020-01-10 23:15:30|
|   3c96db7b-8683-424a-ab41-219c1494f11c | customer__name  |  [Janie Doe] |   2020-01-11 01:15:12|
|   3c96db7b-8683-424a-ab41-219c1494f11c | customer__highest_purchase_value  |  [3500.0] |   2020-01-14 03:11:22|
|   3c96db7b-8683-424a-ab41-219c1494f11c | customer__highest_purchase_value  |  [4933.12] |   2020-04-29 13:00:04|
|   d0199b1a-f3dc-4024-b7ad-951d336f49c3 | customer__tags  |  [new_customer] |   2020-01-14 03:11:22|
|   d0199b1a-f3dc-4024-b7ad-951d336f49c3 | customer__tags  |  null |   2020-01-20 03:11:22|
|   d0199b1a-f3dc-4024-b7ad-951d336f49c3 | customer__tags  |  [old_customer, nubanker] |   2020-01-20 03:11:24|

There is a very useful function called generateEAVT which helps conforming a DataFrame into the EAVT schema:

```scala
import nubank.iglu.infra.spark.ResolverUtils.generateEAVT

val df: DataFrame = ...

generateEAVT(
    df,                                   // DataFrame
    $"customer__id"                       // E column
    "customer__highest_purchase_value",   // A name
    $"customer__highest_purchase_value",  // V column
    $"purchase_timestamp"                 // T column
)
```

- The value for the attribute is considered valid from the moment it is set until the moment it is overwritten by a new one
- When creating an EAVT dataframe, be aware that it should be valid for every timestamp

```scala
import common_etl.implicits._
import nu.data.br.dbcontracts.customers.entities.Customers
import nu.data.infra.api.datasets.v1.Names
import nubank.iglu.core.EventLogRow
import nubank.iglu.infra.spark.{CustomResolver, DefinitionParams, ResolverUtils}
import org.apache.spark.sql.Dataset

object CustomerPrototypeResolver extends CustomResolver {
  val customerIdHistName: String = Names.entityAttributeHistory(Customers, "customer__id")
  
  def inputs: Set[String]        = Set(customerIdHistName)
  def definition(params: DefinitionParams): Dataset[EventLogRow] = {
    val df = params.datasets(customerIdHistName)
      .select($"customer__id", $"prototype" as "customer__prototype", $"db__tx_instant")
      .distinct
    val prototypeEAVT =
      ResolverUtils.generateEAVT(
        df,
        $"customer__id",
        "customer__prototype",
        $"customer__prototype",
        $"db__tx_instant"
      )
    prototypeEAVT
  }
}
```
