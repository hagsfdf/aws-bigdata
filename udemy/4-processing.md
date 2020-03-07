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

- Master Node : manages, coordinates the cluster (single EC2 instance). Minimal number of functioning EMR cluster
- Core node : Hosts HDFS (Hadoop Distributed File System) data and runs tasks (can be scaled up & down but with some risk) -> runs task + storing data
- Task Node : runs tasks, does not host data (no risk of data loss when removing, **good use of spot instances**) -> runs task, no storage of data

## EMR usage

- Transient(deleted after the task completion) vs Long-Running Clusters
    - can spin up task nodes using Spot instances for temporary capacity
    - Can use Reserved Instances on long-running clusters
- Connect directly to master to run jobs
- Submit ordered steps via the console

## EMR / AWS integration

- Amazon EC2 for the instances that comprise the nodes in the cluster
- Amazon VPC to configure the virtual network in which you launch your instances
- Amazon S3 to store input and output data
- Amazon CloudWatch to monitor cluster performance and configure alarms
- AWS IAM to configure permissions
- AWS CloudTrail to audit requests made to the service
- AWS Data Pipeline to schedule and start your cluster

## EMR Storage

- HDFS Hadoop Distributed File System, distributes the data at stores across different instances in your cluster
    - If the cluster is shut down, the data is lost
    - But it stores multiple copies of your data on different instances and that ensures that no data is lost if an single instance fails
    - Each data is stored as blocks (broken up into blocks)
    - By default a block size is 128 megabytes (for processing)
    - It is ephemeral (Caching intermediate results, For workload that have random IO) (but not durable)
- EMRFS : access S3 as if it were HDFS (for backup purpose)
    - **EMRFS Consistent View** - optional for S3 consistency (ensures consistency during the numerous writes and read)
    - Uses DynamoDB (to store metadata) to track consistency
- Local File System (locally connected disks) (useful for storing caching, not persistent data)
- EBS for HDFS (cannot attach it to a running cluster, it must be a launching configuration)

- The only option to make data persistent is, EMRFS (S3 + HDFS)

## EMR promises

- EMR charges by the hour (whether you are using or not) (not kinda serverless)
    - + EC2 charges
- Provisions new nodes if a core node fails (automatically)
- Can add and remove tasks nodes on the fly
- Can resize a running cluster's core nodes

## So what is Hadoop?

- comprises of three modules : MapReduce, YARN, HDFS
- HDFS - ephemeral storage, robust to single instance fail
- YARN - yet another resource negotiator. Manages what gets run where.
- MapReduce - Sofeware framework for writing applications that process vast amounts of data in parallel in a reliable fault tolerant manner.

## Apache Spark

Spark is taking the place of MapReduce

- In-memory caching
- Directed acyclic graphs to optimize its query execution
- It is not the best way to perform OLTP or batch processing
- Not for real time usage
- More for analytical applications

![image](https://user-images.githubusercontent.com/34101059/76137970-12789d00-6086-11ea-8e8b-9f7f5ec59fe9.png)

Spark Components

SPARK CORE at the core level - dealing with Resilient Distributed Dataset

And at the top of that, there are 1. Spark Streaming (enables real time analytics by mini batching and fast scheduling), 2. Spark SQL, 3. MLlib, 4. GraphX

### Spark Streaming

- Spark Structured Streaming handles data like a database table that keeps on growing forever
- new data in stream = new rows appended to input table

#### Spark Streaming + Kinesis

- Kinesis producer (EC2 host generating logs), Spark Dataset implemented from KCL

#### Spark + RedShift

- spark-redshift package allows spark datasets from Redshift (redshift here just acts as spark SQL data source)
- useful for ETL using Spark

## Apache Hive

Hive is a way to execute SQL code on your unstructured data.

**Hive exposes SQL interface to your underlying data stored on your EMR cluster**

From the block in Spark, Hive sits top of the MapReduce, with the aid of Tez (kind of Apache spark, using a in-memory acyclic graph).

Hierarchy will be as:

YARN -> MapReduce, Tez, -> Hive

### Why Hive

- Uses familiar SQL syntax (HiveQL)
- Scalable - works with "big data" on a cluster (most applicable for "data warehousing")
- Easy **OLAP queries**
- Highly extensible (User defined function, Thrift server, JDBC/ODBC driver)
- NOT for OLTP, not for quick query

### Hive metastore

- It maintains a metastore that imparts a structure you define on the unstructured data that is stored on HDFS
- Stores things like "These are the different columns, these are the column names, data types etc"

### External Hive Metastores

- Metastore is stored in MySQL on the master node by default.
- But this is not good, since metastore data is not ephemeral, and you might need the data after shutting the cluster down, or etc.
- SO external metastores offer better resiliency / integration. Store metastores in :
    - AWS Glue Data Catalog
    - Amazon RDS
And also, if you use these external hive metastore, the recipe to interpret this data as a structured one, is now exposed to other services like RedShift, Athena,...

### Other Hive / AWS integration points

- Load table partitions from S3 (e.x. subdirectories in S3 can be interpreted as a structured data "2019/05/a.csv", "2019/06/b.csv")...
- Write tables in S3 (without the use of temporary files)
- Load scripts from S3
- DynamoDB as an external table
    - For this need, you need to define external hive table based on your DynamoDB data
    - Then use hive to analyze the data stored in DynamoDB, or load the results back to DynamoDB, or archive them into S3.
    - It also allows you to copy data from a DynamoDB into EMRFS or HDFS and vice versa
    - Also, you can perform joint operations between DynamoDB table by using hive


## Apache Pig

- Alternative interface to MapReduce.
- Writing mappers and reducers by hand takes a long time.
- Pig introduces *pig latin*, a high-level scripting language that lets you use SQL-like syntax to define map / reduce steps
- Highly extensible with user-defined functions

The framework here is exactly the same as Hive, on the top of the HDFS, on the top of the YARN, on the top of the MapReduce or Tez, is Pig

### Pig / AWS integration

- Ability to use multiple file systems (not just limited to HDFS) (EMR friendly) (e.x. query data in S3)
- Load JAR's and scripts from S3

## HBase on EMR

- Non-relational, petabyte-scale database
- Based on Google's BigTable, on top of HDFS
- **In-memory**
- Hive integration (so you can issue SQL style command)

So you have unstructured data spread across your Hadoop cluster, HBase can treat that like a non relational database, and issue fast queries on it.

### Sounds a lot like DynamoDB

- Both are NoSQL databases!
- But if you are tied to AWS, DynamoDB is better:
    - Fully-managed (serverless)
    - more integration with other AWS services
    - Glue integration

- But HBase has its strong points like :
    - efficient storage of **sparse data**
    - appropriate for high frequency counters (consistent reads & writes)
    - high write & update throughput
    - more integration with Hadoop

In short, if you're looking to integrate with Hadoop itself, HBase offers more.

### AWS integration

- Can store data (StoreFiles and metadata) on S3 via EMRFS
- Can back up to S3

## Presto

- It can connect to **many different "big data" databases** at once, and query across them (think of join)
- **Interactive queries at petabyte scale**
- Familiar SQL syntax.
- Optimized for OLAP - analytical queries, data warehousing
- This is what Amazon Athena uses under the hood (Athena is a serverless version of presto)
- Exposes JDBC, Command-Line, and Tableau interfaces

### Presto Connectors

- HDFS
- S3
- Cassandra
- MongoDB
- HBase
- SQL
- RedShift
- Teradata

There are relational, non-relational database both. You can treat them all as a SQL interface.

Presto is even faster than Hive

All the process is very fast since it is done in memory and pipelined across the network in between stages.

BUT, it is still not appropriate choice for OLTP or batch processing

It is just an efficient interactive query tool for doing OLAP style queries.

## Zeppelin and EMR notebook

- If you're familiar with iPython notebooks (It is Zeppelin!)
- It's a web-based interface that allows you to write blocks of python code and see the results interactively.
- Zeppelin integrates with Spark, Python, JDBC, HBase, ElasticSearch + more

> So think of a Zeppelin as a way of scaling up an iPython notebook to an entire cluster and handling big data

### Zeppelin + Spark

- Can run Spark code interactively (visualization, easy experimentation!)
- Can execute SQL queries directly against SparkSQL
- Makes Spark feel more like a data science tool!

### EMR notebook

- Similar concept to Zeppelin, with more AWS integration
- Notebooks automatically backed up to S3 (EMR notebook exist outside of the cluster itself, commands like "do this thing, and shut the cluster down" is ok)
- Provision clusters from the notebook!
- Hosted inside a VPC
- Accessed only via AWS console


## Hue

- Hadoop User Experience
- Graphical, management **front-end** tool for applications on your EMR cluster
- IAM integration : Hue Super-users inherit IAM roles (browse and move data between HDFS or EMRFS)

## Splunk

- "Makes machine data accessible, usable, and valuable to everyone"
- Collecting and gathering data about the actual performance of your cluster and what it's doing => and presents it!
- But it can be independent to EMR. Just launching Linux Amazon OS and spin Splunk, outside the EMR
- **Operation tool** - can be used to visualize EMR and S3 data using your EMR Hadoop cluster

## Flume

- Another way to stream data into your cluster (like Kinesis!)
- Distributed service that allows you to efficiently collect, aggregate and move large amounts of log data in particular
- Designed for Log data coming in from a big fleet of web servers

![image](https://user-images.githubusercontent.com/34101059/76152875-13eaa980-6108-11ea-8cde-e605a4dc74e5.png)

> Alternative technology for handling streaming applications on an EMR cluster

## MXNet

- Like Tensorflow, a library for building and accelerating neural networks.
- Framework to build deep learning application

## S3DistCP

- Tool for copying large amounts of data
    - from S3 into HDFS
    - from HDFS into S3
- Uses MapReduce to copy in a distributed manner
- Suitable for parallel copying of large numbers of objects
    - Across buckets, across accounts

## Other EMR/ Hadoop tools (some are pre-installed, some are not.) (None of these are specific to EMR)

![image](https://user-images.githubusercontent.com/34101059/76152909-73e15000-6108-11ea-8588-f9ea9a7b5a06.png)

## EMR security

- IAM policies (grant or deny permissions and determine what actions the use can perform within your cluster and with other AWS resources)
- Kerberos (strong authentication) (Network authentication protocol that ensures that passwords or other credentials aren't sent over the network in an unencrypted format)
- SSH (provides a secure way for users to connect to the command line on cluster instances and it also provides tunneling so you can view web interfaces that are hosted on your master node of you cluster from outside of the cluster) (Kerberos and EC2 key pairs can be used to authenticate clients for SSH) (= encrypting data in transit)
- IAM roles (ways to inter-operate with other AWS services) (e.x. autoscaling on cluster? Attach the IAM role)

## Choosing Instance Types

- Master node:
    - m4.large if <50 node, m4.xlarge, if > 50 nodes
- Core & task nodes:
    - m4.large is generally good
    - Cluster waits a lot on external dependencies (long idle) (web crawler), t2.medium
    - Improved performance : m4.xlarge
    - computation-intensive applications (deep learning?) : high CPU instances
    - Database, memory-caching applications (HBase? Spark?): high memory instances
    - Network / CPU-intensive (NLP, ML) - cluster computer instances
- Spot instances
    - Good choice for task nodes
    - Only use on code & master if you're testing or very cost-sensitive; you're risking partial data loss

# Amazon Machine Learning (deprecated) 

ML with linear and logistic regression

- Supervised Learning (The property we want to predict is called a label)
    - Training data set contains labels known to be correct, together with the other attributes of the data

## Types of models

- Regression (predict numerical value, SHOPPING)
- Multi-class Classification (Is it a dog or cat or fish? Among three)
- Binary Classification (Is this biopsy result malignant?)

## Confusion Matrix

A way to visualize the accuracy of multi-class classification predictive models

## Hyper-parameters

- Learning rate
- Model size
- Number of passes
- Data shuffling
- Regularization

## Amazon ML

- Provides visualization tools & wizards to make creating a model easy
- You point it to training data in S3, RedShift, or RDS
- It builds a model that can make predictions using batches or a low-latency API
- Can do train/test and evaluate your model
- Fully managed (don't worry about provisioning servers ... etc.)

### Ideal Usage Patterns

- Personalization - predict items a user will be interested in
- Predict user activity
- Forecast product demand
- Classify social media (does this Tweet require my attention?)

### Cost Model

- Charged for compute time
- Number of predictions
- Memory used to run your model
- Compute-hours for training
- "Pay for what you use!"

### Promises & Limitations

- No downtime
- Up to 100GB training data (more via support ticket)
- Up to 5 simultaneous jobs (more via support ticket)

### Anti-Patterns

- Terabyte-scale data
- Unsupported learning tasks 
    - Sequence prediction (LSTM, RNN)
    - Unsupervised clustering
    - Deep learning
- EMR / Spark is an (unmanaged) alternative

# SageMaker

Scalable, **fully-managed** machine learning

Allows you to create notebooks hosted on AWS that can train large scale models in the cloud!

## SageMaker Neo

A new Amazon SageMaker capability that enables machine learning models to train once and run anywhere in the cloud and at the edge?

## Three modules

### Build 

- provides a hosted environment, experimenting with algorithms and visualizing your output
- This is a stage where you're gonna be writing your python code in Jupyter notebook. And it is loaded with CUDA or CUDNN drivers
- Also includes Anaconda packages, tf, MXnet, pytorch...
- Built-in Reinforcement learning algorithms today

### Train

- One-click model training, and tuning at high scale and low cost
- SageMaker Search allows you to quickly find and evaluate the most relevant model from the multiple model training jobs.

### Deploy

- Easily host and test your models that will make predictions
- There's a batch transform mode that allows you to run predictions on large or small batch data.
- Enables you to deploy inference pipelines (from preprocessing and postprocessing to batch inference request, all-in-once)]


## SageMaker is powerful

- Tensorflow
- Apache MXNet
- GPU accelerated deep learning
- Scaling effectively unlimited
- Hyperparameter tuning job
- No fixed limits for size of data sets! 


## Security SageMaker

- Code stored in "ML storage volumes"
    - controlled by security groups
    - optionally encrypted at rest
- All artifacts encrypted in transit and at rest BY DEFAULT
- API & console secured by SSL
- IAM roles (control what service SageMaker can talk to)
- KMS integration fro SageMaker notebooks, training jobs, endpoints

- Also can integrate with CloudWatch and CloudTrail... 

# AWS Data Pipeline

Lets you schedule tasks for processing your big data

Suppose a scenario, that fleet of EC2 instances produce millions of log data, fed into S3, and analyzed in EMR. 

Data pipeline can "schedule" a daily task or whatever frequency you want to copy those log files from EC2 into S3. (e.x. storing to S3 every day, analyzing in EMR every week)

> Web service that helps you reliably process and move data between different AWS compute and storage services at specified intervals

## Data Pipeline Features

- Destinations include S3, RDS, DynamoDB, Redshift, and EMR
- Manages task dependencies
- Retries and notifies on failures
- cross-region pipeline
- precondition checks (are the sources ready to go? e.x. DynamoDBdataExists ? S3PrefixExists?, more customized version? shell command precondition)
- Data sources may be on-premises
- Highly available

## Data pipeline activities

- EMR (possible to spin up an EMR instance, run some steps, and automatically terminate it)
- Hive
- Copy
- SQL
- Scripts

By default an activity will retry three times before entering a hard failure state. You can increase the number of automatic retry up to 10. If the number of activity is exhausted, it will not try to run again unless we manually issue a rerun command by ourselves.

# AWS Step functions

Similar to Data Pipeline! **Designing Work Flows**

- Use to design work flows
- Easy visualization
- Advanced Error handling and retry mechanism outside the code
- Audit of the history of work flows
- Ability to "Wait" for an arbitrary amount of time
- Max execution time of a State Machine is 1 year ! (possible to long-live process)

One interesting use case is that it can "automate" the process of generating your data set and feeding it into a machine learning model (Hyperparameter tuning..)
