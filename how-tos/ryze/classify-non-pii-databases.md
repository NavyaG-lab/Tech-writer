---
owner: "#data-protection"
---

# Classifying non PII data in bulk

This process is based on a parameterized file placed on `resources/configs/non-pii-prefixes.edn`. 
There you can configure the prefixes of the databases that should be automatically classified without PII.

The `non-pii-prefixes.edn` will look like the following sample:

```clojure
{:data-sources-prefixes [{:country     "br"
                          :datasources [{:dataset-series [{:prefix      "prometl-"
                                                           :description ""},
                                                          {:prefix      "dataset-continuous-auditing-"
                                                           :description ""},
                                                          {:prefix      "dataset-kpi-"
                                                           :description ""}]},
                                        {:datomic []}]},
                         {:country     "mx"
                          :datasources [{:dataset-series [{:prefix      "prometl-"
                                                           :description ""},
                                                          {:prefix      "dataset-continuous-auditing-"
                                                           :description ""},
                                                          {:prefix      "dataset-kpi-"
                                                           :description ""}]},
                                        {:datomic []}]},
                         {:country     "co"
                          :datasources [{:dataset-series [{:prefix      "prometl-"
                                                           :description ""},
                                                          {:prefix      "dataset-continuous-auditing-"
                                                           :description ""},
                                                          {:prefix      "dataset-kpi-"
                                                           :description ""}]},
                                        {:datomic []}]}]}

```

### Details about each key:

- `:country`- The country where you want to find the databases
- `:datasources` - The data sources where you want to find the databases (datomic, dataset-series, etc)
    - `:prefix` - The name that will match with the start of the database name
    - `:description` - Some description about the prefix

It is important to emphasize that the prefixes correspond to the beginning of the database name and not to what is included in the name.

**Example:**
```
Prefix: test-
database name: test-database
match: true

Prefix: test-
database name: database-test-name
match: false
```

### Running the command

Finishing the parameterization of the prefixes of the data sources we are ready to execute the classification command.
We need to execute the command by country, as shown below:

```clj
lein classify-non-pii {country}
```

The available countries is `br`, `co` and `mx`

This process will find all databases based on parameterized prefixes and that don't have the classification
(or the entire classification) done.
In the databases found, we include the tag `:na` in all the attributes that contain the tag `nil`.

Is good to know that all the attributes already classified do not have any effect with this automatic classification.

All databases automatically classified will generate an output log in the console:

```clj
Country: br Datasource: dataset-series Database: dataset-continuous-auditing-evidence-collector-atento-skipped-jobs
```

## Classification hints

For tips on candidate databases that are unlikely to store PII data and do not have the classification done,
you can run this command:

```clj
lein classify-non-pii-hints {country}
```

This process is based on a static prefixed list containing keywords that we think should not have pii data:

```clojure
(def ^:private non-pii-hints ["logs" "kafka" "k8s" "prometl" "kube" "kpi"])
```

This command will generate a log with the path of the candidate database schemas found:

```clj
resources/br/dataset-series/bigquery-logs-test-3/schema-5e98a306-0326-4206-b408-750455919842.edn
resources/br/dataset-series/bigquery-logs-test-2/schema-5e975eb4-4f43-47a6-ad4e-2f63cd35fcee.edn
resources/br/dataset-series/internal-audit-jira-work-logs/schema-60357c95-966a-4f41-99dd-74ac8308908a.edn
resources/br/dataset-series/dataset-collections-lending-ab-logs-union/schema-5f9decde-a355-410d-8458-775803054efb.edn
resources/br/dataset-series/dataset-collections-lending-ab-logs-union/schema-609d763e-0f94-4290-9ed1-7e8a28455b8b.edn
resources/br/datomic/diablo/retrieve-money-transaction.kafka.edn
```

It is important to emphasize that this command only list databases that do not have the classification done and is very
important to check each one of them and do the manual classification until understand if they can be a prefix
inside the configuration to automatic classification.
