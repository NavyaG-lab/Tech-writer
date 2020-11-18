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

Start by checking our [coordination-spreadsheet][10] for the initiative. Pick a
service (or multiple if you want to do batches). It pays off if it is a service
owned by your team or a service where you understand the business logic. But if
no such service is available, just pick any. It's not super-important. Put your
name next to it to indicate you are working on it.

### Step 1: Bump common-datomic and update generate contracts function

First and foremost, create your own branch:
`git checkout -b migrate-contracts-v1`

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

- Copy the entities from the service to the correct place in itaipu:

```sh
cd $NU_HOME
cp -r {service_name}/resources/nu/data/br/dbcontracts/{service_name}  itaipu/src/main/scala/nu/data/br/dbcontracts/
```

- Create a new `DatabaseContract` that includes the entities generated in the previous step, the entities are generated on `src/main/scala/nu/data/{country}/dbcontracts/{service_name}/entities`. [Example][5]
- Add the `DatabaseContract` to the respective Country's list of the databases. [Example][6]: I mostly copy one from another contract and simply adjust it.
- PS: Remember to add a `private [country]` to your `DatabaseContract` definition, that will make importing the right country easier.
- PS2: Remember to override the `prototypes` val to the prototypes where the service run in each country. To check which prototypes the service is used in, check definition: `https://github.com/nubank/definition/blob/master/resources/br/services/{service_name}`. Check out the options available at `nu.data.infra.Prototypes`. [Example][7]

NOTE: squad can be inferred from the old contracts

- Delete old contracts from `src/main/scala/etl/contract/{service_name}`:
    - always use intellij's safe delete which will show you all the references
        in the codebase. This allows you to do step4 straight-away


### Step 4: Migrate references to the old contract

- Replace in path `etl.contract.{service_name}` with `nu.data.br.dbcontracts.{service_name}.entities`
- Do common-migrations listed below
- Run `sbt clean compile` to ensure everything is compiling or build in
    intellij.
- *Non-standard imports might require manual changes.*: In my experience, they
    usually do. Check the examples below.

### Step 5: Create a PR for the service

Create a PR with all the changes you have made to the service files. Probably,
you'll have to run `lein lint-fix` in order to pass the tests. Running the
tests themselves with `lein test` is also often a good idea as they check the
contracts as well one more time. Then it's time for one more commit and
creating a service PR.

It is often a good idea to explicitly notify owners of the service via slack.
Finding the channel isn't always easy. `[squad-name]-eng` often exists. If none
can be found, I resort to writing to frequent contributors in person. Here is
the message template i use:

```
Bom dia pessoal,
:reviewplease: data infra is migrating old contracts from v0 to v1 to get rid of outdated code pre-dating multi-country. I have migrated this service: https://github.com/nubank/[your PR here].
The corresponding itaipu PR will be merged tomorrow, but the PR's don't need to be merged in sync. This just keeps the service up-to-date with the contracts that are being used from now on. Could someone review and merge?

Also: The new contracts require all fields to be equipped with a docstring.  Where we couldn't provide a useful docstring we have filled in a dummy value.  If you find the time or if it bugs you, we would be delighted if you could fill the correct information into the docstrings.
Obrigado
```

Make sure you list your PR in the [coordination-spreadsheet][10] and mark it
green once it goes through.


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
[10]: https://docs.google.com/spreadsheets/d/1qeL1DDeETuGSAXvEfarqfBytRFNR-JlrdqBwRfZmFRc/edit#gid=0
