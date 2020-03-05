# What is the key components in processing?

AWS Lambda, AWS Glue, Elastic MapReduce (managed hadoop cluster, allowing you to run a variety of tools for processing massive datasets), AWS SageMaker, AWS data pipeline.


# AWS Lambda

Serverless data processing

- A way to run code snippets in the cloud (serverless, continuous scaling)
- Automatically scales out. No configuration of EC2 instance needed

## Use case: Serverless Website

Log in request will go through 1. API Gateway, 2. Lambda (OK able to log in), 3. Amazon Cognito (Provides Token), or Amazon DynamoDB (browses log-in history) 

## Use case : Order history application

Server logs go through kinesis streams, lambda (triggers of events from the data stream and extract each individual record then turn around and write that into DynamoDB), DynamoDB, then client application.

## Why not just run a server?

- server management (patches, monitoring, hardware failures)
- Servers can be cheap, but scaling gets expensive really fast
- You don't pay for processing time you don't use
- Easier to split up development between front-end and back-end

## Main uses

- Real-time file processing
- Real-time stream processing
- ETL (Extract, Transform, Load)
- Process AWS events
- Cron replacement (fixed schedule, triggered by time amount)

S3, Kinesis, DynamoDB, SNS and SQS and IoT etc.... can trigger lambda function

**But lambda is actually pulling the Kinesis Stream, Kinesis stream is not push to lambda**

## More interesting Use case

S3 -> Lambda -> ElasticSearch service

Object creation in S3 triggers the lambda -> and processed data sent to ElasticSearch service.

## Use case 2

Consider a case of copying data to RedShift. S3 -> Lambda -> RedShift ? 

But lambda cannot have any stateful information. It is absurd to copy data by a record. We want to make a batch of it instead. But the lambda function cannot pass some information from one lambda call to the next (bc. stateful). So, we might associate lambda with DynamoDB, not only with RedShift. DynamoDB tells us "I can actually batch things up and send it to RedShift". Using DynamoDB to track of how much data has been received so far.

## Lambda + Kinesis

- Your lambda code receives an event with a batch of stream records (It may not gonna invoked for every single record)
    - You specify a batch size when setting up the trigger (up to 10000 records)
    - Too large batch size can cause timeouts!
    - Batches may also be split beyond Lambda's payload limit (6MB)

- Lambda will retry the batch until it succeeds or the data expires
    - **This can stall the shard** if you don't handle errors properly
    - Use more shards to ensure processing isn't totally held up by errors (even one shard fails, another shards will be computed)

- Lambda processes shard data synchronously

- Streams should be in the same account. Stream from another account cannot be handled by a single lambda function.

## More on Lambda

- Pay for what you use
- Paid for memory consumed + number of requests
- high availability
- unlimited scalability (there is a safety throttle of 1000 concurrent executions per region, which is even a soft limit)
- high performance (But you can specify a timeout. Maximum timeout is 900 seconds)

## Anti-patterns

- Long-running application
- Dynamic Websites (instead use EC2 and CloudFront)
- Stateful Applications (you can't maintain information from one lambda call to another) (But as we mentioned, you can maintain DynamoDB or S3 just to store some shared environment)


# AWS Glue (Serverless! Fully Managed!)

It defines table definitions and perform ETL on your underlying data lake and provide structure to unstructured data.

It is usually used to serve as a central metadata repository for your data lake in S3, so it's able to discover schemas or table definitions and publish those for use with analysis tools such as Athena, RedShift, or EMR

## Glue Crawler / Data Catalog

Scans your data in S3 and often the glue crawler will infer a schema automatically just based on the structure of the data. 

e.x. csv or TSV data sitting in S3, it will automatically break out those columns.

You can schedule that crawler to run periodically. So if there are new data or new types of data popping into S3 at random times, Glue can discover those automatically.

## Glue Crawler / Data Catalog

Scans your data in S3 and often the glue crawler will infer a schema automatically just based on the structure of the data. 

e.x. csv or TSV data sitting in S3, it will automatically break out those columns.

You can schedule that crawler to run periodically. So if there are new data or new types of data popping into S3 at random times, Glue can discover those automatically.

When the glue crawler is scanning your data and S3 will populate what's called the glue data catalogue. Glue data catalogue is a central meta-data repository used by all the other tools.

The data itself remains where it was originally in S3. Only the **table definition itself (e.x. column names, types of data in the column...)** is stored by glue in the glue data catalog.

Data catalog tells theses other services how to interpret that data and how it's structures.

## Glue and S3 partitions

- Glue crawler will extract partitions based on how your S3 data is organized.
- So before you store your data in S3, you will think how the data would be queried beforehand.
- Do you query primarily by time ranges? (directory by yyyy/mm/dd/device)
- Do you query primarily by device? (directory by device/yyyy/mm/dd)

## Glue + Hive

Hive is a service that runs on Elastic MapReduce that allows you to issue SQL like queries on data. And also can integrate with glue

How?

> You can use your AWS glue data catalog as your metadata store for hive 
> Import Hive Meta store into glue

## Glue ETL

- Transform data, Clean Data, Enrich Data (before doing analysis)
    - Generate ETL code in Python or Scala, you can modify the code
    - Can provide your own Spark or PySpark scripts
    - Target (output) can be S3, JDBC (RDS, RedShift), or in Glue Data Catalog
- Fully managed, cost effective
- Jobs are run on serverless Spark platform
- Glue Scheduler to schedule the jobs
- Glue Triggers to automate job runs based on "events"



- Automatic code generation
- Scala or Python
- Encryption
    - Server-side (at rest)
    - SSL (in transit)
- Can be event-driven
- Can provision additional "DPU's" (Data Processing Units) to increase performance of underlying Spark jobs.
- Errors reported to cloud watch


### Glue ETL - Transformation

- Bundled Transformations:
    - DropFields, DropNullFields - remove (null) fields
    - Filter - specify a function to filter records
    - Join - to enrich data
    - Map - add fields, delete fields, perform external lookups
- Machine Learning Transformations:
    - **FindMatches ML** : identify duplicate or matching records in your dataset, even when the records do not have a common unique identifier and no fields match exactly
- Format Conversions : CSV, JSON, Avro, **Parquet**, ORC, XML
- Apache Spark transformations (e.x. K-means)

#### Glue Development Endpoints (supports debug, and run...)

- Develop ETL scripts using a notebook
    - Then create ETL job that runs your script (using Spark and Glue)
- Endpoints is in a VPC controlled by security groups, connect via
    - Use Elastic IP's to access a private endpoint...
    - Sage Maker notebook
    - PyCharm professional edition
    - Zeppelin notebook server on EC2
    - So long and so forth

#### Running Glue jobs

- Time-based schedules (cron style)
- **Job bookmarks (pick up where you left, and resume the job from that point)**
    - Persists state from the job run (only new data will be picked)
    - prevents reprocessing of old data
    - Allows you to process new data only when re-running on a schedule
    - Works with S3 sources
    - Works with relational databases via JDBC (but only if Primary Key's are in sequential order) (caveat: only handles new rows, not updated rows)
- CloudWatch Events
    - Fire off a Lambda function or SNS notification when ETL succeeds or fails
    - invoke EC2 run, send event to Kinesis, activate a Step Function

## Glue Cost Model

- Billed by the minute(CPU time) for crawler and ETL jobs
- First million objects stored and accesses are free for the Glue Data Catalog (pretty much the same with Lambda)
- Development endpoints for developing ETL code charged by the minute.

## Glue Anti patterns

- Streaming Data (Glue is batch oriented, minimum 5 minute intervals. whereas for video, fps... cannot afford that)
    - if you want to ETL your data while streaming it, perform your ETL using Kinesis, store the data in S3 or RedShift, and then trigger glue ETL to continue transforming it.
- Multiple ETL engines (other than Spark) (if you want to use multiple ETL engines such as Hive or pig, you might wanna use **Data Pipeline, or EMR** than ETL)
- NoSQL databases (e.x. DynamoDB) (In nature, it need not strict,fixed schema)

# EMR Elastic MapReduce

- Managed Hadoop framework on **EC2 instances**
- Includes Spark, HBase, Presto, Flink, Hive 
- EMR Notebooks (interactively query data)
- Several (built-in) integration points with AWS 

## An EMR Cluster

It is a collection of EC2 instances at the end.

- Master Node : manages, coordinates the cluster (single EC2 instance)
- Core node : Hosts HDFS (Hadoop Distributed File System) data and runs tasks (can be scaled up & down but with some risk) -> runs task + storing data
- Task Node : runs tasks, does not host data (no risk of data loss when removing, **good use of spot instances**) -> runs task, no storage of data

## EMR usage

- Transient(deleted after the task completion) vs Long-Running Clusters
    - can spin up task nodes using Spot instances for temporary capacity
    - Can use Reserved Instances on long-running clusters
- Connect directly to master to run jobs
- Submit ordered steps via the console


