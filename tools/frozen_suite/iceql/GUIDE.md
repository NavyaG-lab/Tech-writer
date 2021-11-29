---
owner: "#squad-analytics-productivity"
---

# Guide

We are going to walk through the two most common use cases to use the **IceQL Consumer API** in a SparkOp:

A) When you pull attributes into an existing query  
B) When you want to query attributes from zero

As an example, we are going to consider the case of an user that wants to "pull" `customer name`, `credit card account limit` and `savings account status` related to a `savings account id` using the IceQL ConsumerAPI.

## Before we start

### Browsing through Ice Mold attibutes

Before start coding, the user can go to [this dashboard](https://nubank.looker.com/dashboards-next/4384)
and browse the attributes catalogued and connected in Ice Mold.
To be able to query an attribute, first it needs to exist inside Ice Mold
and secondly, it has to be connected to other attributes through Spark SQL queries (i.e. SparkOps).

There, the user can see that (you can picture it like a graph with nodes and edges):

- `savings account id` is connected to: `customer id`, `savings account status`
- `customer id` is connected to: `customer name`, `credit card account id`
- `credit card account id` is connected to: `credit card account limit`

All attributes are cataloged and connected, therefore they can be used in the SparkOp. Otherwise,
the missing attributes would have to be added to Ice Mold.

To know more about **Ice Mold** and how you can catalog and connect your own attributes,
check [Ice Mold's doc](https://github.com/nubank/itaipu/tree/master/src/main/scala/etl/warehouse/ice_mold).

## Using IceQL Consumer API inside a SparkOp

#### A) When you pull attributes into an existing query

#### Scenario

Lets say an user, Elsa, has a DataFrame with all savings accounts that were created in 2020.
She then wants to get `customer name`, `credit card account limit` and `savings account status` related to
those savings account.

This is how her SparkOp looks now:

```scala
imports ...

object MyCoolSparkOp extends SparkOp {
  override def name: String      = "dataset/my-cool-sparkop"
  override def country: Country  = Country.BR
  override val inputs: Set[String] = Set(savingsAccountDatasetName)
  override def definition(datasets: Map[String, DataFrame]): DataFrame = {
     datasets(savingsAccountDatasetName)
     .filter(year($"savings_account__created_at") == 2020)
  }
}
```

#### Imports

Now, to use the API a few imports are needed:

````scala
import etl.warehouse.iceql.{ConsumerAPI, NuContext}
import nubank.iceql.core.{Attribute => IceQLAttribute}
````

We rename the Attribute import to IceQLAttribute so it doesn't get mixed up with Metapod Attributes in case you are using them.

#### Instantiating the Consumer API in the SparkOp

To define the ConsumerAPI from a query, 3 parameters are needed:

- **given**: Set of attributes used as starting point. In this case, the `savings account id`;
- **targets**: Set of attributes to be pulled.
Elsa needs `customer name`, `credit card account limit` and `savings account status`
- **context**: Which collection of attributes should be used as source of data.
Currently we only have one set for each country, so don't mind this for now.
The context has to passed as a parameter to the SparkOp.

After Elsa has defined those parameters, her SparkOp should look like this:

```scala
imports ...

  case class MyCoolSparkOp(context: NuContext) extends SparkOp {
  override def name: String      = "dataset/my-cool-sparkop"
  override def country: Country  = Country.BR
  override val inputs: Set[String] = Set(savingsAccountDatasetName) ++ api.inputs
  
  private val given = Set(IceQLAttribute("savings_account__id"))

  private val targets = Set(IceQLAttribute("customer__name"),
                            IceQLAttribute("credit_card_account__limit"),
                            IceQLAttribute("savings_account__status"))
  
  private lazy val api = ConsumerAPI(given, targets, context)

  override def definition(datasets: Map[String, DataFrame]): DataFrame = {
    import api.AttributePuller

    datasets(savingsAccountDatasetName)
    .filter(year($"savings_account__created_at") == 2020)
    .select("savings_account__id")
    .pullAttributes(datasets)
  }
}
````

A few things are important to be noted:

1. The SparkOp now needs to receive a context, so it needs to be a case class (or a class).
This is done so IceQL knows the attributes available;
2. The inputs have to receive `++ api.inputs` this is used to allow IceQL adequate inputs
to fulfill the "pullAtributes" needs;
3. `given`, `targets` and `api` are a `lazy val`.
This is because we only want those to be evaluated when this SparkOp is being calculated;
4. Inside the definition, `api.AttributePuller` has to be imported. This is done so we're able to use implicits

#### Setting up the package file

Now the SparkOp needs to receive a context of type NuContext. The SparkOp's package file should be like this:

```scala
import nu.data.<country>.core.CoreData
import common_etl.RunParams
import etl.warehouse.iceql.NuContext
import etl.warehouse.inuit.ExecutionParamsBuilder

package object my_package {
  def allOps(params: RunParams): Seq[SparkOp with DeclaredSchema] = {
    val context = NuContext(CoreData.resolvers(params), ExecutionParamsBuilder.fromRunParams(params))
    Seq(
       MyCoolSparkOp(context),
       MyOtherCoolSparkOp(params.referenceDate))
  }
}
````

If you have to use the reference date (or target date), it can still be accessed with `params.referenceDate`.  

#### B) When you want to query attributes from zero

Another user, Frozone wants to get the same attributes
**for the same collection of savings accounts** but he starting his SparkOp from zero.
The steps to be followed are nearly the same and his SparkOp should be something like this:

```scala
imports ...

  case class MyColdSparkOp(context: NuContext) extends SparkOp {
  override def name: String      = "dataset/my-cold-sparkop"
  ovedrride def country: Country  = Country.BR
  override val inputs: Set[String] = api.inputs
  
  private val given = Set(IceQLAttribute("savings_account__id"))

  private val targets = Set(IceQLAttribute("customer__name"),
                            IceQLAttribute("savings_account__created_at"),
                            IceQLAttribute("credit_card_account__limit"),
                            IceQLAttribute("savings_account__status"))
  
  private lazy val api = ConsumerAPI(given, targets, context)

  override def definition(datasets: Map[String, DataFrame]): DataFrame = {
    import api.AttributePuller

    api.fetch(datasets)
    .filter(year($"savings_account__created_at") == 2020)
    .drop("savings_account__created_at")
  }
}
````

Note that:

1. Frozone's SparkOp is going to output the same data as Elsa's
2. His inputs depend only on the API

#### More questions

Reach us out in #squad-analytics-productivity in Slack.
