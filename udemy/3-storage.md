# (brief overview) S3

- Buckets are defined at the region level
- but Bucket should have a globally unique name

## Objects

- Objects (files) have aKey. The key is is the FULL path
- Just keys with very long names that contain slashes ("/")
- Object Values are the content of the body:
    - 0KB ~ 5TB
    - If uploading more than 5GB, must use "multi-part upload"
- Metadata (list of text key / value pairs - system or user meta data)
- Tags (unicode key / value pair) - useful for security / life cycle

## Consistency Model

- Read after Write consistency for PUTS of **new objects**
    - As soon as an object is written, we can retrieve it!
    - Remember the success code! PUT 200 -> GET 200
    - one caveat : GET 404 -> PUT 200 -> GET 404 - eventual consistency
- Eventual consistency for DELETES and PUTS of **existing objects**
    - PUT 200 -> PUT 200 -> GET 200 (might be older version)
    - DELETE 200 -> GET 200

## Storage Tiers

- Amazon S3 Standard (99.99% availability)
- Amazon S3 standard - Infrequent Access (rapid access guaranteed) (99.9% availability)
- Amazon S3 One Zone - Infrequent Access (only one AZ, availability 99.5%, low latency and high throughput, SSL for data at transit and encryption at rest)
- ~~Amazon Reduced Redundancy Storage~~
- Intelligent Tiering (Auto-tiering)
- S3 Glacier (archiving / backup) (alternative to on-premise magnetic tape storage)

Commonalities:

1. Highly durability (11 9s) of objects across multiple AZ (more than 3 AZ, except one zone)
2. Sustain 2 concurrent facility failure (not for one zone(0) and intelligent tiering(1), and glacier(1) though)

For Glacier:

- Each item in Glacier is called "Archive" (up to 40TB)
- Archives are stored in "Vaults"
- 3 retrieval options
    - expedited (1 to 5 minutes retrieval)
    - standard (3 to 5 hours)
    - Bulk (~12 hours)

**object is individually assigned with any storage class (not binded to the bucket). And also can be changed easily**

## S3 Life Cycle Rules

- Set of rules to move data between different tiers.
- Transition actions
- Expiration actions

- can be configured by prefix (e.x. stores/). Only objects within the stores will be governed by the life cycle rules then.
- So there can be multiple life cycle rules within the same bucket!

## Versioning

- Same key overwrite will increment the "version ID"
- previous overwritten files before versioning, its version ID will be null
- Enabled at the bucket level
- Cannot terminate versioning, only suspend it.
- **For Cross Region replication, versioning should be enabled**

## Cross Region Replication

- Asynchronous Replication
- Must enable versioning **both in source and destination**
- Also can be different accounts
- Must set proper IAM permissions to S3.
- We can also set source by prefix or tags (like life cycle rules)

## S3 ETags?

ETag is Entity Tag, ensuring "identical content"

- How do you verify if a file has already been uploaded to S3?
- Names work, but how are you sure the file is exactly the same?

- For this, use ETags:
    - For simple uploads (less than 5GB), it's the MD5 hash.
    - For multi-part uploads, it's more complicated...

- Using ETage, we can ensure **integrity** of files.

### Use case of ETags

One want to ensure that the file in "2019/03/04/a.csv" and the "2020/03/05/b.csv" is the exactly same. ETag hashes based on the content, so if the ETag is the same, those two will be the same. If the file is modified, the ETag would be different

## S3 performance

- When you had more than 100 TPS, S3 performance could degrade
- HISTORICALLY, it was recommended to have random characters in front of your key name to optimize performance.
    - my_bucket/5r4d_my_folder/myfile1.txt
    - my_bucket/1ei2_my_folder/myfile2.txt

- HISTORICALLY, Never use dates to prefix keys

- We can scale up to 3500 RPS for PUT and 5500 RPS for GET for EACH PREFIX.
- Now no randomize needed for normal user, but if you want above normal range of RPS, consider randomizing the prefix key



- Faster upload of large objects (>5GB), must use multipart upload (it's recommended to user multipart upload for more than 100MB objects)
    - parallelizes PUT for greater throughput
    - maximize your network bandwidth
    - decrease time to retry in case a part fails (all-or-nothing vs kinda checkpoint)
- Use CloudFront to cache S3 objects around the world (improves reads)
- S3 Transfer Acceleration (uses edge locations) - just need to change the endpoint you write to, not the code
- If using SSE-KMS encryption, you may be limited to your AWS limits for KMS usage (degradation!)

## S3 Encryption for **Objects**

- 4 methods
    - SSE-S3 : keys are handled & managed by AWS S3
    - SSE-KMS : leverage KMS to manage encryption keys
    - SSE-C : you manage your own encryption keys
    - Client Side Encryption

### SSE-S3

- Object is encrypted server side
- AES-256 encryption type
- Must set header : "x-amz-server-side-encryption":"AES256"

![image](https://user-images.githubusercontent.com/34101059/75950815-a95e2180-5eed-11ea-8458-bb67aa6056ad.png)


### SSE-KMS

- pros : user control + audit trail
- Must set header: "x-amz-server-side-encryption":"aws:kms"
- key that is used is a KMS customer master key(CMK) that you can manage over time.

### SSE-C

- Using data keys fully managed by the customer outside of AWS
- S3 does not store the encryption key you provide
- **HTTPS** must be used
- For every HTTP request made, encryption key must provided in HTTP headers

### Client Side Encryption

- Client library such as Amazon S3 Encryption Client (S3 encryption SDK)
- Client must encrypt / decrypt data themselves when sending to / retrieving from S3

### Encryption in transit

- AWS S3 exposes:
    - HTTP endpoint: non encrypted
    - HTTPS endpoint : encrypted in transit

- You're free to use any endpoint you want, but HTTPS is recommended
- again, HTTPS is mandatory for SSE-C
- Encryption in transit is also called as SSL / TLS

## S3 Security

### S3 CORS (Cross-Origin Resource Sharing)

- If you request data from another website, you need to enable CORS. (in default, Same Origin Policy blocks this kind of request)
- CORS allows you to limit the number of websites that can request your files in S3.
- Exam situation : Web site is working fine when we go online, but then when you run the web site off-line on your local host, it doesn't work. Why? Because of the CORS

### S3 Access Logs

- For audit purpose, you may want to log all access to S3 buckets
- Any request made to S3, from any account, authorized or denied, will be logged into **another S3 bucket!**

### S3 security overview

- User based
    - IAM policies - which API calls should be allowed for a specific user from IAM console
- Resource based
    - Bucket policies - bucket wide rules from the S3 console - allows cross account
    - Object ACL - finer grain
    - Bucket ACL - less common

- Networking
    - supports VPC endpoints (for instances in VPC without internet)
- Logging and Audit:
    - S3 access logs can be stored in other S3 bucket
    - API calls can be logged in AWS Cloudtrail
- User Security:
    - MFA (multi-factor authentication)
    - signed URLs : URLs that are valid only for a limited time.

## Glacier

- Low cost object storage meant for archiving/backup
- Each item in Glacier is called "Archive" (up to 40TB)
- Archives are stored in "Vaults"

### Vault Policies & Vault Lock

- Each Vault has:
    - ONE vault access policy
    - ONE vault lock policy
- Vault Policies are written in JSON (similar to bucket policy)
- Vault access policy is similar to bucket policy (restricts user/ account permissions)

- Vault Lock Policy? is a policy you lock, for regulatory and compliance requirements.
    - The policy is **immutable**
    - e.x.1. Forbid deleting an archive if less than 1 year old
    - e.x.2. Implement WORM policy (write once read many) (guarantee for NO overwrite)


# DynamoDB

- Fully managed, highly available with replication across 3AZ
- not a relational database!
- Fast and consistent in performance (low latency on retrieval)
- **Enables event driven programming with DynamoDB streams!**

## Basics

- It is made of tables
- each table has a primary key (must be decided at creation time)
- each table can have an infinite number of items (=rows)
- each item has attributes (can be added over time - can be null)
- maximum size of a item is 400KB (S3 object can be up to 5TB)
- Data types supported are : Scalar types (binary, boolean, null,..), document types (list, map), set types (string set, number set , ...)

## Primary Keys

- Option 1: partition key only (HASH)
    - partition key must be **unique** for each item
    - It must be diverse (highest cardinality)
- Option 2: partition + sort key
    - the combination must be unique
    - data is grouped by partition key
    - sort key == range key
    - e.x. user_id (partition key) + game_id (sort key)

## DynamoDB in Anti Pattern

- Pre-written application to a traditional relational database
- Joins or complex transactions
- Binary Large Object data: store data in S3 & metadata in DynamoDB
- Large data with low I/O rate : use S3 instead.

> If the data is cold and large => S3, If it is hot and manageable-size => DynamoDB

## Provisioned Throughput (you should calculate)

- Read Capacity Units (RCU): throughput for reads
- Write Capacity Units (WCU) : throughput for writes
- Option to setup auto-scaling of throughput to meet demand
- Throughput can be exceed only **temporarily** using "burst credit"
- If burst credit is empty, you'll get a "ProvisionedThroughputException"

### WCU

**1 WCU is one write per second for an item up to 1KB in size**

- We write 10 objects per seconds of 2KB = 20WCU
- we write 6 objects per second of 4.5KB -> 6 * ceil(4.5) = 30WCU

### RCU

Strongly consistent read (expensive, latency) vs Eventually consistent read (default)

- But GetItem, Query & Scan provide a "ConsistentRead" parameter you can set to true
- 1 RCU = 1 strongly consistent read per second, or 2 eventually consistent reads per second, for an item up to 4KB in size

- 16 eventual consistency per second of 12 KB each, (16/2) * 12/4 = 24RCU
- 10 strongly consistent read per second of 6KB -> 10 * ceil(6/4) = 20RCU

### Throttling

- If we exceed our RCU or WCU, we get ProvisionedThroughputException. 
- Reasons:
    - Hot keys/partitions : one partition key is being read too many times
    - Very large items: remember RCU and WCU depend on size of itemrs
- Solutions : 
    - Exponential back-off (already in SDK) ([link](https://en.wikipedia.org/wiki/Exponential_backoff)) (algorithm for retransmission of failed objects, the number of possibilities for delay increases exponentially)
    - Distribute partition keys
    - for RCU issue, use DAX (DynamoDB accelerator)

## Partitions

- You start with one partition for newly created table
- Each partition:
    - Max of 300 RCU / 1000 WCU
    - Max of 10GB
- To compute the number of partitions
    - By capacity: (TOTAL RCU/3000) + (TOTAL WCU/1000)
    - By size: TOTAL SIZE / 10GB
    - Total partitions : CEIL(MAX(capacity, size))
- **WCU and RCU are spread evenly between partitions (reason for hot partition)**

## DynamoDB API

### Writing Data

- PutItem - Write data to DynamoDB (create data or full replace)
    - consumes WCU
- UpdateItem - update data in DynamoDB (partial update of attributes)
    - possibility to use atomic counters and increase them
- Conditional Writes:
    - accept a write / update only if conditions are respected / otherwise reject
    - Helps with concurrent access to itmes
    - no performance impact

### Deleting Data

- DeleteItem
    - Delete an individual row
    - Ability to perform a conditional delete
- DeleteTable
    - Much faster than subsequent, thorough calls of DeleteItem s.

### Batching Writes

- BatchWriteItem
    - Up to 25 PutItem and / or DeleteItem in one call
    - up to 16 MB of data written
    - up to 400KB of data per item
- Batching allows you to save in latency by reducing the number of API calls done against DynamoDB
- Operations are done in parallel for **better efficiency**
- It's possible for part of a batch to fail, in which case we have to re-try the failed items (using exponential back-off algorithm)

### Reading Data

- GetItem:
    - Read based on Primary Key
    - Primary Key = HASH or HASH-RANGE
    - Eventually consistent read by default
    - Option to use strongly consistent reads (more RCU - might take longer)
    - ProjectionExpression can be specified to include only certain attributes ($\Pi$)
- BatchGetItem:
    - Up to 100 items
    - Up to 16 MB of data
    - Items are retrieved in parallel to minimize latency

### Query

- Query returns items on :
    - Partition Value (must be = operator)
    - SortKey value (=, <, <=, ..., between) - optional
    - FilterExpression to further filter (client side filtering) (usually cumbersome) (can be any attribute)
    
- Returns:
    - up to 1MB of data
- Able to do pagination on the results
- Can query table, a local secondary index, or a global secondary index

### Scan

- Scan the entire table and then filter out data (inefficient)
- Returns up to 1MB of data - use pagination to keep on reading
- Consumes a lot of RCU
- Limit impact using limit or reduce the size of the result

- For faster performance, use parallel scans:
    - Multiple instances scan multiple partitions at the same time
    - Increases the throughput and RCU consumed
- Can use a **ProjectionExpression + FilterExpression** (no change to RCU)

## LSI & GSI

### LSI (Local Secondary Index)

- Alternate range key for your table, local to the hash key
- Up to five local secondary indexes per table.
- The sort key consists of exactly one scalar attribute (among String, Number, or Binary)
- **LSI must be defined at table creation time**
- P.K should be the previously defined partition key + new sort key

### GSI (Global Secondary Index) (kinda serves as partition key in the newly created table)

- To speed up the queries on non-key attributes, use a Global Secondary Index
- GSI = partition key + optional sort key
- The index is a new "table" and we can project attributes on it
- Must define RCU / WCU for the index
- possibility to modify / add GSI (not LSI)
- projected attributes (select attributes) ($\Pi$)
    - all
    - Keys only
    - include 

## DAX (DynamoDB Accelerator)

- Seamless cache for DynamoDB
- Writes go through DAX to DynamoDB (write-through, default) (but there can be write-around for massive writes)
- Micro second latency for cached read & queries
- Solves the Hot Key problem
- 5 minutes TTL for cache by default
- up to 10 nodes in the cluster
- Multi AZ (3 node minimum is recommended for production, HA)
- Secure (Encryption at rest with KMS, VPC, IAM, CloudTrail...)

## DynamoDB Streams

- Changes in DynamoDB (Create, update, delete) can end up in a DynamoDB stream
- This stream can be read by AWS Lambda(will receive as a batch of records), and we can do:
    - React to changes in real time (welcome email to new users)
    - Create derivative table / view
    - Insert into elastic search
- Could implement Cross Region Replication using Streams
- Stream has 24 hours of data retention (no modification available)
- Configurable batch size (up to 1000 rows, 6MB)

### DynamoDB Streams Kinesis Adapter

- Use KCL library to directly consume the from DynamoDB streams
- You just need to add a "Kinesis Adapter" library for this sake.
- The interface and programming is exactly the same as Kinesis Streams
- So you have two choices to consume DynamoDB Streams 1. Lambda, 2. KCL library with the Kinesis Adapter

## DynamoDB TTL

- TTL = automatically delete an item after an expiry date/ time
- TTL is provided at no extra cost, deletions do not use WCU / RCU
- Helps reduce storage and manage the table size
- Helps adhere to regulatory norms (user data restoration period:7 days)
- TTL is enabled per row (you define a TTL column, and add a date there, e.x. "expire_on" column -> UNIX epoch)
- DynamoDB typically deletes expired items within 48 hours of expiration
- Deleted items due to TTL are also deleted in GSI / LSI
- DynamoDB Streams can help recover expired items

## DynamoDB - security

- VPC endpoints available to access DynamoDB without internet
- Access fully controlled by IAM
- Encryption at rest using KMS
- Encryption in transit using SSL / TLS

## Backup and Restore

- Point-in-time-recovery like RDS
- No performance impact

## Others

- Global Tables (multi region, fully replicated, high performance)
- Amazon Database Migration Service (DMS) can be used to migrate to DynamoDB (from Mongo, Oracle, MySQL, S3, etc...)
- You can also launch a local DynamoDB on your computer

# ElasticCache (really briefly)

- The same way that RDS is to get managed relational databases, ElasticCache is to get managed Redis or Memcached
- Caches are in-memory databases with really high performance, low latency
- Helps reduce load off of databases for read intensive workloads
- Helps make your application **stateless**
- Write Scaling using sharding
- Read Scaling using Read Replicas
- Multi AZ with failover capability
- AWS governs it all.

## ElasticCache with Redis

- In-memory key-value store
- cache survive reboots by default (persistence)
- Multi AZ with automatic failover for disaster recovery 
- support for read replica

## ElasticCache with Memcached

- In-memory object store
- cache doesn't survive reboots
- Overall, Redis > Memcached

