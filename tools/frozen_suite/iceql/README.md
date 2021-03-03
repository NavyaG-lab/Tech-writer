---
owner: "#squad-analytics-productivity"
---

# IceQL

## Introduction

IceQL is a query builder with a GraphQL-like interface, 
used to query attributes created using Ice Mold. 
Users interact with IceQL by using the ConsumerAPI, 
where they provide a list of **givens** (which attributes they have, ex: customer__id), 
and a list of **targets** (which attributes they want to fetch, 
ex: customer__dob, customer__status). 
Under the hood, IceQL finds the path to get the attributes needed (Scheduler), 
and for each segment of the path does a 'LEFT JOIN' (Traverser) adding things to the final result.
