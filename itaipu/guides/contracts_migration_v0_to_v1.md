# Contracts Migration - V0 to V1 (AKA Multi-Country Contracts)

On `common-datomic` version `5.42.2` the capability of generating contracts for multiple countries was added, including the following changes:

- use `nu.data.infra.api.dbcontracts.v1` as base for contracts generation.
- package structure changed from `contract.etl` to `nu.data.infra.{country}.dbcontracts`
- Documentation in all fields and contracts is now **required**
- non-optional fields in the `DatomicEntity` data structure
- the function `gen-helpers/generate-contracts!` now accepts a country as an argument.


## Upgrading contracts to V1

### Step 1: Bump common-datomic and update generate contracts function

[Reference PR][1]

- Bump `common-datomic` on the clojure service to a version >= `5.42.2`
- Update the [main function][2] in `contract/contract_main.clj` to accept `country` as a parameter.
- Update the test function in `db/datomic/config_test.clj` to include the service's country
  - For services in multiple countries duplicate this line for each country.
- Delete the old contracts from `resources/contract`

### Step 2: Generate new contracts using nucli
- Pull the latest `nucli` version: `nu proj update nucli`
- Run the command, for each country:
  - `nu dev sync-itaipu-contracts <service> --country <country>`

### Step 3: Changes on Itaipu - Delete existing contract from Itaipu and create a new DatabaseContract

[Reference PR][4]

- Delete old contracts from `src/main/scala/etl/contract/{service_name}`
- Create a new `DatabaseContract` that includes the entities generated in the previous step, the entities are generated on `src/main/scala/nu/data/{country}/dbcontracts/{service_name}/entities`. [Example][5]
- Add the `DatabaseContract` to the respective Country's list of the databases. [Example][6]

### Step 4: Migrate references to the old contract

- Replace in path `etl.contract.{service_name}` with `nu.data.br.dbcontracts.{service_name}.entities`
- Run `sbt clean compile` to ensure everything is compiling.
- *Non-standard imports might required manual changes.*


### Common Migrations

When migrating you might face some compilation errors by using the V1 api, those are simple changes like the ones below, they involve changing the usage of a deprecated function to its up to date version.

- `DatabaseContractOps.lookup(Entity.historyEntity("attribute_name")).name` -> `Names.entityAttributeHistory(Entity, "attribute_name")`
- `PIILookupTable.opName(Employees, "employee__customer_id")` -> `Names.piiLookup(Employees, "employee__customer_id")`




[1]: https://github.com/nubank/metapod/pull/365/files
[2]: https://github.com/nubank/metapod/pull/365/files#diff-75982a7c03f1fa94300796c6649430a4R6
[3]: https://github.com/nubank/metapod/pull/365/files#diff-925b3593e886902ddc596b82072b6c62R5
[4]: https://github.com/nubank/itaipu/pull/6299
[5]: https://github.com/nubank/itaipu/pull/6299/files#diff-2e9855c468c7e57c2c4376cd090df220R10
[6]: https://github.com/nubank/itaipu/pull/6299/files#diff-1cd94cecc13a02d4f603ca213f6e3f7cR9
