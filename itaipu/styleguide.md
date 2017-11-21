# Itaipu styleguide and troubleshooting

## What to do at the "KeyIntegrity" / dataset layer
* Choose a clear grain and stick to it - if you are picking a canonical account for a customer, that should go into the customer key integrity table. Key integrity tables should probably have a similar row count to the underlying contract table, with the exception of filtering corrupt rows.
* Selecting a canonical entity from many possible matches from a 1:N relationship
* Tricky joins to other tables with 1:N relationships
* Filtering corrupt rows
* Canonical calculated columns relevant for predictive models and dimensions alike
* Drop contract style prefixes for new fields added (e.g., `delivered_at` instead of `card__delivered_at`)
* Add `debug__` column to elucidate choices made when selecting canonical / counting associated things, etc
* Explodes
* Retain nulls - no need to fill everything with "N/A"
* Don't join in and replicate unimproved contract columns (aside from primary keys) - they'll get joined in elsewhere (likely at the dimension level)

## What to do at the "Dimension" layer
* Truncate enum values to remove the prefix
* Drop contract style prefixes for all columns
* Fill in nulls with "N/A" for string columns
* Add a surrogate key
* Add a sentinel indicator and "missing row"
* Add slowly changing columns as appropriate
* Binning numeric values into categories
* Converting PII into approximate versions of PII (e.g., approximate age)
* Flatten out 1:1 relationships where they can be models as additional dimension columns rather than new dimensions

## What to do at the "Fact" layer
* Refer to one or many surrogate keys to do joins (do not reference UUID primary keys unless as debug)
* Have a numeric column (unless it's a factless fact table that only establishes a relationship between dimension rows)
* Include time lag calculations for date/time columns

## Using strings vs. references to columns and datasets
Because column names and dataset names are tested in the Itaipu integration test, always use the more readable string (e.g., `"dataset/prospect-key-integrity"`) rather than direct references between classes (e.g., `ProspectKeyIntegrity.name`). As an added bonus, this makes iteration in Databricks much easier.

## UDFs
A UDF cannot depend on a `def` - it must always depend on a `val` (and this applies transitively). This is commonly the cause of "Task not serializable" on DataBricks. Alternatively, extending Serializable may fix this problem. You may get the same error message if you create a UDF that depends on Clojure libraries, such as [here](https://github.com/nubank/itaipu/blob/0a89b218ce894afd51dbd66f4184de846207a6f5/src/main/scala/etl/dataset/BillingCycles.scala#L113).

## Dot or not dot syntax
Use the "SQL style" syntax with parentheses but no dots ONLY in the definition of a SparkOp. In small transformation defs, use the dot syntax.

## Pivots
Pivoting without explicitly specifying the possible values of the pivot column cannot work in the context of the "fake" query plan test, because the test doesn't have any values. So downstream manipulation of the columns resulting from a pivot will appear to be invalid due to the "missing" columns.

## Structuring SparkOps
Prefer a structure where definition contains minimal logic - just a simple pipeline of transforms with a select at the end which explicitly whitelists the expected output columns. Don't test the definition directly on a unit basis, but test it via a real DataBricks run. Test each transform function individually in unit tests.

## Transform Test Granularity
Unit test every function that is explicitly called from a definition. Avoid transform functions for trivial joins. It's ok to have private defs that are not unit tested as long as they are not directly referenced from definition, and this is preferable to having a proliferation of trivial transforms (given the verbosity of unit tests is similar for trivial and non-trivial transformations).

## Unit Test Style
Create each input dataframe using a `Seq` of tuples followed by a `.toDF` to provide column names. Create separate vals for `expected` and `result`. Prefer selecting only the relevant primary key column and new or modified columns from the result, so you only need to type these columns for the expected (this also helps with future test maintenance).

## Troubleshooting Tests
* Q: What does `java.lang.ClassNotFoundException: <refinement>` represent?
  * A: This usually means that you have a `Some(x)` or `None` value in a column, and a naked "string" value in the same column when constructing a dataframe with `.toDF`
* Q: What does `java.lang.NoClassDefFoundError: no Java class corresponding to Product with Serializable found` represent?
  * A: This usually means that you are trying to create a dataframe, and some tuples (rows) have more columns than others
