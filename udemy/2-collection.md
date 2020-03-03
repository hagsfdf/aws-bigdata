# 0.Collection introduction

What is **collection?** Moving data into AWS!

- Real Time - immediate actions (e.g. Kinesis Data Streams, Simple Queue Service, IoT)
- Near-real time - Reactive actions (e.g. Kinesis Data Firehose, Database Migration Service)
- Batch - Historical Analysis (large amount of data) (e.g. Snowball, Data Pipeline)

So let's start with Kinesis Data Streams

# AWS Kinesis 

- Kinesis is a managed alternative to Apache Kafka
- Great for application logs, metrics, IoT, click streams
- Great for "real-time" big data
- Great for streaming processing frameworks (Spark, etc...)
- Data is automatically replicated synchronously to 3 AZ

There are three types of it...

- Kinesis Streams : Low latency streaming ingest at scale.
- Kinesis Analytics : perform **real-time** analytics on streams using SQL.
- Kinesis Firehose : Load Streams into S3, RedShift, ElasticSearch & Splunk

# Use case

Kinesis Stream ingests data from Click Streams, IoT devices, or Metrics and Logs. 

If you may want to analyze it in **real time,** solution is kinesis analytics.

If you want to store your data for later analysis, Amazon Kinesis Firehose. It is **near-real-time analysis**. Kinesis firehose will deliver data into S3 bucket or RedShift, or Splunk, for analysis

## Kinesis Streams (is not Database)

- Streams are divided in ordered Shards
- Data storage is not persistent. Data retention is 24 hours by default, can go up to 7 days.
- Ability to reprocess/replay data. Even if the consumer consumes the data, it is not gone from the stream. (It will expire based on retention period, though) But you can read the same data over and over as long as it is in the Kinesis Stream.
- (Therefore,) Multiple application can consume the same stream.
- Real-time processing with scale of throughput.
- Once the data are inserted, it's immutable. It can't be deleted. **Append-only Stream**

### Shards?

- One stream is made of many different shards
- Billing (\$) is per shard provisioned. can have as many shards as you want.
- Batching available or per message calls (will make more sense if we dive into producer section)
- The number of shards can evolve over time (reshard/merge)
- **Records are ordered per shard (when they are received)**

### How does producer produce the data? By Record.

And it consists of three parts:

- Data blob : Data being sent, serialized as bytes. **up to 1MB**.
- Record Key : Sent alongside a record, helps to group records in shards. Same key = same shard. Plz, use a highly distributed key
- Sequence Number : Unique Identifier for each records put in shards. (this is not produced by producer) it is automatically added by Kinesis after ingestion. 

### Important limits

#### Imposed on Producer

- 1MB/s or 1000 messages/s at write PER SHARD
- "ProvisionedThroughtputException" otherwise

#### Consumer Classic

- 2MB/s at read PER SHARD across all consumers
- 5 API calls per second PER SHARD across all consumers

c.f.) consumer enhanced fan-out version requires NO API calls (it is a push model, it is good for flexible scaling)

#### Data Retention

- 24 hours data retention by default
- Can be extended to 7 days (with extra fee)

## Kinesis Producers

- Kinesis SDK (Software Development Kit)
- Kinesis Producer Library (KPL) (can achieve enhanced throughput)
- Kinesis Agent (Agent that runs on server. Allows you to get a log file)
- Third party libraries (Spark, Log4J appenders, Flume, Kafka connect, NiFi,...)

### Kinesis SDK (LAMEST)

- APIs that are used are PutRecord and PutRecords
- PutRecords will use batching and increases throughput (therefore less HTTP requests) (one HTTP request will contain a lot of records)
- ProvisionedThroughtputExceeeded if we go over the limits

What's the use case? LOW THROUGHPUT, HIGHER LATENCY, SIMPLE API, AWS LAMBDA

- Managed AWS sources for Kinesis Data Streams (CloudWatch Logs, AWS IoT, Kinesis Data Analytics). These services will use SDK to plug their data streams(logs) into the Kinesis Stream

How about the exception?

- ProvisionedThroughtputExceeeded  (exceeding MB/s or TPS (transactions per second) for any shard)
- Make sure you don't have a hot shard (usually when partition key is bad)

Solution for exception

- Retries with backoff
- Increase shards (scaling)
- Ensure your partition key is a good one (fairly distributed)

### Kinesis Producer Library (KPL)

- Easy to use and highly configurable C++ / Java Library
- Used for building high performance, long-running producers
- Automated and configurable retry mechanism (we don't have to deal with exceptions as we did in SDK. KPL handles it for us)
- Synchronous(same as API) or Asynchronous API(better performance for async)
- Submits metrics to CloudWatch for monitoring
- Compression must be implemented by user.
- KPL records must be decoded with KCL or special helper library. (not available by basic CLI)
- Batching (both turned on by default)- increase throughput, decrease cost

Two types of batching:

- **Collect** records and write to multiple shards in the same PutRecords API call
- **Aggregate** - increased latency 
    - capability to store multiple records in one record (go over 1000 records per second limit)
    - increase payload size and improve throughput (maximize 1MB/s limit)


#### KPL Batching

![image](https://user-images.githubusercontent.com/34101059/75790405-81b46f80-5dae-11ea-84ce-4965d2825aba.png){width=60%}

It doesn't immediately send a newly incoming record. It waits for aggregation (till < 1MB). Then, those resulting records are not going to be sent by multiple PutRecord. Instead, it will use PutRecords. This is Collection.

So how does Kinesis know how long they have to wait? Batching efficiency can be influenced by introducing some delay with **RecordMaxBufferedTime** (default 100ms) (adding a bit of latency)


### Kinesis Agent

- Monitor Log files and sends them to Kinesis Data Streams
- Java-based agent, built on top of KPL
- Install in Linux-based server environments

- Features:
    - Write from multiple directories and write to multiple streams
    - Routing feature based on directory / log file
    - Pre-process data before sending to streams (single line, csv to json, log to json...)
    - The agent handles file rotation, checkpointing, and retry upon failures (just like KPL!)
    - Emits metrics to CloudWatch for monitoring

**If you need to do aggregation of logs in mass in almost real time, then the Kinesis agent is the solution**


## Kinesis Consumer - Classic

- Kinesis SDK
- Kinesis Client Library (KPL)
- Kinesis Connector Library
- 3rd party libraries (Spark, etc..) **Spark is able to consume the kinesis data!!**
- Kinesis Firehose
- AWS Lambda

### SDK

- Classic Kinesis - Records are polled by consumers from a shard
- Each shard has 2MB total aggregate throughput. 

So if the kinesis data stream has N shards, then consumer application A makes GetRecords() request to the shard number 1, and the shard 1 is responsible for providing the data. (This is polling mechanism)

- GetRecords returns up to 10MB of data ( then throttle for 5 seconds ) or up to 10000 records. (5 second = 10MB/2MB(throughput))
- Maximum of 5 GetRecords API calls per shard per second = 200ms latency
- **If 5 consumers application consume from the same shard, means every consumer can poll once a second (200ms * 5) and receive less than 400KB/s (=2MB / 5))**

### KCL (Kinesis Client Library)

- Java-first library
- Read records from Kinesis produced with the KPL (de-aggregation)
- Share multiple shards with multiple consumers in one "group", shard discovery
- Checkpointing feature to resume progress. It tracks where it was consuming right before the failure.
- How does checkpointing and shard discovery works? Amazon DynamoDB checkpoints the progress over time and synchronize to see who is going to read which shard. 
- (In other words) Leverages **DynamoDB** for coordination and checkpointing (one row per shard).
    - We have to provision appropriate DB schema. Questions like:
    - Does it have enough WCU (write capability unit) / RCU (read capability unit)?
    - Use on-demand for DynamoDB
    - **Otherwise DynamoDB would be throttle, so it may slow down KCL**

- Records processors will process the data

### Kinesis Connector Library (KINDA deprecated)

- Older Java library, leverages the KCL library.
- write data to, amazon S3, DynamoDB, RedShift, ElasticSearch
- Kinesis Connector Library must be running on an EC2 instance.
- Focusing is on sending the data to other application. (Take data from data stream and send it to different destinations!)
- Actually, this job is replaceable. Sending to S3 and RedShift can be done by Kinesis Firehose. And other things can be done by Lambda.

### AWS Lambda sourcing from Kinesis

- AWS Lambda can source records from Kinesis Data Streams
- Lambda consumer has a library to de-aggregate record from the KPL
- Lambda can be used to run lightweight ETL (Extract, Transform, Load) to: S3, DynamoDB, RedShift, ElasticSearch, ... 
- Also can be used to trigger notifications / send emails in real time (SNS)..
- Already has a configurable batch size (can be customized)

## Kinesis Enhanced Fan Out

- New **GAME CHANGING** feature from August 2018.
- Works with KCL 2.0 and AWS lambda.
- Each Consumer get 2MB/s of provisioned throughput per shard. There is no polling from the shard. Shard just **pushes** data to the consumer!
- 20 consumers? No prob. They will get 40MB/s per shard aggregated.
- No more 2MB/s limit. 

How did the kinesis enhanced fan out did this? **Pushes the data to consumers** over HTTP/2

Outstanding benefits:

- We can scale a lot more consumer applications
- Reduced latency (~ 70ms)

Recall that In the consumer classic, there was 200 ms of latency if there are only one consumer. And More consumer just all add to one second latency. 

### Enhanced Fan-out vs Standard consumers

- Standard consumers:

1. low number of consuming applications (1,2,...)
2. can tolerate ~200ms latency
3. minimize cost

- Enhanced fan out consumers

1. Multiple consumer applications for the same stream
2. low latency requirements ~ 70ms
3. higher cost 
4. Default limit (soft limit) of 5 consumers but can be relieved by mailing a service request on AWS support.

