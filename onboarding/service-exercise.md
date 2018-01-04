# Onboarding Exercise Part II: Creating a service to expose a dataset via API

The goal of this exercise is to make you familiar with Nubank's general service infrastructure and how it integrates with data infrastructure specific technology. Your task is to build a Nubank microservice to serve data from the dataset you produced in _part I_: ["Creating a dataset"](dataset-exercise.md)

 **TODO - Creating the Service** 

---

- [ ]  Generating a new service using the nu-service-template
- [ ]  Getting the avro partitions through the s3 component
- [ ]  Defining the inner representation of the entity
- [ ]  Endpoint to trigger data consumption
- [ ]  Producing and consuming to kafka
- [ ]  Saving to datomic
- [ ]  Endpoint for getting the data
- [ ]  Testing
  - [ ]  Unit tests
  - [ ]  Integration test
- [ ]  Run the service locally

## Statement

---

Nubank has a problem with dealing with bills. For some unknown reason, it has become really difficult to query what is the due amount of past bills for a given customer. To solve this issue, we want to create a new service that will read data produced by the ETL, build a cache from it, and serve the data using a GraphQL API.


---

Before starting you should read this glossary of our 
[service architecture](https://github.com/nubank/playbooks/blob/master/docs/glossary.md#microservice-structure-and-hexagonal-architecture-terms)

Best Nubank tool: adding `#nu/tapd` before an s-exp will print the value 
returned by this s-exp everytime your code execute this s-exp. That's great for
debugging or to just know WTH is going on in a piece of code. To add in the 
middle of a thread macro (this print the value being passed in the thread macro 
at a certain point) add `nu/tapd` (without the `#`). More about `nu/tapd` and
other helpful debug macros can be found in the [cljdev
readme](https://github.com/nubank/cljdev#functionsmacros)


## Generating a new service using the nu-service-template

We usually use this [template](https://github.com/nubank/nu-service-template) 
for generating new services. You should create a `normal` service, and not a 
`global` one.

After generating the code of your service run 
`nu certs gen service test <service-name>`. This command doesn't work with 
dockerized `nu`, you can check if your `nu` command is dockerized with `type nu`
 and `which nu`. If you have a dockerized nucli run `unset nu`, this will unset 
the dockerized version in your current terminal session.

After that your tests should be working. Run [`lein nu-test`](https://github.com/nubank/nu-test)
(this will run both [midje unit tests](https://github.com/nubank/playbooks/blob/master/glossary.md#test-unit-tests) and [postman integration tests](https://github.com/nubank/playbooks/blob/master/glossary.md#postman-tests))

---

## Getting the avro partitions through the s3 component

The library that we will use to read avro files requires the files to be saved 
locally, so before reading the files we need to download them from s3.

We'll use the 
[s3 component](https://github.com/nubank/common-db/blob/master/src/common_db/components/s3_store.clj)
to discover and dowload the files ([component glossary term](https://github.com/nubank/playbooks/blob/master/glossary.md#componentsclj)). This component implements the [storage protocol](https://github.com/nubank/common-db/blob/master/src/common_db/protocols/storage.clj). 
Looking at the protocols implemented by a component is the simplest way to have 
a big picture understanding of it can do.

We'll add this component to the `base` fn on the `service.components` namespace 
of your service. Just take a look on how other components are added and do the 
same. The only dependency that your s3 component will need is the [`config` component](https://github.com/nubank/common-core/blob/34afaf592ddbfa5a5d2efb502ec69bcaf07c8841/src/common_core/components/config.clj#L179-L198).

This s3 component can be used to access only one bucket (the bucket is the first
 part of an s3 uri after the `s3://`: `s3://bucket/folders/files`). One way to 
define which bucket your component will use is add an entry on 
[`resources/service_config.json.base`](https://github.com/nubank/playbooks/blob/master/glossary.md#resourcesmy-new-service_configjsonbase) with key `s3_bucket` and value 
`nu-spark-devel` (which is the 
[bucket](https://github.com/nubank/data-infra-docs/blob/onboarding/onboarding/introduction.md#run-the-sparkop-on-databricks)
 that we used to manually save the dataset on databricks)

Congrats, you now have a s3 component. Now lets use it.

In a repl (or a file that will be sent to a repl) start your system with 
`service.components/create-and-start-system!`, storing the result in a variable for use later 

This system is a map with all the components defined on the `service.components`
 namespace.

To list all the files you can simply do 
`(common-db.protocols.storage/list-objects (:s3 system) "onboarding/**schema**/")`.
 This s3 path was defined 
[here](https://github.com/nubank/data-infra-docs/blob/onboarding/onboarding/introduction.md#run-the-sparkop-on-databricks)

Now you should write some code to caching locally all these files of a given s3 
folder.

---

## Defining the inner representation of the entity

We want to store all the entries within the avro files on datomic. For each line 
we'll store a new entry on datomic. To insert data on datomic we need a [database mode](https://github.com/nubank/data-infra-docs/blob/master/glossary.md#models). 
To help us figure out a good model let's look at the data contained in the
 avro files. For reading avro files we'll use the library 
[abracad](https://github.com/damballa/abracad). You'll need to add this library 
as a dependency in your `project.clj` file and restart your repl.

To show all the records in a given avro file, run `(seq
(abracad.avro/data-file-reader file-name))`, where `file-name` points
to a file you saved locally. Based on these records you should define an inner
representation to your entity. Take a look at this 
[namespace](https://github.com/nubank/savings-accounts/blob/master/src/savings_accounts/models/savings_account.clj)
 to get an idea on how to create your model.

The `id`s present in the avro files are foreign keys, so in addition, we'll need 
a primary key. We use UUIDs for primary keys and usually call the primary key attribute `name-of-entity/id`.
 This id will be generated by datomic when you insert the entity.

After creating the model of your entity add the skeleton on the namespace 
`service.db.datomic.config`

---

## Endpoint to trigger data consumption

Now let's move away from the repl a bit to start to write the main logic to
serve the avro data to clients.

We want an endpoint that only who has the `admin` scope can use. Add a new 
endpoint to the `service` namespace. This endpoint should receive a json body
with the s3 path associated with the key `s3-path`. To extract the body 
parameters on your handler you need to extract the `:body-params` key in the 
arg list of the `defhandler` (in the same level as the `:components` is)

This flow will cache locally the files from s3 and produce messages to kafka. So
 in the handler triggered by the new endpoint we'll extract the s3 and producer 
component. But before using the s3 component on the http handler we need to add 
it as a dependency to the webapp component(in the `service.components` 
namespace). The producer already is a dependecy of this component.

The endpoint you are creating will call a `controller` function that will 
control the flow. All the deterministic and without side effects functions go 
into a `logic` namespace, try to extract as many as these functions as possible.

The flow will download the files from s3 and for each entry in all files it 
will produce a message on kafka

---

## Producing and consuming to kafka

The namespaces responsible for producing and consuming messages to and from 
kafka are `service.diplomat.producer` and `service.diplomat.consumer`, 
respectively. Take a look at `savings-accounts` to grasp how they work.

To produce a message we need to convert the data to a wire schema. We are 
reading the messages in the avro schema, so we need a function to convert this 
avro in our a wire schema; this kind of functions live on namespaces under 
`service.adapters`.

But before defining the adapting function we need to define the wire schema. 
Usually these schemas live on 
[common-schemata](https://github.com/nubank/common-schemata). But since this is 
a pet project we can define them under `service.models` (don't tell anybody I 
recommended that ;) )

Now you can write the function that avro-schema->wire-schema. These adapters 
functions are called on the edges(consumer, producer, https), so we don't have 
to deal with wire data inside our service.

Everytime you use a new topic you need to register it on `kafka_topics` in the 
`resources/service_config.json.base` file.

We'll consume the topic we just produced the messages(yes, it doesn't make a lot
 of sense in this case - it's just so you see producing/consuming of messages).

---

## Saving to datomic

When we consume the messages that we've produced they will be in the same format
 we used to produce (obviously), that is a wire schema. We need an adapter 
function to convert a wire schema to our inner schema. This function will be 
called on the consumer.

Now that we have an inner representation of the data we can send this data to a 
controller function. This new flow is simpler, we just need to store the data on
 datomic, the functions to do that are in namespaces under `service.db.datomic`.

There is a little problem with this topic we are consuming. Our flow is not 
idempotent. If we consume the message more than one time we will either insert 
the record twice (with different ids) or it will throw an exception when 
inserting the second time (if our inner schema has an unique field). For our 
solution choose one the fields (the one that makes more sense for that) of the 
schema and declare it as unique: just add `:unique true` to the schema. Now when
 we consume the topic twice it will throw an exception. An ok way to avoid that 
is to wrap the datomic insert function in a `try catch` statement, so the rest 
of the code don't have to care about it.

---

## Endpoint for getting the data

Now let's add a new endpoint for querying the data we inserted. We'll query 
datomic using the id you made unique in the schema. The user will send this 
id in the url path. Take a look 
[here](https://github.com/nubank/savings-accounts/blob/master/src/savings_accounts/service.clj)
 to see how this extracting looks like.

When we extract data from the url we get just a string, and that's sad because 
we need an `UUID`. Fortunately we have an pedestal interceptor that does this 
conversion automatically for us. We just need to add it to the interceptor list 
at the `services` namespace. Take a look in the link above to find this
interceptor.

You'll have to find another usefull interceptor now. We don't directly use the 
datomic component to fetch data, we get a snapshot from the database using the 
`common-datomic.db.db` fn and with this snapshot we query for data. There is a 
interceptor that already gives the snapshot to the handler. The main advantage 
of this approach is that it's automatically clear if an endpoint will change 
anything in the database or just query it. Take a look in the link above to find
 this interceptor.
 
Remeber that you should use convert the data to a wire schema before replying 
the request.

---

## Testing

Even though running code in the repl is great, automated tests are even better. 
We'll write two types of tests: unit(midje) and integration(postman) tests.

A good place to understand our way of writing is the README of our 
[common-test](https://github.com/nubank/common-test)

Before writing to many tests we should change a thing we did in the  beggining 
of this exercise. We added the s3 component to the base layer of components, 
but hitting s3 for unit and [inner] integration tests is not very good. 
Fortunatelly we have a mock component for s3. We can add this mock component 
to run just when we are running local tests by adding a new entry in the 
`test` fn on the `components` namespace. We just need to add the same name we
 did in the `base` fn and now use the 
[mock component](https://github.com/nubank/common-db/blob/master/src/common_db/components/mock_s3_store.clj).

### Unit tests

The tests files follow the same structure as the "real code", the two 
differences are:
- instead of being in the `src` folder they are in the `test` folder
- the test files add the suffix `_test` in the end of the file name (and before 
`.clj`). Also the namespace has a `-test` suffix.

We should write tests for all functions in the `logic`, `adapters`, `datomic` 
namespaces. If on the `service`, `consumer` and `producer` namespaces you are 
doing anything out of the ordinary or are not felling very confortable about 
some function you should also add tests to them.

Use `s/with-fn-validation` every time that you can. Be aware that midje's 
metaconstant break these validations. Also, ALWAYS test logic functions with 
schema validation and no stubs or mocks.

Controllers tests are a bit more controversial. Some people like to have them, 
others think they should be avoided because they don't have a big upside and 
require labor intensive work when the code is changed.

### Integration test

Take a look at this [postman test](https://github.com/nubank/savings-accounts/blob/master/postman/postman/account_creation.clj)
to get familiarized to the way we write integration tests.

The integration tests go in `postman/postman/` folder.

You should add one postman test that will ensure that the whole flow is working:
- caching locally and processing avro files
- producing and consuming kafka messages
- saving to datomic
- receiving and answering http request
- querying datomic

Since you are using the mock component for s3 we should add some mock data there
 so we have something to download from s3. This component is a regular s3 
component, you can use the methods defined in the s3 protocol for saving data.
For a better code organization you can separate this function to an auxiliary 
namespace.

For triggering an endpoint you can use the same functions as in `service-test`. 
To see if a message was produced to kafka you can use the function 
[log-messages](https://github.com/nubank/common-test/#kafka). Make sure you call 
 `common-test.postman.helpers.kafka/clear-messages!` in the `aux/init` function.

---

## Run the service locally

Before you run we should make some small changes to make the process a bit more 
interesting:
- comment the s3 mock component in the `test` environment. In this way your 
service will use the `base` s3 component, which will actually hit Amazon's s3.
- in the function that inserts the data on datomic do a `#nu/tapd` in the unique
 field. This will give some visibility on the insertions and you can later use 
these ids in the query endpoint.

Running a service is pretty straight forward with 
[nudev](https://github.com/nubank/nudev). First of all in this repo add your 
service to the `UNFLAVORED` list on `nustart.d/nustart/lein_service.rb` (this is
 related to the structure we're using in the `components.clj`).

Before running any service you need to ensure the dependencies of the service 
are up. Running `dev-env-compose up -d` on a terminal starts a Kafka, Datomic, 
Redis and Zookeeper. To start your service run `dev-compose up -d service-name`.
To see the logs run `dev-compose logs -f service-name`.

If you don't see anything weird (no logs or stack traces) in the logs your 
service is probably running ok. To make sure it's running do a 
`curl localhost:port/api/version`. This should return `{"version":"MISSING"}`. 
You can get the port by looking the `dev_port` in the 
`resources/service_config.json.base` file.

If everything goes fine you can hit the endpoint that consume the data from s3. 
After that hit the endpoint to get the entity that was inserted.

You finished it, but our princess is in another castle. Now you need to go to 
the real world!.

---

# Study materials

First of all read this: [https://github.com/nubank/data-infra-docs/blob/master/primer.md](https://github.com/nubank/data-infra-docs/blob/master/primer.md)
