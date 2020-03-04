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

![image](https://user-images.githubusercontent.com/34101059/75790405-81b46f80-5dae-11ea-84ce-4965d2825aba.png)

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

## Kinesis Scaling

### Adding shards

- called "shard splitting"
- stream capacity is increased (1MB/s data in per shard)
- divide a "hot shard"
- the old shard is closed and will be deleted once the data is expired.

### Merging shards

- Decreasing the stream capacity and save costs
- Can be used to group two shards with low traffic
- Old shards are closed and deleted based on data expiration.

### Auto scaling (Manual)

- It is not a native feature of Kinesis
- The API call to change the number of shards is UpdateShardCount.
- We can implement Auto Scaling with AWS Lambda
- [AdditionalNote](https://aws.amazon.com/ko/blogs/big-data/scaling-amazon-kinesis-data-streams-with-aws-application-auto-scaling/)

### Scaling Limitation

- Resharding cannot be done in parallel. Plan capacity in advance
- Only perform one resharding operation at a time and it takes a few seconds
- For 1000 shards, it takes 8.3 hours to double the shards to 2000.
- **Not instantaneous**

- You can't do the following (you can't scale up/down to quickly, abruptly):
    - scale more than twice for each rolling 24-hour period for each stream
    - Scale up to more than double
    - scale down below half
    - scale up to more than 500 shards
    - scale a stream with more than 500 shards down unless the result is fewer than 500 shards. (1200 -> 600 (-600) X, 1000 -> 400 O)
    - Scale up to more than the shard limit for your account

## Kinesis Security (More on security)

- Control access / authorization using IAM policies
- Encryption in transit using HTTPS endpoints
- Encryption at rest using KMS
- client side Encryption must be manually implemented.
- VPC endpoints available for Kinesis to access within VPC.

## Kinesis Firehose (finally...!)

- Fully Managed Services, no administration
- **Near Real time** (60 seconds latency minimum for non full batches) (it is not send to destination immediately)
- Load data into RedShift / Amazon S3 / ElasticSearch / Splunk
- Automatic scaling (unlike kinesis stream)
- Supports many data formats
- Data conversions from JSON to Parquet / ORC (only for S3)
- Data transformation through AWS Lambda (ex: CSV -> JSON,,,)
- Supports compression when target is Amazon S3(GZIP, ZIP, and SNAPPY)
- only GZIP is the data is further loaded to RedShift
- Pay for the amount of data going through Firehose (No planned provision needed)
- **Spark / KCL do not read from Kinesis Data Firehose**

### Diagram

SDK, KPL, Kinesis Agent, Kinesis Data Stream, CloudWatch Logs & Events, IoT rules actions as a producer

Firehose can handle transformation with a conjunction with AWS Lambda

S3, RedShift, ElasticSearch, Splunk as a destination

### Delivery Diagram

Source delivers stream to firehose. Firehose can do some data conversion with the AWS Lambda (CSV -> JSON...) Several blueprint templates available for Lambda.

Then, the fomatted data can be sent to S3. If the destination is redshift, technically, it will go into S3 first, and there will be a copy command to put that data into redshift.

Without the conjunction of Lambda, we can **get all the source data into an Amazon S3 bucket** by kinesis firehose!

Also, it could be a good archiving tool when there's a transformation failures in Lambda or delivery failure. 

You may not lose your data in firehose. 

### Firehose Buffer Sizing

- Question: How does firehose sends data to the destination?
- Firehose accumulates records in a buffer
- The buffer is flushed based on time and size rules

- Buffer Size (ex: 32MB): if that buffer size is reached, it's flushed.
- Buffer time (ex: 2 minutes): if that time is reached, it's flushed.
- Firehose can **automatically** increase the buffer size to increase throughput.

- High throughput -> buffer size will be hit
- low throughput -> buffer time(minimum:1min) will be hit

### Kinesis Data Streams vs Firehose

- Streams
    - Going to write custom code for producer and consumer
    - Real time (~200ms latency for classic, ~70ms latency for enhanced fan-out)
    - Must manage scaling (shard splitting/merging)
    - Data storage for 1 to 7 days, replay capability, multi consumers
    - Use with lambda to insert data in real-time to ElasticSearch.

- Firehose
    - Fully managed, send to S3, RedShift, Splunk, ElasticSearch.
    - Serverless data transformation with Lambda
    - Near real time (lowest buffer time is 1 minute)
    - Automated Scaling
    - No data storage

### Let's use the Kinesis Data Firehose!

First, down load the LogGenerator.py. By executing the python code, it will fetch the data into the log format in your desired directory (/var/log/cadabra/). And then, modify the agent.json (/etc/aws-kinesis) and match the filePattern and deliveryStream. Then you are done! Just turn on the aws-kinesis-agent. And by the configuration you made when you made your own kinesis firehose, the logs are in S3 (by 5MB buffer size).

We want to make Order History Application.

In order to make this work, we need to publish Server logs from EC2 (already done). And now, server logs will go into kinesis streams (not kinesis firehose) so that the state is accessible in real time. Later, it will pass through AWS Lambda and DynamoDB, to client application.

But let's focus on Kinesis Data Stream for now.

### Let's use Kinesis Data Stream

"flows" tag in agent.json controls it all. Configure the right filePattern and kinesisStream, and also make dataProcessingOptions in order to csv2json. It costs a fortune. 

# SQS

Producer Sends message to SQS queue. And the consumers poll messages from the queue. 

## Standard Queue

- Oldest offering
- Fewest managed
- Scales from 1 message per second to 10000 messages per second.
- Default retention of messages: 4 days, maximum of 14 days
- No limit to how many messages can be in the queue
- Low latency (<10ms on publish and receive)
- Horizontal scaling in terms of number of consumers
- Can have duplicate messages
- Can have out of order messages
- Limitation of 256KB per message sent

## Producing Messages

- Define Body (up to 256KB)
- Add message attributes (metadata - optional)
- provide delay delivery (optional)

And that message is sent to SQS. Then you get back message identifier and MD5 hash of the body.

## Consuming Messages

- Poll SQS for messages (receive up to 10 messages at a time)
- Process the message within the visibility timeout
- Then Delete the message using the message ID & receipt handle
- Therefore, message cannot be consumed by multiple consumer applications. (since it's deleted after processing)


## FIFO queue

- name of the queue must end in .fifo
- lower throughtput (up to 3000 per second with batching 300/s without)
- messages are processed in order by the consumer
- messages are sent exactly once
- 5 minute interval de-duplication using "Duplication ID"

## SQS Extended Client

- How to send large messages (over 256KB)
- Using the SQS extended client (Java Library)

![image](https://user-images.githubusercontent.com/34101059/75851379-dc8cac00-5e2c-11ea-9602-4886fe29cb28.png)

## SQS Use case

- Decouple applications
- Buffer writes to a database
- Handle large loads of messages coming in
- SQS can be integrated with auto scaling using CloudWatch!

## SQS Limits

- Maximum of 120,000 in-flight messages being processed by consumers
- Batch request has a maximum of 10 messages - max 256KB
- Message content is XML, JSON, Unformatted text
- Standard Queues have an unlimited TPS
- FIFO queue support up to 3000 messages per second (using batching)
- Max message size is 256KB (or use extended client)
- Data retention from 1 minute to 14 days
- Pricing, (pay per API request, pay per network usage)

## SQS Security

- Encryption in transit using the HTTPS endpoint
- Can enable SSE (server side encryption) using KMS
    - can set the CMK (customer master key) we want to use
    - SSE only encrypts the body, not the metadata
- IAM policy must allow usage of SQS
- SQS queue access policy
    - finer grained control over IP
    - control over the time the requests come in.

## (Important) Kinesis Streams VS SQS

- Kinesis Data Stream:
    - Data can be consumed many times
    - Data is deleted after the retention period
    - Ordering of records is preserved (at the shard level) - even during replays
    - Build multiple applications reading from the same stream independently (Pub/Sub)
    - Streaming MapReduce querying capability by using Spark or somethign...
    - Check pointing needed to track progress of consumption
    - Shard (capacity) must be provided ahead of time

- SQS:
    - Queue, decouple application
    - One application per queue
    - Records are deleted after consumption
    - Messages are processed independently for standard queue
    - Ordering for FIFO queues
    - Capability to delay messages
    - Dynamic scaling of load (no-ops)
    - message object size is 256KB (whereas kinesis stream has up to 1MB)

![image](https://user-images.githubusercontent.com/34101059/75851949-3d68b400-5e2e-11ea-9198-13cc10ec8af3.png)

## SQS vs Kinesis - Use cases

- SQS use cases (decoupling from a developer's perspective):
    - order processing
    - image processing
    - Auto scaling queues according to messages
    - buffer and batch messages for future processing
    - request offloading

- Amazon Kinesis Data Streams (big data streaming)
    - Fast log and event data collection and processing
    - Real Time metrics and reports
    - Mobile data capture
    - Real time data analytics
    - gaming data feed
    - complex stream processing

# IoT

## Overview

- Internet of Things
- We deploy IoT devices ("Things") (IoT Thing) ex. thermostat, light bulb,... physical device
- We configure them and retrieve data from them

- It's going to have thing registry. Giving the device and ID, handling authentication,,, security all that stuff.
- Still, IoT thing should communicate with our cloud. For this, it uses **Device Gateway**
- Device gateway is a managed service which allows you to communicate with your IoT things 
- (e.x. temperature is over 30 Celsius) then, **IoT message broker** gets the message, and it is sending the message to somewhere like **IoT rules engine** IoT rules engine will send that message to Kinesis, SQS, Lambda, ... etc.
- Or IoT message broker can be integrated with **Device Shadow**. Even if the IoT things like thermostat is not connected to internet right now, the state is restored in device shadow (make temperature 20 degree). And when the thing is connected to internet, device shadow can tell the thing : adjust the temperature to 30 degree.

## IoT Tutorial

- Device Gateway : So the things are not connected in direct manner, but they are connected via Device Gateway which is manifested in cloud environment. 
- Rules Engine : It contains a bunch of rules that you can define allowing you to modify the behavior of your devices based on your own rules (G -> B)
- Rules Actions : It can send data to Kinesis, SQS, DynamoDB,... It sends data to many different targets within AWS. (if red button is pushed, send an SNS notification). Device doesn't interact with AWS application directly!
- Device shadow : It's kind of register, stand-by device for unconnected thing. It restores the requested state. (even if wifi in my home stops, the shadow device must be updated to track the request) By this, you can control your off-line device.

## Let's deep dive into each component!

### IoT Device Gateway

- Serves as the entry point for IoT devices connecting to AWS
- Allows devices to securely and efficiently communicate with AWS IoT
- Supports MQTT, Web Sockets, and HTTP 1.1 protocols.
- Fully managed and scales automatically to support over a billion devices
- No need to manage any infrastructure (like server less)

### IoT message broker

- Pub/Sub messaging pattern - low latency
- Devices can communicate with one another this way
- messages sent using the MQTT, Web Sockets, or HTTP 1.1 protocls
- messages are published into topics (just like SNS)
- Message broker forwards messages to all clients connected to the topic
- So it can orchestrate all our devices using message broker.

### IoT thing registry =(sort of) IAM of IoT

- All connected IoT devices are represented in the AWS IoT registry
- Organizes the resources associated with each device in the AWS Cloud
- Each device gets a unique ID
- Supports metadata for each device (e.x. Celsius vs Fahrenheit...)
- Can create X.509 certificate to help IoT devices connect to AWS
- IoT groups : group devices together and apply their permissions.

#### How Authentication works?

1. Create X.509 Certificates and load them securely onto the Things
2. AWS SigV4
3. Custom token with Custom authorizers

- For mobile applications:
    - Cognito identities (extension to Google, Facebook login)
- Web/Desktop/CLI:
    - IAM
    - Federated Policies

- AWS IoT policies (governs IoT things, actual device):
    - attached to X.509 certificates or Cognito identities
    - Able to revoke any device at any time
    - IoT policies are JSON documents
    - Can be attached to groups!

- IAM policies (governs users,group, roles):
    - attached to users, group, or roles
    - Used for controlling IoT AWS **API**s

### Device Shadow (resides in AWS cloud)

- JSON document representing the state of a connected Thing
- We can set the state to a different desired state (ex: light on)
- The IoT thing will retrieve the state when online and adapt

### Rules Engine

- Rules are defined on the MQTT topics
- Rules = when it's triggered
- Actions = what is does
- Rules are like:
    - augment data received from a device
    - save a file to S3
    - invoke a Lambda function
    - Write data to DynamoDB database
- Rules need IAM roles to perform their actions

So how would you get IoT devices to send data to kinesis? It is not use directly a put record on the device but define IoT rule action. 

### IoT Greengrass

- Brings the compute layer to the device directly
- Can execute AWS Lambda functions on the devices: like IoT coffee pot!
    - pre-process the data
    - execute predictions based on ML models
    - communicate between local devices
- also operates off-line
- deploy functions from the cloud directly to the devices.

# Database Migration Service

You might want to move from a database on premise into the cloud environment. How do you want to do that? Replication?

- Quickly and securely migrate database to AWS, resilient, self healing
- The source database remains available even during the migration

- Supports:
    - Homogeneous migration: ex) Oracle to Oracle
    - Heterogeneous migration ex) Microsoft SQL server to Aurora

- How? Continuous Data Replication using CDC 
- You must create an EC2 instance to perform the replication tasks


## DMS sources and Targets

Sources:

- On-premise and EC2 instances database, Oracle, Ms SQL, MySQL, MariaDB, Amazon RDS, Amazon S3

Target:

- Oracle, ...., . . .,. . Amazon RDS, RedShift, DynamoDB, S3, ElasticSearch, Kinesis stream, ...

## AWS Schema Conversion Tool (SCT)

- Convert your database's schema from one engine to another
- OLTP ex) (SQL server or oracle) to MySQL, PostgreSQL, Aurora...
- OLAP ex) (Teradata or Oracle) to Amazon Redshift

- You can use AWS SCT to create AWS DMS endpoints and tasks

- You may need to create an endpoint for each replication source and target that we want to have.


# Direct Connect

**remember : In the case of big data: It allows you to put a lot of data over a dedicated network line which is pretty reliable**

Did this before! Provides a dedicated **private** connection from a remote network to your VPC. 

- Can setup multiple 1 Gbps or 10 Gbps dedicated netowrk connections
- Setup Dedicated connection between your DC and Direct Connect locations
- You need to setup a Virtual Private Gateway on your VPC
- Access public resources (S3) and private (EC2) on same connection

- Use case:
    - increase bandwidth throughput - working with large data sets - lower cost
    - more consistent network experience
    - Hybrid environment (on premise + cloud)
    - enhanced security

- supports both IPv4 and IPv6
- high-availability : Two DC as failover or use Site-to-Site VPN as a failover.

## Direct Connect Gateway

In case you want to setup a Direct Connect to **one or more** VPC in many different regions (for same account)

# Snowball

- **Physical** data transport solution that helps moving TBs or PBs of data in or out of AWS
- Alternative to moving data over the network (it hits the road!)
- Secure, tamper resistant, uses KMS 256 bit encryption.
- Tracking using SNS...
- Pay per data transfer job
- Data center decomission, disaster recovery, large data cloud migrations.

- If it takes more than a week to transfer over the network, use Snowball instead.

## Process?

1. request snowball devices from the AWS console for delivery
2. install the snowball client on your server
3. connect the snowball to your servers and copy files using the client
4. ship back the device (it then goes to the right AWS facility)
5. data will be loaded into an S3 bucket
6. snowball is completely wiped

## Diagram

- Direct upload to S3? via a internet? 10Gbit/s internet-imposed limits
- With snowball via shipping.

## Snowball Edge (for exporting EC2 AMI)

- Snowball device with computational capability
- Supports a custom EC2 AMI so you can perform processing on the go
- supports custom lambda functions
- Very useful to pre-process the data while moving

## AWS Snowmobile

MASSIVE MASSIVE TRUCK. supports exabytes of data.

If the data is more than 10 PB, better than snowball.


