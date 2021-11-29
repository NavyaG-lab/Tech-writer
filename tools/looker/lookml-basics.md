---
owner: "#squad-analytics-productivity"
---

# LookML Basics

This document describes the basic concepts and processes involved in the creation of LookML-based Explores, Looks and Dashboards.
For a more in-depth coverage, there is plenty of documentation available at [docs.looker.com](https://docs.looker.com/data-modeling/learning-lookml/lookml-intro)

## Summary

- [What is LookML?](#what-is-lookml)
- [LookML Project Organization](#lookml-project-organization)
- [Main Concepts](#main-concepts)
- [Creating an Explore Page](#creating-an-explore-page)
- [Code Examples](#code-examples)
- [Best Practices](#best-practices)

## What is LookML

> LookML is a _language_ for describing dimensions, aggregates, calculations and data relationships in a SQL database. Looker uses a model written in LookML to construct SQL queries against a particular database.

LookML creates an abstraction for the underlying SQL queries and enables powerful data modeling: creation of new dimensions, relationships, advanced filters and calculations.

To edit LookML files, it is necessary to have access to the [development mode](#main-concepts).

## LookML Project Organization

A LookML **Project** is a version-controlled collection of files that describe how Looker will interact with a database. The two main file types in a project are **models** and **views**.

#### Models

A *.model* file specifies how Looker will connect to a database. As a best practice, it is also where Explore pages are defined (more on that [below](#3-exposing-views-through-explores))

#### Views

A *.view* file contains information on how Looker will interpret tables (or derived tables) from the database. A `view` parameter inside a view file references a specific table (or derived table) and defines its fields as **dimensions** and **measures**.

## Main Concepts

**Dimension:** field which is a context descriptor, it can be used to filter query results, and also give "break levels".

**Measure:** field that uses a SQL aggregate function (e.g. COUNT, SUM, AVG). Measures are the way results are gathered when combined with Dimension. In a SQL query context, measures would be the "Aggregate" (and dimensions would be the fields in the "Group By" clause).

**Development Mode:** To edit LookML files, it is necessary to have access to development mode and it must be enabled. In this mode, changes occur in a [development branch](https://en.wikipedia.org/wiki/Branching_(version_control)), separated from the production branch (*master*). This way, changes can be tested in an isolated environment, not affecting the users using Looker in the production environment. Behind the scenes, Looker is using a traditional git repository to track changes in branches.

## Creating an Explore Page

Looker users can interact with data in a point-and-click fashion by using Explore pages. The first step in creating these pages is defining `views`. Those views should be linked to a `model`. The last step is exposing the view(s) to users in an Explore page. This is done by using `explore` parameters. All these steps are detailed below:

### 1. Creating a view file

Before you start your view creation, make sure you are in development mode. To do that, open *"Develop"* in the upper bar. Then click on *"Development Mode"* to turn it on. A purple bar should appear at the top of the page.

**Creating your view:** First click in *"Develop"* -> *"Manage LookML Projects"*

Select a project. (Example: `belomonte_custom_queries`, which is the default project for Nubank Brazil LookML creation)

Once inside a project, on the left side you'll see a vertical bar containing the project's files and folders.
Select the folder in which you want to build a new view.
Click on the three points in the right side of the folder's name.

Now you have two options of starting your view creation:

- You can choose to open a clean file and write all the content of the view by yourself (*"Create View"*).
- Or you can choose to use a table to autogenerate a simple view, and modify just what you want (*"Create View From Table"*).

Let's proceed by using a table as a base:

Click on *"Create View From Table"*.
Then select the table you want to use as a base to your view.
Go to the end of the page, and click *"Create Views"*.
Now you have a simple view code, which you can edit, include more Dimensions, Measures etc.

A simple code example is shown [below](#view-example).

### 2. Making sure the view file is included in a model

A view must be included in a `model`. To add/check this, open the model file to which you'd like to link your view and check the include parameters. For example:

```
include: *.view
include: SpecificSubfolder/*.view
```

In the example above, all views in the same folder as the model will be included, and also all views in the SpecificSubfolder. More details on path and wildcards syntax [here](https://docs.looker.com/data-modeling/getting-started/ide-folders).

(In `belomonte_custom_queries` project, the default model is `connection_custom_queries.model`)

### 3. Exposing views through Explores

The last step is to make your view available in an Explore Page. Those are created through the `explore` parameter.

In the model file, add an explore containing your view (e.g. `explore: transactions_example { }`) and optional joins to other views. A more detailed code example is provided [below](#explore-example).

Explores could also be defined inside the `.view` file. In fact, most of LookML code written in Nubank has the explore clause inside the view file. This alternative has the benefits of more compartmentalized code.

Once your modifications are saved, you can search for the recently created Explore by clicking on "Explore" in the upper bar.

### 4. Deploying views to production

Once you've completed all previous steps and think your views are ready to be shared, you nedd to deploy it to production.

With your project and branch select, click in `Validate LookUML` and wait the validation proccess.

So click in `Commit Changes & Push` then select files and type a message to commit, finally click in `Merge & Deploy to Prod` to deploy your views to production.

PS: If you are using `belomonte_custom_queries` project, before validating your views you have to pull the last changes of `belomonte` project. Check [known issues](looker-known-issues.md) for more information.

## Code Examples

### View Example

Suppose we have a table `dataset.transactions_example` in the Data Warehouse, with columns `transaction_id`, `customer_id`, `date` and `transaction_amount`. In this case, the contents of a view file could be as follows:

```
view: transactions_example {
  sql_table_name: dataset.transactions_example;;
  
  dimension: transaction_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.transaction_id ;;
  }

  dimension: customer_id {
    type: string
    sql: ${TABLE}.customer_id ;;
  }

  dimension_group: date {
    description: "The day when the transaction occurred"
    type: time
    timeframes: [
      raw,
      date,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.date ;;
  }

  measure: transaction_amount {
    description: "The transaction amount in R$"
    type: sum
    sql: ${TABLE}.transaction_amount ;;
  }
  
  measure: number_of_unique_customers {
    type: count_distinct
    sql: ${customer_id} ;;
  }
  
}
```

Every view is defined by a [view parameter](https://docs.looker.com/reference/view-params/view?version=7.4&lookml=new) and its underlying parameters:

```
view: view_name { ... }
```

In our example, the `view_name` is *transactions_example*. The view name must be an unique identifier. If changed, it will break all Looks and Dashboards that depend on it (the displayed name can still be changed without introducing problems by using the [label](https://docs.looker.com/reference/view-params/label?version=7.4&lookml=new) parameter inside the view).

The underlying view parameters used in the example are: `sql_table_name`, `dimension`, `dimension_group` and `measure`.

When editing a LookML file, a **very useful context-specific help** will be available on the right side of the screen. If the cursor is placed in a `view`, all the possible parameters that can be used in a view will be displayed, with a link to the documentation explaining how they work and how to use them. Similarly, if the cursor is placed in any other parameter, such as a `dimension` inside the view, all of the possible parameters that can be used in the dimension block will be displayed.

The `sql_table_name` parameter specifies the table that will be used by this view (in Nubank, this means `contract.table1`, `dataset.table2` etc.)

In our hypothetical table, we have three fields that we would like to represent as dimensions (`transaction_id`, `account_id` and `date`) and one field we would like to represent as a measure (`transaction_amount`).

#### Dimensions

The syntax of a **dimension** with a couple parameters is simple:<br>
```dimension: dimension_name { <dimension parameters> }```<br>
The dimension [type](https://docs.looker.com/reference/field-reference/dimension-type-reference) is given by its `type` parameter.<br>
The `sql` parameter takes any valid SQL to select a column. These statements generally contain Looker's substitution operator. For example, `${TABLE}.transaction_id` references a column *transaction_id* in the table that is connected to the view (in this case, `dataset.transactions_example`).

The `date` field in our table is not defined with a `dimension` parameter but rather a `dimension_group`. This permits the creation of several time-based dimensions at the same time, so that from a single date input, the user can have direct access to the timeframes specified in the `timeframes` parameter.

#### Measures

For **measures**, their [types](https://docs.looker.com/reference/field-reference/measure-type-reference) are are usually SQL aggregation functions. In our example, SUM represents the total amount we would like to get when grouped by any dimension.

We could create more dimensions or measures derived from the four columns or other dimensions and measures. In the code, a `number_of_unique_customer` measure was created with count_distinct type, referencing the customer_id. This enables us to get the number of customers doing transactions by date, for example.<br>
Notice that in the sql parameter, we used `${customer_id}` (a LookML dimension defined above) instead of `${TABLE}.customer_id` (the column named *customer_id* in the table). Both will give the same results, but the advantage of the first is that, if the sql definition of the `customer_id` dimension changes, it will be reflected automatically in the measure.

### Explore Example

The `explore` parameter creates Explore pages, enabling users to interact with the dimensions and measures defined inside a LooML view. A possible explore declaration is as follows:

```
explore: transactions_example {
  group_label: "BR - LookML Playbook"
  join: customers {
    sql_on: ${transactions_example.customer__id} = ${customers.customer__id} ;;
    type: left_outer
    relationship: many_to_one
  }
}
```

In the code above, the view `transactions_example` is being added to the Explore.

The `join` parameter may be used to add dimensions and measures from other views. In the example, we are joining `transactions_example` with `customers`. By doing so, if the `customers` view contains a *city* dimension it would be possible to obtain transaction amounts (from the `transactions_example` view) as a function of customer city (from the `customers` view).<br>
Like in any SQL join, we must declare the join type and conditions. In addition, the [relationship](https://docs.looker.com/reference/explore-params/relationship) between views is necessary for accurate measure calculations.

The use of a `group_label` facilitates organization of explores.

## Best Practices

- Only one `view` (table) should be declared in each view file. The `explore` should be declared in a model file. This enhances view discoverability and enables creation of multiple explores referencing a same view.
- Looker's substitution operators should be used whenever possible in the `sql` parameter.
- Ideally we should always specify what is the primary key on the corresponding dimension
- When creating Explore Pages for other users, follow [these recommendations](https://help.looker.com/hc/en-us/articles/360001766908-Best-Practice-Create-a-Positive-Experience-for-Looker-Users).
