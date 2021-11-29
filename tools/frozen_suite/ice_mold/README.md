---
owner: "#squad-analytics-productivity"
---

# Ice Mold

A tool to create graph data models inside Nubank
(with a heavy inspiration on [RDF](https://workingontologist.org/) and
[Abrams](https://github.com/nubank/abrams)),
which should bring a lot of value in terms of data governance,
internationalization and long-term stability.

## What problem does Ice Mold solve

- There's a growing need for a single-source-of-truth for attributes and metrics in Nubank;
- We need to have a clear calculation logic linked to every metric;
- It helps define and collect metadata for discoverability and platform management

## What is Ice Mold

Ice Mold is a tool used to create a graph data model,
i.e. a tool used to create nodes (attributes), edges (attribute connections),
that can ease up data consumption in Itaipu by providing a central and flexible
environment for data modeling, attribute tagging and additional metadata.
The intention is to decouple business definitions and metadata
from practical implementations of data manipulation, which are defined by SparkOps.

Ice Mold is a passive layer meant to provide the abstractions needed to model data.
If you want to understand how Ice Mold communicates with the other systems from the Frozen Suite,
refer to our [systems overview](../README.md).

---

**This is a summarised version of the official Ice Mold documentation.
The complete version, with more context and guides can be found
[here](https://www.github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/ice_mold/README.md)  in Itaipu.**

For a step by step approch use the
[GUIDE](https://www.github.com/nubank/itaipu/blob/master/src/main/scala/etl/warehouse/ice_mold/GUIDE.md).

To get more context on use cases, see our [Ice Mold user stories](../user_stories.md).
