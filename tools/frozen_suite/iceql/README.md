---
owner: "#squad-analytics-productivity"
---

# IceQL

## Introduction

IceQL is a query builder with a GraphQL-like interface, used to query attributes created using Ice Mold. 
Users interact with IceQL by using the ConsumerAPI, where they provide a list of **givens** (which attributes they have, ex: customer__id), 
and a list of **targets** (which attributes they want to fetch, ex: customer__dob, customer__status). 
Under the hood, IceQL finds the path to get the attributes needed (Scheduler), and for each segment of the path does a 'LEFT JOIN' (Traverser) adding things to the final result.

## What problem does IceQL solve?
The idea of IceQL came from finding a solution to two conflicting goals: having a single-source-of-truth without a single-point-of-failure for the ETL.
- Single source-of-truth: same consistent definitions throughout the ETL with coherent naming convention. Redundant information reduced.
- Stable and reliable DAG: attributes are can be calculated in parallel across different tables, which avoids having a single point of failure in the ETL.

## What is IceQL?
IceQL is a tool that allows to easily query attributes defined in Ice Mold. 
IceMold is a metadata tool that enables Nubankers to define attributes and attributes connections 
with a name, a documentation, type, tags and a query code on how this attribute should be calculated.

On IceQL we read Attributes and Attribute Connections from IceMold to grab the definitions (queries) for each attribute.

IceQL provides all the "back-end" needed to perform queries on top of its data structure 
(e.g., answers questions such as "How can I get from `customer` to `credit card limit`"). 

The "front-end", which is the interface where users can pull attributes to their SparkOps is called "Consumer API". 
The API basically consists of functions (such as `.pullAttributes` and `fetchAttributes` 
that can be used alongside your normal Spark SQL DataFrame functions to get the attributes you need inside your SparkOp.


## How do I use IceQL?

To get started with IceQL please refer to the [GUIDE](GUIDE.md), where we'll walk through the most common use cases for IceQL.

## FAQ
1 - How do I check the query that IceQL is doing for me?

_There's no current way of doing it. 
The idea of IceQL is exactly abstracting from the user the necessary query to get to an attribute. 
For the person using iceQL on their SparkOp, the only thing that needs to be considered is the attributes you have and the attributes you want to pull. 
The definitions for each attribute will be defined on the data catalog but the way to get from your given attributes to the target attributes is taken care of by iceQL._

2 - When should I use IceQL?    
_Whenever it is available and fits your use case._

3 - Why use IceQL?  
_IceQL avoids that your SparkOp completely fails to calculate if one of its input fails.
It helps alignment of attributes definitions across Nubank
as attributes are unique an contains lots of metadata.
And finally, IceQL is able to optimize queries from the ConsumerAPI used in the SparkOp, 
making our DAG more efficient._

4 - How does a regular SparkOp compare with a SparkOp using IceQL?  
_In terms of coding, it abstracts business logic and implementation details.
If the path has been paved to an attribute (i.e. it is connected by an attribute connection) 
you can build a query by calling attributes names without having to rewrite the spark logic to reach them._
