---
owner: "#squad-analytics-productivity"
---
# Ice Mold
<p align="center">
  <em>A metadata tool to map attributes and connections in Nubank as a graph model.
  </em>
</p>

## What problem does Ice Mold solve?
- There's a growing need for a single-source-of-truth for attributes and metrics in Nubank;
- We need to have a clear calculation logic linked to every metric;
- It helps define and collect metadata for discoverability and platform management

## What is IceMold?
IceMold is a layer of data modeling, i.e. a place to catalog data and their relations, 
that can ease up data consumption in Itaipu by providing metadata, tags, descriptions.
The intention is to decouple business definitions and metadata
from practical implementations of data manipulation, which are defined by SparkOps.

---

**This is a summarised version of the official Ice Mold documentation.
The complete version, with more context and guides can be found [here](https://www.github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/ice_mold/README.md)  in Itaipu.**

For a step by step approch use the [GUIDE](https://www.github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/ice_mold/GUIDE.md).

To get more context on use cases, see our [Ice Mold user stories](user_stories.md).
