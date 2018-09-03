Keep an eye on #guild-data-eng and #eng-cool-stuff at slack for newer resources.

Have a look at the books in the office to get some dead tree resources.

# Internal material

- [Busquem Conhecimento ETL](https://www.youtube.com/watch?v=QKSiGzrLUyQ): talk given by Alessandro Andrioni and Andre Midea on November 11, 2016
- [Machine Learning Meetup 5th Edition - Nubank’s Data Pipeline](https://www.youtube.com/watch?v=i97teM7TNqg): talk given by Alessandro Andrioni and Andre Midea on June 5, 2017
- [BIMicroservices-v2.pdf](https://drive.google.com/file/d/1DbXJvEvab6TkoHFZgmRTFBWVVkCM00A_/view): presentation given by Edward Wible on October 6, 2017

# Blog posts

## General data engineering

- [The Rise of the Data Engineer](https://medium.freecodecamp.org/the-rise-of-the-data-engineer-91be18f1e603)
- [The Downfall of the Data Engineer](https://medium.com/@maximebeauchemin/the-downfall-of-the-data-engineer-5bfb701e5d6b)
- [Functional Data Engineering — a modern paradigm for batch data processing](https://medium.com/@maximebeauchemin/functional-data-engineering-a-modern-paradigm-for-batch-data-processing-2327ec32c42a)

## About logs and the way we structure our data

- [The Log: What every software engineer should know about real-time data's unifying abstraction](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
- [Using logs to build a solid data infrastructure (or: why dual writes are a bad idea)](https://martin.kleppmann.com/2015/05/27/logs-for-data-infrastructure.html)

## Stream processing

- [How to beat the CAP theorem](http://nathanmarz.com/blog/how-to-beat-the-cap-theorem.html)
- [Questioning the Lambda Architecture](https://www.oreilly.com/ideas/questioning-the-lambda-architecture)
- [Why local state is a fundamental primitive in stream processing](https://www.oreilly.com/ideas/why-local-state-is-a-fundamental-primitive-in-stream-processing)
- [Stream processing, Event sourcing, Reactive, CEP… and making sense of it all](https://martin.kleppmann.com/2015/01/29/stream-processing-event-sourcing-reactive-cep.html)
- [Turning the database inside-out with Apache Samza](https://martin.kleppmann.com/2015/03/04/turning-the-database-inside-out.html)
- [Kafka, Samza, and the Unix philosophy of distributed data](https://martin.kleppmann.com/2015/08/05/kafka-samza-unix-philosophy-distributed-data.html)
- [Putting Apache Kafka To Use: A Practical Guide to Building a Stream Data Platform (Part 1)](http://www.confluent.io/blog/stream-data-platform-1/)
- [Putting Apache Kafka To Use: A Practical Guide to Building a Stream Data Platform (Part 2)](http://www.confluent.io/blog/stream-data-platform-2/)
- [The world beyond batch: Streaming 101](https://www.oreilly.com/ideas/the-world-beyond-batch-streaming-101)
- [The world beyond batch: Streaming 102](https://www.oreilly.com/ideas/the-world-beyond-batch-streaming-102)
- [Comparing the Dataflow/Beam and Spark Programming Models](https://cloud.google.com/blog/big-data/2016/02/comparing-the-dataflowbeam-and-spark-programming-models)
- [Event sourcing, CQRS, stream processing and Apache Kafka: What’s the connection?](http://www.confluent.io/blog/event-sourcing-cqrs-stream-processing-apache-kafka-whats-connection/)
 
## Distributed systems

- [Notes on Distributed Systems for Young Bloods](https://www.somethingsimilar.com/2013/01/14/notes-on-distributed-systems-for-young-bloods/)
- [Distributed systems theory for the distributed systems engineer](http://the-paper-trail.org/blog/distributed-systems-theory-for-the-distributed-systems-engineer/)
- [How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html)
- [Readings in conflict-free replicated data types](https://christophermeiklejohn.com/crdt/2014/07/22/readings-in-crdts.html)
- [The Hadoop Distributed File System](http://www.aosabook.org/en/hdfs.html)
- [You Do It Too: Forfeiting Network Partition Tolerance in Distributed Systems](http://blog.thislongrun.com/2015/07/Forfeit-Partition-Tolerance-Distributed-System-CAP-Theorem.html)
- [Making The Case For Building Scalable Stateful Services In The Modern Era](http://highscalability.com/blog/2015/10/12/making-the-case-for-building-scalable-stateful-services-in-t.html)
- [Provenance and causality in distributed systems](http://blog.jessitron.com/2016/09/provenance-and-causality-in-distributed.html)
- [Aphyr's Jepsen article series](https://aphyr.com/posts/281-jepsen-on-the-perils-of-network-partitions)

## Databases

- [Hermitage: Testing the “I” in ACID](https://martin.kleppmann.com/2014/11/25/hermitage-testing-the-i-in-acid.html)

## Data modeling

- [Towards universal event analytics - building an event grammar](http://snowplowanalytics.com/blog/2013/08/12/towards-universal-event-analytics-building-an-event-grammar/)
- [The three eras of business data processing](http://snowplowanalytics.com/blog/2014/01/20/the-three-eras-of-business-data-processing/)
- [Building an event grammar - understanding context](http://snowplowanalytics.com/blog/2014/03/11/building-an-event-grammar-understanding-context/)
- [Improving Snowplow's understanding of time](http://snowplowanalytics.com/blog/2015/09/15/improving-snowplows-understanding-of-time/)
- [We need to talk about bad data](http://snowplowanalytics.com/blog/2016/01/07/we-need-to-talk-about-bad-data-architecting-data-pipelines-for-data-quality/)

## Schema management

- [Schema evolution in Avro, Protocol Buffers and Thrift](https://martin.kleppmann.com/2012/12/05/schema-evolution-in-avro-protocol-buffers-thrift.html)
- [The problem of managing schemas](https://www.oreilly.com/ideas/the-problem-of-managing-schemas)
- [Yes, Virginia, You Really Do Need a Schema Registry](http://www.confluent.io/blog/schema-registry-kafka-stream-processing-yes-virginia-you-really-need-one/)
 
## Other companies' data infrastructures

- [Asana #1](https://blog.asana.com/2014/11/stable-accessible-data-infrastructure-startup/)
- [Asana #2](https://blog.asana.com/2014/11/great-data-delivery/)
- [Buffer](https://overflow.buffer.com/2014/10/31/buffers-new-data-architecture/)
- [500px](https://medium.com/@samson_hu/building-analytics-at-500px-92e9a7005c83?hn)
- [RJMetrics](https://blog.rjmetrics.com/2015/11/10/how-we-built-rjmetrics-pipeline/)
- [Simple](https://www.simple.com/engineering/building-analytics-at-simple)
- [IFTTT](http://engineering.ifttt.com/data/2015/10/14/data-infrastructure/)
- [Amplitude](https://amplitude.com/blog/2015/03/27/why-we-chose-redshift/)
- [Viki](http://engineering.viki.com/blog/2014/data-warehouse-and-analytics-infrastructure-at-viki/)
- [Kickstarter](https://www.kickstarter.com/backing-and-hacking/this-is-the-story-of-analytics-at-kickstarter)
- [Upworthy](http://upworthy.github.io/2014/04/data-architecture/)
- [Airbnb #1](http://nerds.airbnb.com/redshift-performance-cost/)
- [Airbnb #2](https://medium.com/airbnb-engineering/data-infrastructure-at-airbnb-8adfb34f169c)
- [Astronomer #1](http://www.astronomer.io/blog/why-we-built-our-data-platform-on-aws-and-why-we-rebuilt-it-with-open-source)
- [Astronomer #2](http://www.astronomer.io/blog/lessons-learned-writing-data-pipelines)
- [Yelp](https://engineeringblog.yelp.com/2016/07/billions-of-messages-a-day-yelps-real-time-data-pipeline.html)
- [Oyster](http://oyster.engineering/post/120026990383/data-at-oyster-part-i-infrastructure)
- [Thumbtack #1](https://www.thumbtack.com/engineering/building-thumbtacks-data-infrastructure-2/)
- [Thumbtack #2](https://www.thumbtack.com/engineering/building-thumbtacks-data-infrastructure-part-ll/)
- [Coursera](https://building.coursera.org/blog/2016/05/14/analytics-at-coursera-three-years-later/)
- [Pinterest #1](https://engineering.pinterest.com/blog/powering-interactive-data-analysis-redshift)
- [Pinterest #2](https://engineering.pinterest.com/blog/powering-big-data-pinterest)
- [WePay](https://wecode.wepay.com/posts/wepays-data-warehouse-bigquery-airflow)
- [SeatGeek](http://chairnerd.seatgeek.com/building-out-the-seatgeek-data-pipeline/)
- [RJMetrics survey](https://blog.stitchdata.com/the-data-infrastructure-meta-analysis-how-top-engineering-organizations-built-their-big-data-2e704f787670#.ti8pspoee)
- [Twitch #1](https://blog.twitch.tv/twitch-data-analysis-part-1-of-3-the-twitch-statistics-pipeline-51556a14c961)
- [Twitch #2](https://blog.twitch.tv/twitch-data-analysis-part-2-of-3-the-architectural-decision-making-process-65683a23a74a)
 
# Articles/conference papers

## Fundamental

- [The Google File System](http://research.google.com/archive/gfs.html)
- [MapReduce: Simplified Data Processing on Large Clusters](http://research.google.com/archive/mapreduce.html)
- [Interpreting the Data: Parallel Analysis with Sawzall](http://research.google.com/pubs/pub61.html)
- [Dryad: Distributed Data-Parallel Programs from Sequential Building Blocks](http://www.news.cs.nyu.edu/~jinyang/sp07/papers/dryad.pdf)
- [FlumeJava: Easy, Efficient Data-Parallel Pipelines](http://research.google.com/pubs/pub35650.html)
- [DryadLINQ: A System for General-Purpose Distributed Data-Parallel Computing Using a High-Level Language](https://www.usenix.org/legacy/event/osdi08/tech/full_papers/yu_y/yu_y.pdf)

## Spark

- [Spark: Cluster Computing with Working Sets](http://people.csail.mit.edu/matei/papers/2010/hotcloud_spark.pdf)
- [Resilient Distributed Datasets: A Fault-Tolerant Abstraction for In-Memory Cluster Computing](http://people.csail.mit.edu/matei/papers/2012/nsdi_spark.pdf)
- [Spark SQL: Relational Data Processing in Spark](http://people.csail.mit.edu/matei/papers/2015/sigmod_spark_sql.pdf)
 
## Streaming

- [All Aboard the Databus!](https://slack-files.com/T024U97V8-F2L3MPN01-672f548a1e)
- [Kafka: a Distributed Messaging System for Log Processing](http://research.microsoft.com/en-us/um/people/srikanth/netdb11/netdb11papers/netdb11-final12.pdf)
- [Building a Replicated Logging System with Apache Kafka](http://www.vldb.org/pvldb/vol8/p1654-wang.pdf)
- [Building LinkedIn’s Real-time Activity Data Pipeline](http://sites.computer.org/debull/A12june/pipeline.pdf)
- [Storm @Twitter](https://cs.brown.edu/courses/csci2270/archives/2015/papers/ss-storm.pdf)
- [Twitter Heron: Stream Processing at Scale](http://dl.acm.org/citation.cfm?id=2742788)
- [MillWheel: Fault-Tolerant Stream Processing at Internet Scale](http://research.google.com/pubs/pub41378.html)
- [The Dataflow Model: A Practical Approach to Balancing Correctness, Latency, and Cost in Massive-Scale, Unbounded, Out-of-Order Data Processing](http://research.google.com/pubs/pub43864.html)
- [Differential dataflow](http://cidrdb.org/cidr2013/Papers/CIDR13_Paper111.pdf)
- [Naiad: a timely dataflow system](http://dl.acm.org/citation.cfm?id=2522738)
- [Realtime Data Processing at Facebook](https://research.facebook.com/publications/realtime-data-processing-at-facebook/)
 
## Graph processing

- [Pregel: A System for Large-Scale Graph Processing](https://kowshik.github.io/JPregel/pregel_paper.pdf)
- [Scalability! But at what COST?](http://www.frankmcsherry.org/assets/COST.pdf)
- [Time-Evolving Graph Processing at Scale](http://www.cs.columbia.edu/~lierranli/publications/GraphTau-GRADES2016.pdf)
 
## Schema, metadata and data management

- [Exploring Schema Repositories with Schemr](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.362.1822&rep=rep1&type=pdf)
- [Shasta: Interactive Reporting at Scale](http://research.google.com/pubs/pub45394.html)
- [Goods: Organizing Google's Datasets](http://research.google.com/pubs/pub45390.html)
 
## Databases

- [Data warehousing and analytics infrastructure at Facebook](https://research.facebook.com/publications/data-warehousing-and-analytics-infrastructure-at-facebook-/)
- [F1 - The Fault-Tolerant Distributed RDBMS Supporting Google's Ad Business](http://research.google.com/pubs/pub38125.html)
- [Spanner: Google’s Globally-Distributed Database](http://static.googleusercontent.com/media/research.google.com/en//pubs/archive/44915.pdf)
- [Online, Asynchronous Schema Change in F1](http://research.google.com/pubs/pub41376.html)
- [Dremel: Interactive Analysis of Web-Scale Datasets](http://research.google.com/pubs/pub36632.html)
- [S-Store: Streaming Meets Transaction Processing](http://www.vldb.org/pvldb/vol8/p2134-meehan.pdf)
- [Scuba: Diving into Data at Facebook](https://research.facebook.com/publications/scuba-diving-into-data-at-facebook/)
- [Mesa: Geo-Replicated, Near Real-Time, Scalable Data Warehousing](http://research.google.com/pubs/pub42851.html)
