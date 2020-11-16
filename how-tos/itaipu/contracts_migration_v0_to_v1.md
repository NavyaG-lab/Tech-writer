---
owner: "#data-infra"
---

# Contracts Migration - V0 to V1 (AKA Multi-Country Contracts)

On `common-datomic` version `5.44.2` the capability of generating contracts for multiple countries was added, including the following changes:

- use `nu.data.infra.api.dbcontracts.v1` as base for contracts generation.
- package structure changed from `contract.etl` to `nu.data.{country}.dbcontracts`
- `etl.contract` package structure remains unchanged (e.g. `etl.contract.DatabaseContractOps`)
- Documentation in all fields and contracts is now **required**
- non-optional fields in the `DatomicEntity` data structure
- the function `gen-helpers/generate-contracts!` now accepts a country as an argument.


## Upgrading contracts to V1

### Step 1: Bump common-datomic and update generate contracts function

[Reference PR][1]

- Bump `common-datomic` on the clojure service to a version >= `5.44.2`:
NOTE: Should not be necessary since we have a bot that bumps libs to the newest
version, but double-check:

NOTE: next 2 points: The exact place sometimes differs from the one described
here. Maybe you need to search a bit.
- Update the [main function][2] in `contract/contract_main.clj` to accept `country` as a parameter.

```clojure
(defn -main [country & args]
  (let [country' (keyword country)]
  (s/with-fn-validation
    (gen-helpers/generate-contracts! db/db-name db/contract-skeletons country'))))
```

- Update the test function in `db/datomic/config_test.clj` to include the service's country
  - For services in multiple countries duplicate this line for each country.

```clojure
(test-helpers/enforce-contracts! db/db-name db/contract-skeletons :br)
```

- Delete the old contracts from `resources`:

```sh
cd $NU_HOME/{service_name}
rm -rf resources/contract
```


### Step 2: Generate new contracts in the service

- run `lein gen-contracts br`

Potential problems:
- you cannot pull the libraries/jars to run the clojure command:
  `nu aws credentials refresh`
- `ERROR: Missing documentation for contract CardInterests`:
  The skeletons that the contracts are generated for are not documented. All
  fields need a `:doc` key and value in their map. The entire contract needs a
  doc like this:

```clojure
(def skeleton ^{:contract/doc "Dummy: Service owner needs to update this"} ...)
```

=> If you don't know how to fill the fields, always use the above `Dummy:...`
filler from the example. We will create a PR with this to the service owners
anyways. They can either fix this themselves or leave it. That shouldn't block
us.


### Step 3: Changes on Itaipu - Delete existing contract from Itaipu and create a new DatabaseContract

[Reference PR][4]

- The usual: Pull itaipu master, create new branch

```sh
cd $NU_HOME/itaipu/
git pull master
git checkout -b {your_name}/upgrade-{service_name}-contracts
```

- Delete old contracts from `src/main/scala/etl/contract/{service_name}`
- Copy the entities from the service to the correct place in itaipu:

```sh
cd $NU_HOME
cp -r {service_name}/resources/nu/data/br/dbcontracts/*  itaipu/src/main/scala/nu/data/br/dbcontracts/
```

- Create a new `DatabaseContract` that includes the entities generated in the previous step, the entities are generated on `src/main/scala/nu/data/{country}/dbcontracts/{service_name}/entities`. [Example][5]
- Add the `DatabaseContract` to the respective Country's list of the databases. [Example][6]
- PS: Remember to add a `private [country]` to your `DatabaseContract` definition, that will make importing the right country easier.
- PS2: Remember to override the `prototypes` val to the prototypes where the service run in each country. To check which prototypes the service is used in, check definition: `https://github.com/nubank/definition/blob/master/resources/br/services/{service_name}`. Check out the options available at `nu.data.infra.Prototypes`. [Example][7]
- PS3: After oppening a PR, remember to ask each code owner to make the necessary communication to the teams that might be affected by this change.

- TODO: check out what to do about schemaOnlyDatabases.

### Step 4: Migrate references to the old contract

- Replace in path `etl.contract.{service_name}` with `nu.data.br.dbcontracts.{service_name}.entities`
- Run `sbt clean compile` to ensure everything is compiling or build in
    intellij.
- *Non-standard imports might require manual changes.*: In my experience, they
    usually do. Check the examples below.


### Common Migrations

When migrating you might face some compilation errors by using the V1 api, those are simple changes like the ones below, they involve changing the usage of a deprecated function to its up to date version.

- `DatabaseContractOps.lookup(Entity.historyEntity("attribute_name")).name` -> `Names.entityAttributeHistory(Entity, "attribute_name")`
- `PIILookupTable.opName(Employees, "employee__customer_id")` -> `Names.piiLookup(Employees, "employee__customer_id")`
- `DatabaseContractOps.lookup(Entity).name` -> `Names.contract(Entity)`

### More Examples

- [Migrating CCLedgerMX, Maat, Mordor][8]
- [Migrating Aloka][9]



[1]: https://github.com/nubank/metapod/pull/365/files
[2]: https://github.com/nubank/metapod/pull/365/files#diff-75982a7c03f1fa94300796c6649430a4R6
[3]: https://github.com/nubank/metapod/pull/365/files#diff-925b3593e886902ddc596b82072b6c62R5
[4]: https://github.com/nubank/itaipu/pull/6299
[5]: https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/mx/dbcontracts/aloka/Aloka.scala
[6]: https://github.com/nubank/itaipu/blob/master/src/main/scala/nu/data/mx/dbcontracts/V1.scala#L11
[7]: https://github.com/nubank/itaipu/pull/6483/files#diff-1f2479d5d9b07a1866c38d182c6b24a6R34
[8]: https://github.com/nubank/itaipu/pull/6483/
[9]: https://github.com/nubank/itaipu/pull/6481/
