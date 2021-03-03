---
owner: "#squad-analytics-productivity"
---

# Iglu

You can read more about iglu on its own [README](https://github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/iglu/README.md).

Iglu library is a collection of abstractions that helps us to do Dimensional Modeling right.
The focus is on composability: defining logic in small chunks 
and allowing the developer to lazily combine them into dimension and fact tables. 
Materialize as you see fit.

## Using Iglu on Itaipu

Here at Nubank we use dimensional modeling mainly to tackle the following problems:

- It is hard to share business concepts between teams (or even inside a team)
- It is hard to find and trust data
- It is hard to reuse datasets and guarantee their quality
