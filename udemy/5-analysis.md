# What we gonna cover?

Kinesis Analytics and ElasticSearch, Athena, RedShift

# Kinesis Analytics

- Receive data from either a Kinesis Data Stream of from the Kinesis Data Firehose
- It's always receiving never ending stream of data and you just write SQL to analyze the data. And spit out that result to other analytic tools

In depth, there are three main parts to Kinesis Analytics:

1. Source or Input data (kinesis stream, kinesis data firehose, also configuring a reference data source is available) (this is kind of lookup data, must store your reference data as an object in an S3 object)
2. Real time Analytics or the application code (actual analysis part) (it can operate over windows of time, so you can look back through fixed time period)
3. Destination, Output Stream, (Kinesis Data Stream, Kinesis Data Firehose is again available), also it can go to error stream if there was an error.

## Common use-case

- Streaming ETL (extract, transform, load)
    - application that continuously reads IoT sensor data stored in a Kinesis Data Stream, **organize that data by the sensor type, remove duplicates, normalize the data for a specified schema**, and deliver the processed data to S3.
- Continuous metric generation
    - Check the traffic to your website by calculating the number of unique web site visitors every five minutes
- Responsive analytics
    - application computing the success rate of a customer facing API over time and then sending those results on to Amazon CloudWatch

## Features of Kinesis Analytics

- Pay only for resources consumed (but it's NOT cheap)
- Serverless
- Use IAM permissions to access streaming source and destination
- Schema discovery. (column name in my SQL is found automatically...?, sophisticated function)
- Even if you configured the destination correctly, and there is no data coming to the destination even after a quite time the cause could be any of the three things:
    - issue with IAM role
    - mismatched name for the output stream
    - Destination service is just currently unavailable
- It elastically scale the processing application (in context of serverless) Even though, there is a default capacity of the processing application in terms of memory, which is 32GB (single Kinesis Processing Unit provides 4GB of memory, and the default limit is 8 KPUs)

## RANDOM_CUT_FOREST

- SQL function used for anomaly detection on numeric columns in a stream
- That Amazon developed!
- DETECTING ANOMALIES, OUTLIERS IN THE DATA STREAM

# ElasticSearch 101

It is (originally) for doing large scale analysis and reporting petabytes scale, but it's not just for search anymore, it's primarily for analysis and reporting these days.

And for some applications, they can actually analyze massive datasets a lot faster than something link Apache Spark Cloud!

## What is ElasticSearch? 

Actually, there is a larger context called the elastic stack. And ElasticSearch is only a part of elastic stack. And ElasticSearch is basically a search engine.

- A search engine (pass the JSON request to search something, or fuzzy search ...) 
- An analysis tool
- A visualization tool (Kibana) (you can also store semi-structure data like data coming in from server logs, and you could use **Kibana** to visualize that data)
- It's just a scalable version of Lucene as distributed horizontally across many nodes in a cluster.
- A data pipeline (**Beats / LogStash**) (A framework to allow you to at scale, import data from any variety of different sources into your cluster) (in short, beats and LogStash is the way to stream data into your ElasticSearch cluster)
- Horizontally scalable (Lucene scaled out infinetely version)

## What is Kibana?

Use case is like, easily import log data using log stash into an ElasticSearch cluster and then use Kibana to visualize that data.


Also you can use front end or UI for actually querying that data interactively, and trying out specific requests on your data set without having to type in command lines (not CLI, but GUI)

- So it's kinda a Google Analytics dashboard. But it your data is too large for Google Analytics to handle them, Kibana + ElasticSearch is good alternative

## ElasticSearch applications

- Full-text search (mainly!)
- Log analytics
- Application monitoring (extent of log analytics)
- Security analytics (centralize and analyze events from across your entire organization! You can index and analyze your data as soon as it's received from multiple sources and find threats faster)
- Click Stream analytics

## ElasticSearch Main Concepts

### First to start with : Documents

Documents are the things you're searching for. Any structured JSON data works. Every document has a unique ID.

### Second is type (but deprecated soon?)

Defines a schema and mapping shared by documents that represent the same sort of thing. (e.x. this is an encyclopedia article!)

### Last is indices (more emphasis on it)

Now, it is more moving forward to "One type per Index"

An index powers search into all documents within a collection of types.

### So, index in a nutshell

An index is split into shards.

And documents are hashed to a particular shard, and every shard live in a different node within a cluster. **Index is a collection of documents that are related to something split into shards.**

Interesting part is: Every shard in ElasticSearch is actually a self-contained Lucene index of its own. So every shard is a functioning mini search engine!

### Redundancy

In this example, this index has two primary shards and two replicas for each primary shard. Your application should round-robin requests amongst nodes.

![image](https://user-images.githubusercontent.com/34101059/76162876-cbbd9c80-6184-11ea-9963-bc7f10d749ed.png)

- Writes requests are routed to the primary shard, then replicated
- Read requests are routed to the primary or any replica.

## "Amazon" ElasticSearch Service

- Fully-managed (but not serverless...) (we don't have to worry about patching, or managing instances) (but, we still need to decide(provision) how many servers you want)
- It offers open source ElasticSearch APIs, manages Kibana, and integrations with log stash and other AWS services like Kinesis
- Scale up or down without downtime! (but this is not automatic)
- Pay for what you use
- Network isolation achieved by VPC
- Ensure data security by encrypting your data at rest and in transit using keys, and manage authentication and access control using Amazon Cognito and IAM policies
- Also integrates to IoT!
- AWS integration
    - S3 buckets (via Lambda to Kinesis)
    - Kinesis Data Streams (receives data from stream)
    - DynamoDB streams
    - CloudWatch / CloudTrail
    - Zone awareness (allocate nodes in your ElasticSearch service cluster across to different AZ in the same region)

## ES options

- Dedicated master node (choice of count and instance types) (master node doesn't hold or process any data, just for management)
- "Domains" (All kinds of configuration) (ES domain == ES cluster)
- Snapshots to S3
- Zone awareness (increased availability with the cost of high latency)

## ES security

- Resource-based policies (what actions can take ES API are, where a principal as a user or an account to a role that can be granted access)
- Identity-based policies (IAM policies or IP based policies)
- IP-based policies
- Request signing (all requests to ES must be signed. When you send in requests from the AWS SDKs to ES that will give you the means you need to actually digitally sign all of those requests going in) (kinda encryption in transit)
- VPC (instead of making it public) (You have to decide upfront if your cluster is gonna live in a VPC or be publicly accessible, no modification later is available)
- Cognito (particularly useful for the context of talking to Kibana)

### Securing Kibana

So if you're hosting your ES cluster inside your VPC, how are you gonna access Kibana on it?

You access Kibana through a web interface so it needs to be able to just go inside your cluster and open up an HTTP connection

Simple way to deal with it is ...

- Cognito (allows end users to log into Kibana through Microsoft AD using SAML 2.0, or social identity providers such as Facebook)
- If you choose to use VPC, getting inside a VPC from outside is hard.. There are several byway..
    - Nginx **reverse proxy** on EC2 forwarding to ES domain
    - SSH tunnel for port 5601
    - VPC Direct Connect
    - VPN

## ES anti patterns

- OLTP
    - no transactional support
    - RDS or DynamoDB is better
- Ad-hoc data querying
    - Athena is better
- Remember Amazon ES is primarily for search & analytics

# Athena

!Serverless! interactive queries of !S3 data!. 

- Interactive query service for S3 (SQL)
    - No need to load data, it stays in S3
- Presto under the hood
- Serverless ! ! ! ! !
- Supports many data formats
    - CSV (human readable)
    - JSON (human readable)
    - ORC (columnar, splittable) (doing queries on your data based on specific columns? VERY efficient)
    - Parquet (columnar, splittable) (also, very efficient)
        - So the word "splittable" here means that your cluster can split a massive ORC or massive Parquet data and view it across different instances
    - Avro (splittable, not columnar, not human-readable)
- Unstructured, semi-structured, or structured data in S3 all supported! You can work with glue and the glue data catalog to impart structure.

## Use case

- Ad-hoc queries of web logs
- Querying staging data before loading to RedShift
- Analyze CloudTrail / CloudFront / VPC / ELB etc **logs in S3**
- Integration with Jupyter, Zeppelin, RStudio notebooks
- Integration with QuickSight
- Integration via ODBC / JDBC with other visualization tool

## Athena + Glue

S3 -> AWS Glue -> Amazon Athena -> QuickSight

Glue crawler populating the glue data catalogue for S3 data, tries to extract columns and table definitions out of it, and can use the glue console to refine that definition.

So once you have a glue data catalogue published for your S3 data, Athena will see it automatically, and it can build a table from it automatically. Now you can query it!

## Cost model

- Pay-as-you-go
    - \$5 per TB scanned
    - successful or cancelled queries count, failed queries do not
    - No charge for Database Definition Language (CREATE / LATER / DROP)
- Save LOTS of money by using **columnar formats**
    - ORC, Parquet
    - Save 30% ~ 90%, and get better performance
- Partitioning data can also reduce cost. (e.x. "2019/05/03", "2019/05/04")
- Glue and S3 have their own charges

## Athena Security

- Access control
    - IAM, ACLs, S3 bucket policies
    - AmazonAthenaFullAccess / AWSQuicksightAthenaAccess
- Encrypt results at rest in S3 staging directory
    - Server-side encryption with S3 manages key (SSE-S3)
    - SSE with KMS key (SSE-KMS)
    - Client-side encryption with KMS key (CSE-KMS)
- Cross-account access in S3 bucket policy possible
- **Transport Layer Security (TLS)** encrypts in-transit (between Athena and S3)

## Anti-patterns

- Highly formatted reports / visualization (use QuickSight instead)
- ETL (use glue instead)

# Amazon RedShift

Fully-managed, petabyte-scale data warehouse

- 10X better performance than other Data warehousing solutions
    - Via machine learning, massively parallel query execution, columnar storage
- Designed for OLAP, not OLTP (for OLTP, row based DB would be better)
- Cost effective
- SQL, ODBC, JDBC interface
- Scale up or down on demand
- Built-in replication & backups
- Monitoring via CloudWatch / CloudTrail

## Use case

- Accelerate analytics workloads
- Unified data warehouse & data lake (Redshift Spectrum is a way of importing your unstructured data in S3 in your data warehouse)
- Modernize data warehouse
- Analyze global sales data
- Store historical stock trade data
- Analyze ad impression & clicks
- Aggregate gaming data
- Analyzing social trends

## Architecture

Cluster is a core infrastructure component of an Redshift.

Cluster is composed of one leader node (interface between your external clients and the computer nodes under the hood) and one or more compute nodes (scales up to 128, so it's not *technically* infinitely scalable)

Each cluster can contain one or more databases.

User data is going to be stored on the compute nodes.

So the leader node receives all the queries from client applications, parses the queries, and develops execution plans, and coordinates the parallel execution of those plans with the compute nodes, and also aggregates the intermediate results from those nodes.

### Compute Nodes

Responsible for executing the steps specified in the execution plans (from the leader node), and sending those intermediate results back to the leader node for aggregation

Each compute node has its own dedicated CPU, memory, and attached disk storage which are determined by the node type you choose.

There are two types of node types:

1. Dense storage
    - Focus on LARGE data
    - HDD for a very low price
    - two storage size available: xl, 8xl
    - xl : three HDD with a total of two TBs of magnetic storage
    - 3xl : 24 HDD with a 16 TBs of magnetic storage
2. Dense compute
    - Focus on FAST performance
    - high CPUs, large amounts of RAM, SSD
    - large : 160 GBs of SSD, 15 GB of RAM
    - 8xl : 2.56 TBs of SSD, 244 GB of RAM

Recall that the number of compute nodes can be scaled up to 128. 

Within the compute node is divided in **node slices**

Portion of the node's memory and disk space is going to be allocated to each slice. Number of slices per node is determined by the node size of the cluster. So each slice process chunks of data being given to it.

## RedShift Spectrum

- Query Exabytes of unstructured data in S3 without loading. (Think of Athena using the AWS Glue Catalog to make tables on top of your S3, it's kinda similar)
    - The difference from the Glue + Athena scenario is that it's just looks like another table in RedShift database, whereas the scenario is more of having the console based query SQL engine. 
- Limitless concurrency
- Horizontal scaling
- Separate storage & compute resources (you can scale each independently)
    - So with spectrum, all of your storage is being done in S3, Spectrum is just doing the compute part of analyzing that data
- Wide variety of data formats
- Support of Gzip and Snappy compression

## RedShift Performance

- Massively Parallel Processing (MPP)
- Columnar Data Storage (each data block stores values of a single column from multiple rows)
- Column Compression (Capable since Columnar storage is all sequentially stored on disk in the same type of data format) 
- Block size of 1MB (pretty big) (reduces the number of IO requests)
- Indexes or materialized view are not required with RedShift
- When loading data into an empty table, Amazon Redshift automatically samples your data and selects the most appropriate compression scheme.

## Durability of RedShift

- Replication within cluster
- Backup to S3 (for DR purpose)
    - Asynchronously replicated to another region
    - Three copies of the data are maintained. (Original, Replica on computer nodes, and in a backup in S3)
- Automated snapshots (retention period 1 day by default, up to 35 days, if you set 0 day, then the automated backup is turned off)
- Failed drives / nodes automatically replaced
    - In case of driver failure, RedShift cluster will remain available with a slight decline in performance of certain queries
        - For multi node cluster, redshift rebuilds that drive from a replica of the data on that drive which is stored on another drive within that node.
        - For single node cluster, data replication is not supported, so **you may want to restore your cluster from a snapshot in S3 instead**
    - In case of Node Failure, cluster will be unavailable for queries and updates until the replacement node is provisioned and added to the database
    - But the most frequently accessed data is loaded first, so Amazon does its best to normalize the performance (for single node cluster, it must restore from S3 just like driver failed case)
- Vulnerable to AZ power outage. The only solution for this is restore your backup S3 into another AZ in the same region.
- LIMITED TO A SINGLE AZ

## Scaling RedShift

- Vertical (improving instance types) and Horizontal (# of nodes) scaling on demand
- During scaling:
    - A new cluster is created while you old one remains available for reads.
    - **CNAME** is flipped to new cluster (a few minutes of downtime)
    - Data moved in parallel to new compute nodes.

## Redshift Distribution styles

Data in your data is distributed across many compute nodes and many slices within those nodes.

Goals of distribution are to 1. Distribute the workload uniformly among the nodes in the cluster and to 2. Minimize data movement during query execution.

In order to view the reflective distributive style of a table, you can query the **PG class info view** or **SVV table info view**

- AUTO
    - Redshift figures it out based on size of data (among EVEN, KEY, ALL)
- EVEN
    - Rows distribution across slices in round-robin
- KEY
    - Rows distributed based on one column
- ALL
    - Entire table is copied to every node

### Even

Useful when you're **not** gonna do joins or there is not a clear choice between key distribution or all distribution

Not thinking of clustering data by key or something

### Key

Leader node here, will place matching values on the same node slice. Matching values from the common columns are physically stored together

Useful for doing queries based on specific column ("SELECT * FROM sample_data WHERE user_id = 120")

### ALL

Ensures that every row is co-located for every join that the table participates. So you need *storage required* TIMES *number of nodes*

So it takes much longer to load,update or insert data.

Useful for tables that are not updated frequently. Small dimension tables do not benefit significantly from ALL distribution.

## RedShift Sort Keys

- Rows are stored on disk in sorted order based on **column** you designate as a sort key
- Like an index
- Makes for range queries
- It enables range restricted predicates, and RedShift automatically store the minimum and maximum values for each block as part of its metadata. (Now queries like BETWEEN is fast)
- Choosing a sort key
    - If the recent data is queried most frequently: time stamp column! Recency
    - If you do frequent range filtering or equality filtering on one column, specify that column as sort key.
    - If you frequently join a table, specify the join column as both the sort key and the distribution key (Query optimizer will then choose sort merge join instead of hash join)
    - Single vs Compound vs Interleaved sort key

### Compound Key

Compound key is made up of all columns listed in the sort key definition in the order they are listed in.

**Default type of sort key. Help to improve compression.**

![compound](https://hevodata.com/blog/wp-content/uploads/2017/10/Screen-Shot-2017-10-08-at-4.40.21-PM.png)

Good for JOIN, GROUP BY & ORDER BY, PARTITION BY & ORDER BY ...

### Interleaved key

Gives equal weight to each column in the Redshift sort keys. For query uses restrictive predicates (equality operator in WHERE clause) on secondary sort columns.

![interleave](https://hevodata.com/blog/wp-content/uploads/2017/10/Screen-Shot-2017-10-08-at-4.41.12-PM.png)

It uses an internal compression scheme for a zone map values that enables them to better discriminate among column values that have a long common prefix.

Do not use interleaved key for increasing attributes like Date, Timestamp, or something. 

## Importing / Exporting Data

IMPORTANT!

- COPY command
    - parallelized; efficient (read from multiple data streams **simultaneously**)
    - From S3, EMR, DynamoDB, remote hosts using SSH
    - role based or key based access control to provide authentication for your cluster to perform those load and unload operations
    - S3 requires a manifest file and IAM role
    - There are two ways to load from S3:
        - Using Amazon S3 object prefix ("s3://es/")
        - Manifest file (JSON format file sitting in S3 that lists the data files that you want to load) ("copy Table_name from s3://bucket_name/manifest_file")
        - In either cases, you would need authorization to do that. (IAM role)
        - So every copy command specifies what table you're loading it into, where you're taking it from, and the authorization for performing that copy
- UNLOAD command
    - unload from a table into files in S3
    - The most efficient way to dump a table in RedShift into S3
- Enhanced VPC routing
    - All copy and unload traffic between your cluster and the repositories **through the Amazon VPC** (otherwise, it will be routed through internet, so you might set NAT gateways or internet gateways for this goal)

### COPY command

- Use COPY to load large amounts of data from **outside** to RedShift
- If your data is already in RedShift in another table, no need to use COPY, just use:
    - INSERT INTO ---SELECT
    - CREATE TABLE AS --
- COPY can decrypt data as it is loaded from S3. (pretty fast!)
    - Hardware-accelerated SSL used to keep it fast
- Gzip, Izop, and bzip2 compression supported to speed it up further (increasing the speed by compressing)
- Automatic compression option
    - Analyzes data being loaded and figures out optimal compression scheme for storing it
- Special case: narrow tables (lots of rows, but few columns)
    - Load with a single COPY transaction if possible
    - Otherwise hidden metadata columns consume too much space.
    - COPY command parallelizes things in once, so why not use a single COPY command, no need for multiple COPY calls.

### RedShift copy grants for CROSS-REGION SNAPSHOT COPIES

What is copy grant in the first place? It permits RedShift to use a CMK from AWS KMS to encrypt copied snapshots in a destination region. You can set up using a KMS key, you can securely copy KMS encrypted snapshots for your RedShift cluster to another region

- Let's say you have a KMS-encrypted cluster and a snapshot of it
- You want to copy that snapshot to another region for backup
- In the destination AWS region, 
    - Create a KMS key if you don't have one already
    - Specify a unique name for your snapshot copy grant
    - Specify the KMS key ID for which you're creating the copy grant
- In the source AWS region:
    - Enable copying of snapshots to the copy grant you just created

### DBLINK

- Connect RedShift to PostgreSQL
- this is a thing because it links column storage of RedShift and row storage of PostgreSQL
- Good way to "copy and sync" data between PostgreSQL and RedShift. 
- Detailed step:
    - In the same AZ, launch RedShift cluster and PostgreSQL
    - Configure the VPC Security Group to allow an incoming connection from the RDS PostgreSQL endpoint.
    - Then, run the SQL code to establish DBLINK connection between postgreSQL instance and RedShift 

## Integration with other services

- S3 (COPY, UNLOAD! parallelized!)
- DynamoDB (also able to load data from it by COPY)
- EMR / EC2 (you can import data using SSH, then COPY)
- Data pipeline (automate the data movement and transformation in and out)
- Database Migration Service

## Redshift Workload Management (WLM)

- Prioritize short, fast queries vs long, slow queries 
- Query queues (according to service classes and configuration parameters)
- So you can modify the WLM configuration to create separate queues for short, fast queries and for long running queries.
- Via console, CLI, or API

### Concurrency Scaling

- Automatically adds cluster capacity to handle increase in concurrent **read** queries (Bursty access to your redshift cluster, concurrency scaling can automatically scale up)
- Support virtually unlimited concurrent users & queries
- WLM queues manage which queries are sent to the concurrency scaling cluster. (Now you can point out read queries that you think might be bursting, rather than adding a bunch of capacity for some off-line latency-insensitive job)

### Automatic Workload Management

- Creates up to 8 queues
- Default 5 queues with even memory allocation. (you can change this freely)
- Large queries (big hash joins) -> concurrency lowered (may be handle this alone)
- Small queries (insert, scan, aggregation) -> concurrency raised (execute this with another bunch of small queries!)
- Configuring query queues
    - Priority
    - Concurrency scaling mode (I want this to go to concurrency scaling cluster)
    - User groups (VIP user benefits from cutting in lines)
    - Query groups (It's a tag attached to query)
    - Query monitoring rules (Set metric space performance boundaries beforehand, and specify what action to take when a query goes beyond those boundaries) ("Abort / Or kick that off to long queue short queries in short queue if they run for more than 1 minute")

### Manual Workload management

- One default queue with concurrency level of 5 (5 queries at once)
- Superuser queue with concurrency level 1 (administrative query which should always run no matter what)
- Define up to 8 queues, up to concurrency level 50
    - Each can have defined concurrency scaling mode, concurrency level, user groups, query groups, memory allocated to queue, timeout, query monitoring rules
    - Can also enable **query queue hopping**
        - Timed out queries "hop" to next queue to try again

### Short Queue Acceleration (SQA)

- Prioritize short-running queries over longer-running ones
- Short queries run in a dedicated space, won't wait in queue behind long queries
- Can be used in place of WLM queues for short queries (**alternative to WLM**)
- Works with (candidate for short queries):
    - CREATE TABLE AS
    - Read-only queries (SELECT statements)
- Uses machine learning to predict a query's execution time
- Can configure how many seconds is "short"!

### VACUUM command

- Recovers space from deleted rows and to restore the sort order

Four different types of it:

- VACUUM FULL (default) (resort all of the rows and reclaim space from deleted rows)
- VACUUM DELETE ONLY (only reclaims deleted row space, not resorting)
- VACUUM SORT ONLY (only resorting not reclaiming)
- VACUUM REINDEX (re-initiate interleaved index, then execute a VACUUM FULL)

## Anti pattern for RedShift

- Small data sets (use RDS instead)
- OLTP (use RDS or DynamoDB instead)
- Unstructured data???? WHAT ABOUT RedShift Spectrum...? However, amazon recommends to use ETL first with EMR 
- BLOB data (store references to large binary files in S3, not the files themselves)

## Resizing RedShift Clusters

Elastic Resize vs. Classic Resize

- Elastic Resize
    - Quickly add or remove nodes of same type
    - cluster is down for a few minutes
    - Tries to keep connections open across the downtime (you might not drop a single query)
    - One limitation : doubling or halving for some dc2 and ra3 node types. (no other option)
- Classic Resize
    - Change node type **and/or** number of nodes
    - Cluster is read-only for hours to days
- Snapshot->restore->resize
    - Used to keep cluster available during a classic resize (use snapshot as a some kind of replica node)
    - Copy cluster, resize new cluster

## New RedShift features for 2020

- RA3 nodes with managed storage
    - enable independent scaling of compute and storage. (you can only scale up CPU, leave storage or vice versa)
- Redshift data lake export
    - unload **result of query** to S3 in Apache Parquet format
    - Parquet is 2x faster to unload and consumes up to 6x less storage, compared to text format.
    - Compatible with Redshift spectrum, Athena, EMR, SageMaker
    - Automatically partitioned

# Briefly on RDS

- Hosted relational database
- Not for "big data"
    - might appear on exam as an example of what not to use
    - Or in the context of migrating from RDS to RedShift.

## ACID property

- Atomicity (part of a transaction fails, the entire transaction is discarded)
- Consistency (should adhere to all defined rules and restriction like cascades and trigger)
- Isolation (Each transaction is independent to itself)
- Durability (All changes made to the database be permanent)

## Amazon Aurora

- MySQL and PostgreSQL - compatible
- 5x faster than MySQL, 3x faster than PostgreSQL.
- Continuous backup to S3
- Automatic scaling with Aurora Serverless
- Replication across AZs

## Security

- VPC network isolations
- At-rest with KMS
    - Data, backup, snapshots, and replicas can be encrypted
- In-transit with SSL


