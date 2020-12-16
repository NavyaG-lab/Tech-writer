---
owner: "#squad-analytics-productivity"
---

# Ice Mold Use Cases

The idea of this document is to imagine some real use cases for the tools we are building, 
and thinking on how users would use our products to solve them. 
Attribute and squad names are not important here.

## Use Case 1

**Problem:** An analyst is building a SparkOp for themself. 
On their dataset, they already have the column `customer__id`, 
but they need to have a column `active_customer` 
and they don't know where this information lives

**Solution:** Analyst should look for the `active_customer` metric on Ice Mold, 
and use the IceQL API to pull this attribute to their SparkOp. 

**Behind the scenes:** In order for this to work, 
we need to have the attribute defined on Ice Mold + a connection (with transformation) 
that goes from `customer__id` to `active_customer` (directly or not, e.g., 
if we have a connection from `customer__id` to `cpf` and from `cpf` to `active_customer`, 
this should also work). 
The Analyst won't know what specific tables are going to be used as an input to their SparkOp, 
since this will be decided by IceQL

## Use Case 2

**Problem:** An Analytics Engineer from Credit Card is having some troubles 
with the `share_of_wallet` attribute. There are two SparkOps, 
owned by two different analysts, that contain this metric, 
but the values don't match. 
It's not immediately clear why that is, 
because the logic is inside a convoluted query on SparkOp. 
The Analytics Engineer needs to help the analysts to always have the same result.

**Solution:** The Analytics Engineer will create a new attribute on Iglu 
called `share_of_wallet`. After talking with the analysts to understand the conceptual definition 
of the metric, the engineer will create a connection from `credit_card_account__id` to `share_of_wallet` 
and add the correct transformation. 
Then, the Engineer will talk with the Analysts and tell them that 
they don't need to have the logic on their SparkOps anymore: 
They should just use the IceQL API.

**Behind the scenes:** One bonus of the Ice Mold approach is also the fact that, 
if someone don't have a `credit_card_account__id` but they have a `customer__id` 
(and the Ice Mold already contains a connection from `customer__id` to 
`credit_card_account__id`), they will also be able to pull this attribute 
(without needing to know how do I go from customer to credit card account).

## Use Case 3

**Problem:** You are an Analyst from the Credit Card BU, 
and someone asks you how you get the number of transactions from a credit card. 
You explain to them that you need to union `contract/A` with `contract/B` 
and filter out some types of transactions. 
This person will spread this information to other analysts, 
and then suddenly there are dozens of SparkOps depending on those contracts 
using this logic. Time passes and the engineering team decides to deprecate `contract/A` 
and `contract/B` and use a new `contract/C` with different columns. 
Alongside that, the filter of transaction types also has changed. 
It will be really hard to change the subsequent SparkOps now! 
How would you prevent this in the future?

**Solution:** The analyst, instead of explaining the inputs 
and the query to get to the `number_of_transactions` attribute, 
could have added this attribute and their respective connections to Ice Mold. 
If they did that, there would be no problem for the subsequent SparkOps! 
Logic would be updated on the Data Catalog and propagated to all dependent SparkOps.

**Behind the scenes:** You could argue that this same objective could've been achieved 
if they created a SparkOp with this metric, and then the other analysts would depend on 
this SparkOp. Although it's true that it would work, 
experience shows that over time this creates a really crazy DAG where it's not uncommon 
to see 20+ layers of dependencies that are hard to be aware of. 
Also, this approach creates huge "points of failure" for the ETL, 
and evolving those central SparkOps becomes a hard challenge. 
Ice Mold + IceQL provides a "clear way" from the contracts to your SparkOp, 
while taking care of necessary dependencies and 'inner layers' 
(e. g., creating intermediary SparkOps for performance reasons)
