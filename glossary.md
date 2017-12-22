# Glossary

Work-in-progress, please add placeholders or info as you come across new terminology

* [Data infrastructure terms](#data-infrastructure-terms)
* [Microservice structure and hexagonal architecture terms](#microservice-structure-and-hexagonal-architecture-terms)
* [General infrastructure terms](#general-infrastructure-terms)

## Data infrastructure terms

## Microservice structure and hexagonal architecture terms

### schemas
At Nubank we've found it very useful to annotate functions with schemas, which offer runtime guarantees that the input and output of functions conform to specific structures.
Generally we use [prismatic schema](https://github.com/plumatic/schema) (a.k.a. plumatic schema), but `clojure.spec` is becoming popular with some squads.
Schema validation isn't turned on in production, but is enforced in postman and e2e tests. Validation can be enabled in unit tests via `schema.core/with-fn-validation`.

Global schemas (a.k.a. wires) are stored in [`common-schemata`](https://github.com/nubank/common-schemata) and used to coordinate the structure of http and kafka data payloads.
Internal schemas are generally generated from models ([for example](https://github.com/nubank/papers-please/blob/7a67b7f6e52ed949ca46cfc9f3d1b3cadb26f53e/src/papers_please/models/verification_request.clj#L23-L26)), but can be found in other places in a service.

### interceptors
Middleware code that validates if the client can access that scope (have the right permissions, or that the payload they are sending is in the correct format or even if it has some specific key-value)

### service.clj
Defines the HTTP API that will be exposed to the outside world. HTTP url endpoint generally have _interceptors_ attached to them. Each HTTP handler should have a schema, so that invalid data sent by clients connecting into this entry will not be forwarded to code and behave in unexpected ways.

### diplomat
Is a nubank specific term and is an abstraction over "the outside world". It is responsible to wire the ports in the hexagonal architecture.
* diplomat/consumer.clj, contains code responsible for consuming kafka topics. Invokes adapter and controller code. Exceptions thrown during message consumption will result in deadletters
* diplomat/producer.clj, produces kafka messages to topics.
* diplomat/http_in.clj, contains handlers used in by HTTP entry points defined in `service.clj`. Some older or smaller services put their handler code directly in `service.clj`
* diplomat/http_out.clj, contains logic to make outgoing HTTP requests.

### adapters
Transform data that came from the outside world into beautiful EDN (Clojure maps with keywords as keys). It can just delegate into a schema (trying to coerce the data) or it can transform data into the schema (e.g., an SQL query that returns data that we'll convert into maps with the correct types). External wire schemas are nested, while internal model schemas are flat to be more easily stored in databases, so adapters will convert between these formats.

For example, given the following data:

```clojure
;; external wire data:
{:account
  {:id   #uuid 9b0f2622-0bb0-47b5-b5d5-ea08ccaa6555
   :name "Bob Harper"}}
;; internal model data:
{:account/id   #uuid 9b0f2622-0bb0-47b5-b5d5-ea08ccaa6555
 :account/name "Bob Harper"}
```

you might see the `my-new-service.adapters.account/wire->internal` adapter function convert from a nested external wire to the flat internal model, and `my-new-service.adapters.account/internal->wire` convert in the reverse direction.

### controllers
Route the data that came from diplomats into another source. For instance, save something into DB or route to another service via a diplomat. Controllers should not have core business logic in them - they are only "routers". They should assume that data is already converted by adapters. Exceptions should be raised in the controller level. In general testing controllers at the unit level requires a lot of mocking, and should hence be avoided because updating those tests to match code changes is labor intensive. Instead, controller code should be tested via postman integration tests.

### logic
Contains simple pure functions, without side-effects, that make any changes into data, or transformations, or anything, that is necessary for the correct working of the other functions.
These must be tested in a complete way - no mocks or stubs, no side-effects, etc.
Ideally they shouldn't raise exceptions, which can be avoided by using [either monad](https://github.com/nubank/nu-algebraic-data-types#either-type).

### models
Are schemas for representing data internally ([example](https://github.com/nubank/papers-please/blob/master/src/papers_please/models/verification_request.clj)). Generally these models are used to define datomic schemas, but you can have models that aren't stored persistently. It is important to only use these schemas within the service, so that the internal model can evolve independently of external models shared across services. Shared external schemas should be stored in the `common-schemata` repository.
Models store persistently in datomic must be registered in `db/datomic/config.clj` ([example](https://github.com/nubank/papers-please/blob/master/src/papers_please/db/datomic/config.clj#L14-L19))

### db
Contains read, write, and migration logic for persistent data. Most commonly you will see something of the form `db/datomic/<a-model>.clj` like `db/datomic/account.clj`, but there can also be other types of databases like `dynamodb` or `influx`.

### components.clj
Defines the service's [components](https://github.com/stuartsierra/component) for different environments (e.g. test, e2e, prod, staging...). Components (e.g. HTTP client, datomic client, redis client) are used when certain logic needs to manage or depend on mutateable state. Components are made available to incoming diplomat handlers, for instance, handlers in http_in or consumers have access to things like the datomic or HTTP components, and pass them down to the controller level for general use.

### `test/` unit-tests
Unit tests written in mostly `Midje`, and at times `clojure.test`.

### postman tests
Integration tests inside the service. These tests are backed by `Midje` but adhere to a `world` centric model. More details [here](https://github.com/nubank/common-test/#postman)

### resources/my-new-service_config.json.base
JSON configuration file which is merged/overridden by the environment where the service is running (e2e, prod, staging). It generally contains:

 * Business level configurations (e.g. number of days to wait for something)
 * List of Kafka topics produced, consumed with other specific configuration
 * URL bookmarks for endpoint on other services (internal and external)
 * Components configuration: circuit breaker, datomic url/password/database, redis host and port...

### bookmarks

## General infrastructure terms

### Prototype / Shard

### Environment

### Stack

### Region

