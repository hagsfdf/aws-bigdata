# AWS Services Integration

## IoT

There was IoT topic, IoT Rules, and IoT Rules Actions. There are variety of destinations to rules actions (Kinesis, DynamoDB, SNS, S3, Lambda, SQS + many others)

## Kinesis Data Streams

In Producer side, SDK, KPL, Kinesis Agent, 3rd party libraries like Spark, Apache Kafka

In Consumer side, SDK, KCL, Kinesis Connector Library, AWS Lambda, 3rd party libraries like Spark, Firehose, ...

## Kinesis Data Firehose

Reads from SDK, KPL, Kinesis Agent, Kinesis Data Streams, CloudWatch Logs & Events, IoT rules actions ...

Often integrated with Lambda for data conversion... 

Can mecha-kucha data to S3, RedShift, Splunk, ElasticSearch

## Kinesis Data Analytics

Get data from Kinesis Data Streams, Kinesis Data Firehose, or Reference Data (JSON, CSV) in S3. 

We can pre-process the record conjunction with AWS Lambda

The result of the continuous running analytic queries can go into Kinesis Data Streams, Firehose, or Lambda function for further processing (e.x. SNS)

## SQS

Receives data from 1. SDK-based application (EC2, ECS, etc,) 2. IoT Core (Rules Engine) 3. S3 events (new files)

\1. SDK-based application (EC2, ECS, etc,...) and 2. Lambda can read from SQS

## S3

Snowball, Snowball Edge, Firehose, Redshift, Athena, Glue, EMR (when we use EMRFS), AWS DMS, IoT Core, Data Pipeline, and so many more things can send data to S3 bucket

Send notification to AWS Lambda, SQS Queue, SNS topic ,... 

## DynamoDB

![image](https://user-images.githubusercontent.com/34101059/76693700-18393880-66ad-11ea-9432-94fc11540ed0.png)

0. Client SDK can write to DynamoDB, how obvious it is!
1. DMS if you want to basically transfer data from something like MySQL into DynamoDB
2. AWS Data Pipeline, you can use batch running ETL this way.
3. DynamoDB Streams if you want to have your change log. And that log can plugged into AWS Lambda function or Kinesis Client Library with DynamoDB adaptor (by using KCL, you can deploy an application on say, EC2).
4. Glue, glue will get all the table's metadata into glue data catalog.
5. EMR can read from DynamoDB using Hive.

## Glue

Sources can be 1. DynamoDB, 2. Amazon S3, 3. Any JDBC (e.x. RDS, any on-premise database only if it's compliant with JDBC)

1. Glue crawlers now will retrieve the schema, retrieve the table name..
2. And it will create glue data catalog

Glue Data catalog can be used in 1. Redshift Spectrum 2. Athena, 3. EMR + Hive

## EMR

Hadoop, Spark, Hive, Pig, Presto, HBase, Jupyter, Zeppelin, Flink

What does it integrate with? Amazon S3 / EMRFS , DynamoDB (Hive does it), Apache Ranger On EC2 (user security fire wall), Glue Data Catalog as some kind of source.

## Amazon Machine Learning (Deprecated)

Sources data from S3 or RedShift, and exposes Predictions API

## Amazon SageMaker

It has tensorflow, pytorch, and mxnet, and many other machine learning framework

Source data **only from S3**, make model with aid of Notebook, then deploy model

## AWS Data pipeline

Interacts with S3, JDBC (e.x. RDS), EMR / Hive, DynamoDB or any other service... 

So it's about batch processing

## ElasticSearch Service

The service is only a part of Elastic Stack

1. ElasticSearch
2. Kibana (Visualization)
3. LogStash (streaming log data to ES)

What service sends data to ES? Data Firehose, IoT Core, CloudWatch Logs

In terms of **Access** to ES, there are IAM and Cognito

## Athena

We can only query data from S3, and the metadata might be stored in Glue Data Catalog

Result would go back to S3

Athena integrates with QuickSight. QuickSight use Athena as a database engine to query some data directly in S3.

## RedShift

Interacts with S3 by COPY / LOAD / UNLOAD or RedShift Spectrum (it you are not to touch the data in S3)

QuickSight Integration. 

PostgreSQL (DBLINK)

## QuickSight

Lots of integration point. Sources data from RDS / JDBC, RedShift, Athena, Amazon S3, Excel, terdata, Jira, salesfores,...

# Instance types for Big Data

- General Purpose : T2, T3, M4, M5
- Compute Optimized : C4, C5
    - Batch processing, Distributed Analytics, Machine / deep learning inference (serving the model)
- Memory optimized : R4, R5, X1, Z1d
    - High performance database, in memory database, real time big data analytics (HBase?)
- Accelerated computing : P2, P3, G3, F1
    - GPU instance, Machine or Deep learning, High Performance computing
- Storage optimized : H1, I3, D2
    - Distributed FS (HDFS), NFS, MapReduce, Apache Kafka, RedShift (especially, D2)

Common Questions

- We will use Spark a lot -> memory optimized! R type instance, X1, Z1d
- tf, MXnet -> Accelerated computing! -> P2, P3, G3, F1,


