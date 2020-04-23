# Onboarding Exercise Part II: Creating a service to expose a dataset via API

The goal of this exercise is to make you familiar with Nubank's general service infrastructure and how it integrates with data infrastructure specific technology. Your task is to build a Nubank microservice to serve data from the dataset you produced in _part I_: ["Creating a dataset"](dataset-exercise.md).

Here you can find one possible solution. But avoid peeking, you should be able to do the exercise by yourself (with help of other nubankers).

 **TODO - Creating the Service** 

---

- [ ]  Generating a new service using the nu-service-template
- [ ]  Getting the Avro partitions through the s3 component
- [ ]  Defining the inner representation of the entity
- [ ]  Endpoint to trigger data consumption
- [ ]  Producing and consuming to Kafka
- [ ]  Saving to Datomic
- [ ]  Endpoint for getting the data
- [ ]  Testing
  - [ ]  Unit tests
  - [ ]  Integration test
- [ ]  Run the service locally

## Statement

---

Nubank has a problem with dealing with bills. For some unknown reason, it has become really difficult to query what is the due amount of past bills for a given customer. To solve this issue, we want to create a new service that will read data produced by the ETL, build a cache from it, and serve the data using a GraphQL API.

---

Before starting you should read this glossary of our [service architecture](https://github.com/nubank/playbooks/blob/master/docs/code-organization.md#microservice-structure-and-hexagonal-architecture-terms).

Best Nubank tool: adding `#nu/tapd` before an s-exp will print the value returned by this s-exp everytime your code execute this s-exp. That's great for debugging or to just know WTH is going on in a piece of code. To add in the middle of a thread macro (this print the value being passed in the thread macro at a certain point) add `nu/tapd` (without the `#`). More about `nu/tapd` and other helpful debug macros can be found in the [cljdev readme](https://github.com/nubank/cljdev#functionsmacros).


## Generating a new service using the nu-service-template

We usually use this [template](https://github.com/nubank/nu-service-template) for generating new services. You should create a `normal` service, and not a 
`global` one.

After generating the code of your service run`nu certs gen service test <service-name>`. This command doesn't work with dockerized `nu`, you can check if your `nu` command is dockerized with `type nu` and `which nu`. If you have a dockerized nucli run `unset nu`, this will unset the dockerized version in your current terminal session.

After that your tests should be working. Run [`lein nu-test`](https://github.com/nubank/nu-test) (this will run both [midje unit tests](https://github.com/nubank/playbooks/blob/3f67eaa4d43b293f4d89c3a4f3e4c0d27cca5cfc/docs/glossary.mdob/master/glossary.md#test-unit-tests) and [postman integration tests](https://github.com/nubank/playbooks/blob/3f67eaa4d43b293f4d89c3a4f3e4c0d27cca5cfc/docs/glossary.md#postman-tests)).

---

## Getting the Avro partitions through the s3 component

The library that we will use to read Avro files requires the files to be saved locally, so before reading the files we need to download them from S3.

We'll use the [S3 component](https://github.com/nubank/common-db/blob/master/src/common_db/components/s3_store.clj) to discover and download the files ([component glossary term](https://github.com/nubank/playbooks/blob/3f67eaa4d43b293f4d89c3a4f3e4c0d27cca5cfc/docs/glossary.md#componentsclj)). This component implements the [storage protocol](https://github.com/nubank/common-db/blob/master/src/common_db/protocols/storage.clj).

Looking at the protocols implemented by a component is the simplest way to have a big picture understanding of it can do.

We'll add this component to the `base` fn on the `service.components` namespace of your service. Just take a look on how other components are added and do the same. The only dependency that your S3 component will need is the [`config` component](https://github.com/nubank/common-core/blob/34afaf592ddbfa5a5d2efb502ec69bcaf07c8841/src/common_core/components/config.clj#L179-L198).

This S3 component can be used to access only one bucket (the bucket is the first part of an S3 URI after the `s3://`: `s3://bucket/folders/files`). One way to define which bucket your component will use is add an entry on [`resources/service_config.json.base`](https://github.com/nubank/playbooks/blob/3f67eaa4d43b293f4d89c3a4f3e4c0d27cca5cfc/docs/glossary.md#resourcesmy-new-service_configjsonbase) with key `s3_bucket` and value `nu-spark-devel` (which is the [bucket](https://github.com/nubank/data-infra-docs/blob/master/onboarding/dataset-exercise.md#run-the-sparkop-on-databricks) that we used to manually save the dataset on databricks).

Congrats, you now have a S3 component. Now let's use it.

In a repl (or a file that will be sent to a repl) start your system with `service.components/create-and-start-system!`, storing the result in a variable for use later.

This system is a map with all the components defined on the `service.components` namespace.

To list all the files you can simply do `(common-db.protocols.storage/list-objects (:s3 @system) "onboarding/**schema**/")`.
This S3 path was defined [here](https://github.com/nubank/data-infra-docs/blob/master/onboarding/dataset-exercise.md#run-the-sparkop-on-databricks).

**Task**: Write logic to download local copies of all the files in a given S3 folder.

---

## Defining the inner representation of the entity

Our next step is to store all the entries within the Avro files on Datomic, with each line corresponding to a new entry on Datomic. To insert data on Datomic we need a [database model](https://github.com/nubank/playbooks/blob/master/docs/glossary.md#models). To help us figure out a good model let's look at the data contained in the Avro files. For reading Avro files we'll use the library [abracad](https://github.com/damballa/abracad). You'll need to add this library as a dependency in your `project.clj` file and restart your repl.

To show all the records in a given Avro file, run `(seq (abracad.avro/data-file-reader file-name))`, where `file-name` points to a file you saved locally. Based on these records you should define an inner
representation to your entity. Take a look at this [namespace](https://github.com/nubank/savings-accounts/blob/master/src/savings_accounts/models/savings_account.clj) to get an idea on how to create your model.

The `id`s present in the Avro files are foreign keys, so in addition, we'll need a primary key. We use UUIDs for primary keys and usually call the primary key attribute `name-of-entity/id`. This id will be generated by datomic when you insert the entity.

After creating the model of your entity add the skeleton on the namespace `service.db.datomic.config`.

---

## Endpoint to trigger data consumption

Now let's move away from the REPL a bit to start to write the main logic to serve the Avro data to clients.

We will define an endpoint to trigger the consumption of the data from S3, cache it locally and eventually produce messages to Kafka. We use Pedestal to handle HTTP requests. In this section, it might prove useful to understand [the routing](http://pedestal.io/reference/routing-quick-reference) and how to define a [handler](http://pedestal.io/reference/handlers).

In this case, the endpoint should only be accessible to those with the `admin` scope. Add a new endpoint to the `service` namespace. This endpoint should receive a JSON body with the S3 path associated with the key `s3-path`.
To extract the body parameters on your handler you need to extract the `:body-params` key from the argument list (the key is defined at the same level of the `:components` key). This key is not provided by Pedestal by default - it comes from an interceptor defined [in common-io](https://github.com/nubank/common-io/blob/master/src/common_io/interceptors/wire.clj#L98-L101).

Since this flow will download files from S3 and produce messages to Kafka, we will need to make the handler extract on both the S3 and producer components. But before doing that, we need to add the S3 component as a dependency of the `webapp` component (in the `service.components` namespace). Note that the producer already is a dependency of this component.

The endpoint you are creating will call a `controller` function that will control the flow. All pure functions go into a `logic` namespace, try to extract as many of these functions as possible.

The flow will download the files from S3 and for each entry in all files it will produce a message on Kafka.

---

## Producing and consuming to Kafka

The namespaces responsible for producing and consuming messages to and from Kafka are `service.diplomat.producer` and `service.diplomat.consumer`, respectively. Take a look at [savings-accounts](https://github.com/nubank/savings-accounts/tree/master/src/savings_accounts/diplomat) to grasp how they work.

To produce a message we need to convert the data to a wire schema. We are reading the messages in the Avro schema, so we need a function to convert this Avro in our a wire schema; this kind of functions live on namespaces under `service.adapters`.

But before defining the adapting function we need to define the wire schema. Usually these schemas live on [common-schemata](https://github.com/nubank/common-schemata). But since this is a pet project we can define them under `service.models` (don't tell anybody I recommended that :wink:).

Now you can write the function `avro-schema->wire-schema`. Adapter functions such as this one are called on the edges of our system (consumer, producer, https), so that we don't have to deal with wire data inside our service.

Everytime you use a new topic you need to register it on `kafka_topics` in the `resources/service_config.json.base` file.

We'll consume messages from the topic we just produced them to (yes, it doesn't make a lot of sense in this case - it's just so you see producing/consuming of messages).

---

## Saving to datomic

When we consume the messages that we've produced they will be in the same format we used to produce them (as expected), that is, a *wire schema*. We need an adapter function to convert a *wire schema* to our *internal schema* (`wire-schema->internal-schema`). This function will be called on the consumer.

Now that we have an internal representation of the data we can send this data to a controller function. This new flow is simpler, we just need to store the data on Datomic, the functions to do that are in namespaces under `service.db.datomic`.

There is one problem with this topic we are consuming: consumption of messages is not idempotent by default. If we consume a message more than once, we will either insert the record twice (with different ids) or it will throw an exception when inserting the second time (if our internal schema has an unique field). For our solution, choose one of the fields of the schema (the one that makes more sense for that)  and declare it as unique: just add `:unique true` to the schema skeleton. Now when we consume the topic twice it will throw an exception. One way to handle this is to wrap the Datomic insert in a `try... catch` statement and drop the exception so that it doesn't affect the rest of the code.

---

## Endpoint for getting the data

Now let's add a new endpoint for querying the data we inserted. We'll query Datomic using the id we marked as unique in the schema. The user will supply this id in the request url. Take a look [here](https://github.com/nubank/savings-accounts/blob/8c904e2b266f27788557d641d32a4c3486d277e6/src/savings_accounts/service.clj#L202-L206) to see how this id is usually extracted.

By default, when we extract data from the url we get a `String` – but for our purposes, we'll need a `UUID`. Fortunately we have a Pedestal interceptor that performs this conversion automatically for us. We just need to add it to the interceptor list at the `services` namespace. Take a look in the link above to find this
interceptor.

There's another important interceptor you'll need: to fetch data from Datomic, we don't directly use the Datomic component; instead, we get a snapshot from the database using the `common-datomic.db.db` function. This snapshot is inserted into the request map as an immutable value against which we can run Datomic queries. The main advantage of this approach is that it's automatically clear if an endpoint will change anything in the database or just query it. Take a look in [this link](https://github.com/nubank/savings-accounts/blob/8c904e2b266f27788557d641d32a4c3486d277e6/src/savings_accounts/service.clj#L170) to find this interceptor.

Also remember that you should convert the data to a wire schema before replying to the request.

---

## Testing

Even though running code in the repl is great, automated tests are even better. We'll write two types of tests: unit(midje) and integration(postman) tests.

A good place to understand our way of writing is the README of our [common-test library](https://github.com/nubank/common-test).

Before we write any tests, there's one thing we need to change in the application code. At the beginning of the exercise, we added an S3 component in the `components` namespace, but for tests we don't want to *actually* hit S3. Fortunately, `common-db` provides a [mock component](https://github.com/nubank/common-db/blob/master/src/common_db/components/mock_s3_store.clj) we can use for this purpose!

We can add this mock component to be used when running local tests by adding a new entry in the `test` function in the `components` namespace. Simply add it under the same key as the one used for the normal S3 component in the `base` function.

### Unit tests

Test files follow the same structure as "real code", with two differences:
- instead of being in the `src` folder they are in the `test` folder
- test file names (and thus test file namespaces) have the suffix `_test` (`-test` for the namespace). For example, the test file for `service.clj` is `service_test.clj`

We should write tests for all functions in the `logic`, `adapters`, and `datomic` 
namespaces. As for the `service`, `consumer` and `producer` namespaces, try to write tests that would increase your level of confidence in the solution. If a function is doing something less conventional or that makes you feel suspicious, it might be a good idea to test it.

Use `schema.core/with-fn-validation` wherever possible. Be aware that midje's metaconstant break these validations. Also, ALWAYS test logic functions with schema validation and no stubs or mocks.

Controllers tests are a bit more controversial. Some people like to have them, others think they should be avoided because they don't have a big upside and require labor intensive work when the code is changed.

### Integration tests

At Nubank we implemented [our own solution for integration tests](https://github.com/nubank/common-test#postman). These are often referred to as Postman tests. For the purpose of the exercise, take a look at this [postman test](https://github.com/nubank/savings-accounts/blob/master/postman/postman/account_creation.clj) to get familiarized with how they are written.

Integration tests go in the `postman/postman/` folder. You should add one postman test that will ensure that the whole flow is working:

- caching locally and processing Avro files
- producing and consuming Kafka messages
- saving to datomic
- receiving and answering HTTP request
- querying Datomic

Since you are using the mock component for s3 we should add some mock data there so we have something to download from s3. This component is a regular s3 component, you can use the methods defined in the s3 protocol for saving data. To improve code organization, you can move this function to an auxiliary namespace.

For triggering an endpoint you can use the same functions as those found in `service.service-test`. To see if a message was produced to Kafka you can use the function [log-messages](https://github.com/nubank/common-test/#kafka). Make sure you call `common-test.postman.helpers.kafka/clear-messages!` in the `init!` function (you can find an example of such a function [here](https://github.com/nubank/papers-please/blob/7a67b7f6e52ed949ca46cfc9f3d1b3cadb26f53e/postman/postman/aux/init.clj#L9-L18)).

---

## Run the service locally

Before you run we should make some small changes to make the process a bit more interesting:
- comment the s3 mock component in the `test` environment. In this way your 
service will use the `base` s3 component, which will actually hit Amazon's s3.
- in the function that inserts the data on Datomic do a `#nu/tapd` in the unique
 field. This will give some visibility on the insertions and you can later use 
these ids in the query endpoint.

Running a service is pretty straightforward with [nudev](https://github.com/nubank/nudev). First of all, in this repo add your service to the `UNFLAVORED` list on `nustart.d/nustart/lein_service.rb` (this is related to the structure we're using in the `components.clj`).

Before running any service you need to ensure the dependencies of the service are up. Running `dev-env-compose up -d` on a terminal starts a Kafka, Datomic, Redis and Zookeeper. To start your service run `dev-compose up -d service-name`. To see the logs run `dev-compose logs -f service-name`.

If you don't see anything weird (no logs or stack traces) in the logs your service is probably running ok. To make sure it's running do a `curl localhost:port/api/version`. This should return `{"version":"MISSING"}`. You can get the port by looking for the `dev_port` in the 
`resources/service_config.json.base` file.

If everything goes fine you can hit the endpoint that consumes the data from s3. 
After that, hit the endpoint to get the entity that was inserted.

You finished it, but our princess is in another castle. Now you need to go to 
the real world!

---

## Study materials

First of all read this: [https://github.com/nubank/data-infra-docs/blob/master/primer.md](https://github.com/nubank/data-infra-docs/blob/master/primer.md)
