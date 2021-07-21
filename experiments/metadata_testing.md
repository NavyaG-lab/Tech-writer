---
owner: "#squad-analytics-productivity"
---

# Fighting Data Complexity by Enhancing Metadata

1. [Project Context](#project-context)
    1. [Available data assets](#available-data-assets)
    1. [Why are we enhancing metadata?](#why-are-we-enhancing-metadata)
        1. [Metrics](#metrics)
1. [Definition of the experiment](#definition-of-the-experiment)
    1. [Goals](#goals)
    1. [Non Goals](#non-goals)
    1. [Approach](#approach)
        1. [How can this test enhance metadata description?](#how-can-this-test-enhance-metadata-description)
        1. [How will we measure success?](#how-will-we-measure-success)
        1. [What to do when the test has been triggered?](#what-to-do-when-the-test-has-been-triggered)  
    
<a id="project-context"></a>
## Project Context

The quick and almost frictionless growth of datasets increased the number of datasets from nearly 30k in July/2020 to up to 87k by the moment this document was written in July/2021. There's also been observed from Data Surveys frequent low scores about Finding, Understanding, and Trusting data. On top of that, recently internal studies with Nubankers focused on *Understanding and Trusting data* showed numerous difficulties on finding and using trustworthy data in the decision-making process. For more context, check the sources in [interview notes](https://drive.google.com/drive/folders/170t3HpCmQqRsrZRqFaQdTPZyFgkSp1R6) and [historical gathered data and details of the deep-dive in the problems](https://docs.google.com/spreadsheets/d/1_zCOVzIfZOsppe-9Z_Q33IxZHr-GNciqNxzB0scv6oo/edit).

In our analysis, we categorize the problems into 3 possible areas of actuation and their relation to data usage:

1. [**Available data assets**](#available-data-assets): regarding the data assets being shown
1. Data literacy and knowledge: regarding previous / current knowledge to act on data tasks
1. Supplied Tooling: regarding the tools currently available for users

We will only be focusing in *Available Data Assets* which is the objective of this test, but one can [check the entire analysis](https://docs.google.com/document/d/1FeoUy9UdU-6r1LHPFnLFlCHYkTyW-SFdBCFGrgWtE8k).

<a id="available-data-assets"></a>
### Available data assets
We divide the issues related to the available data assets into the following categories:
1. **Lack of quality metadata** → Many datasets lack descriptions and other metadata that helps their understanding. The sole names of the datasets and columns aren't enough to make them understandable.
1. Inconsistent data → There are many names for the same thing and also many different concepts with the same name, and this makes it difficult to understand the tables and to know the right datasets to choose for specific use cases.
1. Some datasets don't reflect what's happening in Production → Sometimes what you get on production is not what you see in the analytical environment, or it's very hard to recreate. One example we heard is the customer invoices. This makes it hard to trust data.

The test described here is designed to address the problem of *[Lack of Quality Metadata](#why-are-we-enhancing-metadata)*, by focusing on *[Enhancing Metadata](#why-are-we-enhancing-metadata)*. If you need more context regarding other categories, feel free to [check the entire analysis](https://docs.google.com/document/d/1FeoUy9UdU-6r1LHPFnLFlCHYkTyW-SFdBCFGrgWtE8k).

<a id="why-are-we-enhancing-metadata"></a>
### Why are we enhancing metadata?

Out of the subset of problems cited in *[Available Data Assets](#available-data-assets)* we have envisioned the lack of quality metadata as one of the main offenders for relying on datasets. This feedback was also gathered in our [interview notes](https://drive.google.com/drive/folders/170t3HpCmQqRsrZRqFaQdTPZyFgkSp1R6). In addition to that, we have seen an increasing amount of datasets being committed without attribute descriptions. According to [this analysis](https://nubank.cloud.databricks.com/#notebook/12304115/command/12636295), 4904 datasets have all attributes without descriptions and 14689 datasets contain at least 50% attributes without descriptions. The most recent snapshot of our metadata metrics is shown on the table below.

<a id="metrics"></a>
#### Metrics

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />
<col  class="org-left" />
<col  class="org-left" />
</colgroup>

<thead>
<tr>

<th scope="col" class="org-left">Analysis<sup><a id="fnr.1" class="footref" href="#fn.1">1</a></sup></th>
<th scope="col" class="org-left"># Datasets</th>
<th scope="col" class="org-left"># Attributes</th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">Total Datasets</td>
<td class="org-left">86,680</td>
<td class="org-left"></td>

</tr>


<tr>
<td class="org-left">Datasets disconsidered in this analysis (without Declared Schema)</td>
<td class="org-left">-30,794</td>
<td class="org-left"></td>
</tr>


<tr>
<td class="org-left">Datasets eligible (SparkOp with Declared Schema)</td>
<td class="org-left">55,886</td>
<td class="org-left">1,060,876</td> 
</tr>


<tr>
<td class="org-left">Datasets without at least one missing attribute</td>
<td class="org-left">-17,477</td>
<td class="org-left">-775,302</td>
</tr>

<tr>
<td class="org-left">Datasets with at least one missing attribute</td>
<td class="org-left">38,352</td>
<td class="org-left">291,153</td>
</tr>
   
<tr>
<td class="org-left">Datasets with all attributes without description</td>
<td class="org-left">4,904</td>
<td class="org-left"></td>
</tr>

<tr>
<td class="org-left">Datasets with at least half attributes without description</td>
<td class="org-left">14,689</td>
<td class="org-left"></td>
</tr>

</tbody>
</table>
<sup><a id="fn.1" href="#fnr.1">1</a></sup> <a href="https://nubank.cloud.databricks.com/#notebook/12304115/">Full Analysis</a>

<a id="definition-of-the-experiment"></a>
## Definition of the experiment

<a id="goals"></a>
### Goals
The goal of this experiment is to reduce the number of datasets that miss attribute descriptions created AFTER the release of this test. We expect users to notice their brand new datasets are missing attribute descriptions, and fix this issue by adding descriptions for them. This way we increase the quality of our metadata, and indirectly, the discoverability of their datasets.

<a id="non-goals"></a>
### Non Goals
With this experiment we do NOT want to backfill descriptions of the datasets that are already running in the ETL, only prevent the creation of new ones.

<a id="approach"></a>
### Approach

<a id="how-can-this-test-enhance-metadata-description"></a>
#### How can this test enhance metadata description?
By creating a non required test, we will let the users know that they are creating datasets that miss attribute descriptions. We will provide a deadline to analyse its results, and if the impact is still far from expected, we will be able to rollout the test into a required one.

<a id="how-will-we-measure-success"></a>
#### How will we measure success?
The metrics regarding datasets without description are going to be tracked through the `dataset/spark-op-declared-schemas` and its archived version. Ideally, we want to keep as near the baseline as possible, so all the newly created SparkOps will have their attribute descriptions filled.

<a id="what-to-do-when-the-test-has-been-triggered"></a>
#### What to do when the test has been triggered?
If the test has been triggered, go back into your SparkOp and add the description in the fields that you've forgotten.
