# Encryption 101

## Encryption in flight (SSL)

Think of a scenario that my credit card to a server to make a payment online.

Ensure no one else on the way where the network packet is going to travel can see the credit card information.

So you might have https web site, which guarantees that it is an SSL enabled website.

- Data is encrypted sending and decrypted after receiving
- SSL certificated helps with encryption (HTTPS) almost all services in AWS had https endpoint.
- Encryption in flight ensures no MITM (man in the middle attack) can happen

## Server Side Encryption at rest

- Data is encrypted after being received by the server. 
- In general scenario, the server will store the data on its disk. And even in case the server is hijacked, it will be safe.
- Data is encrypted before being set
- It is stored in an encrypted form (usually a data key)
- The encryption / decryption keys must be managed somewhere (AWS KMS) and the server must have access to it.

![image](https://user-images.githubusercontent.com/34101059/76366222-bf943380-636c-11ea-8102-213959913df7.png)

## Client side encryption

- Data is encrypted by the client and never decrypted by the server.
- Data will be decrypted by a receiving client. (Server will never read the decrypted data)
- Could leverage **Envelope Encryption**

![image](https://user-images.githubusercontent.com/34101059/76366292-f8340d00-636c-11ea-9771-a78f0d777602.png)

(Client side data key is somewhat optional)

# S3 encryption (BORING)

- There are 4 methods of encrypting objects in S3
    - SSE-S3 : encrypts S3 objects using keys handled & managed by AWS
    - SSE-KMS : leverage AWS KMS to managed encrypted keys
    - SSE-C : U manage your own encryption keys
    - Client Side Encryption

## SSE-S3

- Object is encrypted server side
- AES-256 encryption type
- Must set header: "x-amz-server-side-encryption":"AES256"

![image](https://user-images.githubusercontent.com/34101059/76366486-78f30900-636d-11ea-963d-eb41994f708d.png)

("Header is the header: "x-amz...")

## SSE-KMS

- The same server side encryption but keys are handled & managed by AWS
- KMS advantages : user control + audit trail
- Must set header: "x-amz-server-side-encryption":"aws:kms"

![image](https://user-images.githubusercontent.com/34101059/76366559-b061b580-636d-11ea-9338-3da667d32bd9.png)

## SSE-C

- Data keys fully managed by the customer outside of AWS
- Amazon S3 doesn't store the encryption key you provide
- **HTTPS** must be used
- Encryption key must provided in HTTP headers, for every HTTP request made
- Technically, S3 does the encryption, and throws away the data key

![image](https://user-images.githubusercontent.com/34101059/76366783-4bf32600-636e-11ea-8cfc-f61ca52b27f1.png)

## Client Side Encryption

- You can use client library such as the Amazon S3 Encryption Client
- Client must encrypt / decrypt data themselves before/when sending / retrieving to/from S3
- Customer fully manages the keys and encryption cycle

![image](https://user-images.githubusercontent.com/34101059/76366876-89f04a00-636e-11ea-9857-385bbb6d3f66.png)

## Encryption in transit (SSL)

- AWS S3 exposes:
    - HTTP endpoint : non encrypted
    - HTTPS endpoint : encryption in flight

- HTTPS is mandatory in SSE-C
- Encryption in flight is also called SSL / TLS

# KMS overview

Pretty Darn important

- Easy way to control access to your data, AWS manages keys for us
- Fully integrated with IAM for authorization, and cloudtrail for auditing purpose
- Seamlessly integrated into:
    - Amazon EBS
    - Amazon S3
    - RedShift
    - RDS
    - SSM: parameter store
    - Etc... so many things
- But you can also use the CLI / SDK for alternative

## KMS 101

- Anytime you need to share sensitive information, use KMS
    - DB passwords
    - Credentials to external services
    - Private key of SSL certificates
- The value in KMS is that the CMK used to encrypt data can never be retrieved by the user, and the CMK can be rotated for extra security.
- In other words, we don't managed the keys and don't perform encryption by ourselves (done by AWS) but we get enhanced security
- NEVER EVER STORE YOUR SECRETS IN PLAIN TEXT, ESPECIALLY IN YOUR CODE!
- Encrypted secrets can be stored in the code / environment variables
- KMS can only help in encrypting up to **4KB** of data per call
- If data > 4KB, use **envelope encryption**
- To give access to KMS to someone:
    - Make sure the key policy allows the user
    - also, make sure the IAM policy allows the API calls

## KMS functionality

- Able to fully managed the keys & policies
    - Create
    - Rotate policies
    - Disable
    - Enable
- Able to audit key usage (using CloudTrail)
- Three types of CMK:
    - AWS managed service default CMK : free
    - User Keys created in KMS : \$1 / month
    - User Keys imported (must be 256-bit symmetric key): \$1 / month
- Pay for API call to KMS (every time you encrypt / decrypt data by KMS, you will be charged (petty amount))

## KMS, API - Encrypted and Decrypt

![image](https://user-images.githubusercontent.com/34101059/76367372-31ba4780-6370-11ea-9281-79868a53f53f.png)

Baseline is we never ever get to perform decryption ourselves, KMS does it for use. We do not have direct access to the CMK.

## Encryption in AWS Services

- Requires migration (through Snapshot, backup)
    - EBS volumes
    - RDS databases
    - ElastiCache
    - EFS network file system
- In-place encryption (encrypt the unencrypted file right away):
    - **S3 (only one)**

# Cloud HSM (Hardware Security Module)

Alternative to KMS

- KMS => AWS manages the software for encryption
- CloudHSM => AWS provisions encryption hardware
- Dedicated Hardware 
- You manage the hardware, ergo you manage your own encryption keys entirely (AWS has no hint of your key now)
- The CloudHSM hardware device is tamper resistant. which means no one can go in the AWS's cloud data center, and look at your device, tamper with it and extract the key
- FIPS 140-2 Level 3 compliance (remember this...)
- CloudHSM clusters are spread across multi AZ (Highly Available) (There could be just one HSM, up to 28 of it)
- Supports both symmetric and asymmetric encryption (means that you can generate SSL/TLS Keys if you needed) (**unlike KMS, only supporting symmetric encryption, hey... wait a sec... Read this [Link](https://aws.amazon.com/ko/about-aws/whats-new/2019/11/aws-key-management-service-supports-asymmetric-keys/)**)
- No free tier available
- Must use the CloudHSM Client Software

##  Cloud HSM diagram

![image](https://user-images.githubusercontent.com/34101059/76367862-a9d53d00-6371-11ea-8758-509d8f94ddc5.png)

## Popular must-use case of CloudHSM includes:

- Dedicated encryption hardware
- You should have control over the user keys but still be in AWS cloud
- Have asymmetric type of encryption (Hey,,, KMS supports asymmetric keys since Nov 25, 2019)

## CloudHSM vs KMS

![image](https://user-images.githubusercontent.com/34101059/76368100-6d561100-6372-11ea-90e7-ed0197767b48.png)

KINDA outdated (asymmetric key support in KMS)

# Security in every AWS service

## Security in Kinesis

- Kinesis Data Streams
    - SSL encpoints using the HTTPS protocol to do encryption in flight
    - AWS KMS provides server-side encryption (encryption at rest)
    - For client side-encryption, you must use your own encryption libraries.
    - Supported interface for VPC endpoints / Private Link - access privately (you can access the Kinesis within our private EC2 instances)
    - You can use KCL to read from Kinesis but must grant read / write access to DynamoDB table.
        - Since KCL will use the DynamoDB table to do check-pointing and sharing the work between different KCL instances
- Kinesis Data Firehose
    - Attach IAM roles so it can deliver to S3 / ES/ Redshift/ Splunk
    - Can encryption the delivery stream with KMS (Server Side Encryption)
    - Supported interface for VPC endpoints / private link
- Kinesis Data Analysis
    - Attach IAM roles so it can read from Kinesis Streams and reference sources and write to an output destination like Firehose!

## Security - SQS

- Encryption in flight using the HTTPS endpoint
- Server Side Encryption using KMS
- IAM policy must allow usage of SQS
- SQS queue access policy (second level of security, think of NACL or S3 bucket policy)
- Client-side encryption must be implemented manually (doesn't have support directly)
- VPC endpoint is provided through an interface

## Security - AWS IoT

- AWS IoT policies:
    - Attached to X.509 certificates or Cognito Identities 
    - Able to revoke any device at any time
    - IoT policies are JSON documents
    - Can be attached to group instead of individual things

- IAM policies:
    - attached to users, group, or roles
    - Used for controlling IoT AWS APIs

- Attach roles to **Rules Engine** so they can perform their actions.

## Security - Amazon S3

- IAM policies
- S3 Bucket policies
- Access Control Lists
- Encryption in flight (SSL/TLS) using HTTPS
- Encryption at rest
    - server side encryption : SSE-S3, SSE-KMS, SSE-C
    - client side encryption - using S3 encryption client
- Versioning + MFA Delete
- CORS for protecting websites (make a list of website that can access to our S3 buckets)
- VPC Endpoint is provided through a Gateway
- Glacier - vault lock policies to prevent deletes (e.x. Write Once Read Many)

## Security - DynamoDB

- Data is encrypted in transit using TLS (HTTPS)
- DynamoDB can be encrypted at rest
    - KMS encryption for base tables and secondary indexes
    - **only for new table!! No in-place encryption**
    - To migrate un-encrypted table, create new table(with encryption) and copy the data. So you need to migrate the table if you want encryption.
    - Encryption cannot be disable once enabled
- access to tables / API / DAX using IAM
- The entire security in DynamoDB is managed through IAM, so don't need to created IAM users within DynamoDB (unlike RDS)
- ~~DynamoDB Streams do not support encryption?~~ NOW IT DOES
- VPC endpoint is provided through a Gateway. Now your private EC2 (no exposure to public internet) instance can communicate with DynamoDB without diverting from the Amazon Network. 

## Security - RDS

- VPC provides network isolation
- Security Groups control network access to DB instances
- KMS provides encryption at rest
- SSL provides encryption in flight
- IAM policies **do not** provide protection from within the database, it provides protection for the RDS API
- IAM authentication is supported by PostgreSQL and MySQL
- Must manage user permissions within the database itself. ("This user can access to the RDS instance" such things can only be configured in RDS itself, not in IAM)
- MSSQL server and oracle support TDE (Transport Data Encryption) (can be enabled on top of KMS)

### Security - Aurora (more than RDS?)

- Since there is no MicroSoft SQL or Oracle support, ~~MSSQL server and oracle support TDE (Transport Data Encryption) (can be enabled on top of KMS)~~

## Security - Lambda

- IAM roles attached to each Lambda function (we did this EVERY.SINGLE.TIME we define the lambda function)
- What your lambda function can do in terms of 1. Sources and 2. Targets
- KMS encryption for secrets
- SSM parameter store for configurations. (can even encrypt the secrets within SSM with KMS for paranoid patients)
- CloudWatch Logs
- Deploy in VPC to access private resources (within that VPC) (e.x. RDS is deployed within your VPC. So if you want to handle it by Lambda, you might deploy the function within the VPC)

## Security - Glue

- IAM policies for the Glue service
- **Configure Glue to only access JDBC through SSL, connection to the JDBC can be encrypted**
- **Data Catalog can be encrypted by KMS**
- **Connection passwords (used to make connection with RDS): Encrypted by KMS**
- Data written by AWS glue - security configurations
    - If it's written to S3, S3 encryption mode: SSE-S3 or SSE-KMS
    - CloudWatch encryption mode
    - Job bookmark encryption mode

## Security - EMR (SO FUCKING IMPORTANT)

- Using Amazon EC2 key pair for SSH credentials
- Attach IAM roles to EC2 instances for:
    - proper S3 access
    - for EMRFS requests to S3
    - DynamoDB scans through Hive
- EC2 security groups
    - one for master node
    - another one for cluster node (core node or task node)
- Encrypts data at-rest: EBS encryption, open source HDFS encryption, LUKS + EMRFS for S3
- In-transit encryption: node to node communication, EMRFS, TLS
- **Data is encrypted before uploading to S3.** (EMR doesn't let us to store unencrypted data into S3)
- Kerberos authentication (provide authentication from Active Directory)
- Apache Ranger : Centralized Authorization (RBAC - Role Based Access) - setup on external EC2 (must be installed externally)
- Must read [link](https://aws.amazon.com/blogs/big-data/best-practices-for-securing-amazon-emr/)

## Security - ElasticSearch 

- Amazon VPC provides network isolation
- ElasticSearch policy to manage security further
- Data security by encrypting data at-rest using KMS
- Encryption in-transit using SSL
- IAM or Cognito based authentication
- **Amazon Cognito allow end-users to log-in to Kibana through enterprise identity providers such as Microsoft AD using SAML.**

## Security - RedShift (SO FUCKING IMPORTANT AS WELL)

- VPC provides network isolation
- Cluster security groups
- Encryption in flight using the JDBC driver enabled with SSL
- Encryption at rest using KMS or an **HSM device** (for HSM, establish a connection)
- Supports S3 SSE using default managed key
- Use IAM roles for RedShift to access other AWS resources (e.x. S3 for dumping or loading, KMS)
- And that IAM role must be referenced in the COPY or UNLOAD command (or alternatively paste access key and secret key credentials in the SQL statement

## Security - Athena

- IAM policies to control access to the service
- Data is in S3, so it can inherit all the security from S3 (IAM policies, bucket policies & ACLs)
- Encryption of data according to S3 standards : SSE-KMS, SSE-S3, CSE-KMS
- Encryption in transit using TLS between Athena and S3 and JDBC driver (it's gonna be enabled by SSL)
- **Fine grained access using the AWS Glue Catalog**

## Security - QuickSight

- Standard edition:
    - IAM users
    - Email based accounts
- Enterprise edition:
    - Active Directory
    - Federated Login
    - Supports MFA (multi factor authentication)
    - Encryption at rest and in SPICE.
- Row Level Security to control which users can see which rows 

# STS (Security Token Service)

- Allows to grant limited and **temporary** access to AWS resources.
- Token is valid for up to one hour (must be refreshed)
- Cross Account Access
    - Allows users from one AWS account access resources in another
- Federation (Active Directory)
    - Provides a non-AWS user with temporary AWS access by linking users Active Directory credentials
    - Uses SAML (Security Assertion markup language)
    - Allows Single Sign On (SSO) which enables users to log in to AWS console without assigning IAM credentials
- Federation with third party providers / Cognito
    - Used mainly in web and mobile applications
    - Makes use of Facebook / Google/  Amazon etc to federate them

## Cross Account Access

- Define an **IAM role** for another account to access
- Define which accounts can access this IAM role
- Use AWS STS (Security Token Service) to retrieve credentials and impersonate the IAM role you have access to (AssumeRole API)
- Temporary credential can be valid between 15 minutes to 1 hour.

So the scenario is as follows. The user wants some particular role (from the same or other account), Then you make a request, (AssumeRole API) to the AWS STS. STS checks permission by talking to IAM, if it's well configured, then the user will be granted with temporary security credential

# Identity Federation

- Federation lets users outside of AWS to assume temporary role for accessing AWS resources. 
- These users assume "identity provided access role"

User (who don't have AWS account) have access to third party servers (think of Facebook) for log-in. AWS trust this 3rd party. User login to 3rd party, and the 3rd party will give temporary credential. Then the use can access AWS (only temporarily)

- Federation assumes a form of 3rd party authentication like,,,
    - LDAP
    - Microsoft Active Directory (~= SAML) (just an implementation of SAML)
    - Single Sign On
    - Open ID
    - Cognito
- Using Federation, you don't need to create IAM users (user management is outside of AWS)

## SAML federation for enterprises

- To integrate Active Directory / ADFS with AWS (or any SAML 2.0)
- Provides access to AWS console or CLI (through temporary credentials)
- No need to create an IAM user for each of your employees


![CLIbasedOne](https://camo.githubusercontent.com/90e59031ad173c69236bd22699fd7889eceb1dce/687474703a2f2f646f63732e6177732e616d617a6f6e2e636f6d2f49414d2f6c61746573742f5573657247756964652f696d616765732f73616d6c2d62617365642d66656465726174696f6e2e6469616772616d2e706e67)

![consolebased](https://www.ipragmatech.com/wp-content/uploads/2015/05/saml-based-sso-to-console.diagram11.png)

In the console based, AWS SSO endpoint should talk to STS in order to validate the request.

## Custom Identity Broker Application For Enterprises

- Use only if identity provider is not compatible with SAML 2.0
- The identity broker must determine the appropriate IAM policy. You have to program your own "identity broker"

![image](https://camo.githubusercontent.com/fd34c19aa8e0f43c578e9ba30ac81249041348c8/687474703a2f2f646f63732e6177732e616d617a6f6e2e636f6d2f49414d2f6c61746573742f5573657247756964652f696d616765732f656e74657270726973652d61757468656e7469636174696f6e2d776974682d6964656e746974792d62726f6b65722d6170706c69636174696f6e2e6469616772616d2e706e67)

## AWS Cognito - Federated Identity Pools for *Public* Applications

Scenario that mobile application user is trying to put or retrieve object from S3.

- Goal:
    - Provide direct access to AWS resources from the Client Side
- How:
    - Log in to federated identity provider - or remain anonymous
    - Get temporary AWS credentials back from the Federated Identity Pool
    - These credentials come with a pre-defined IAM policy stating their permissions
- Note:
    - Web Identity Federation is an alternative to using Cognito, but Amazon recommends to stick with the Cognito (pshh..)

So the identity provider can be CUP, Google, Facebook, Twitter, SAML, OpenID,... or whole bunch of stuff.

1. App log-in to identity provider
2. App receives a token from Identity Provider
3. App now authenticate to Federated Identity Provider (talking to Federated Identity)
4. Federated Identity verifies the token by talking to Identity Provider
5. Federated Identity gives App temporary AWS credentials
6. Now Federated Identity will get credentials from STS
7. Then the federated identity will give app a temporary AWS credentials
8. Now talk to S3 bucket

# Policies - leveraging AWS variables

So now we will talk about advanced policy. READ THIS [LINK](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/reference_policies_variables.html)

- \$\{aws:username\}: to restrict users to tables / buckets
- \$\{aws:principaltype\}: account, user, federated or assumed role
- \$\{aws:PrincipalTag/department\}: to restrict using Tags

So these variables will get replaced at runtime

The above thing was all about the AWS accounts. How about Federated Users ?

READ THIS [link](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#condition-keys-wif)

- \$\{aws:FederatedProvider\} : which IdP was used for the user (Cognito, Amazon,...)
- \$\{www.amazon.com:user_id\}, \$\{cognito-identity.amazonaws.com:sub\}...

## Policies advanced

- For S3, read the [policy](https://docs.aws.amazon.com/ko_kr/AmazonS3/latest/dev/example-bucket-policies.html)
- For DynamoDB, read the [policy](https://docs.aws.amazon.com/ko_kr/amazondynamodb/latest/developerguide/specifying-conditions.html)
- **For RDS, IAM policies do not help with in-database security. WE are responsible for users & authorization.** IAM policies to do authorization within RDS? It's not the way it's done.


# AWS CloudTrail

- Provides governance, compliance, and audit for your AWS account.
- It tracks every API call made to your accounts
- CloudTrail is enabled by default!
- Get an history of events / API calls made within you AWS account by: 
    - Console
    - SDK
    - CLI
    - AWS Services
- Can put logs from CloudTrail into CloudWatch Logs.
- If a resource is deleted in AWS, look into CloudTrail first! (for reprimanding the malicious deletion user)
- Only shows the past 90 days of activity
- The default UI only shows "Create", "Modify", or "Delete" events
- CloudTrail Trail:
    - Get a detailed list of all the events you choose
    - Ability to store these events in S3 for further analysis
    - Can be region specific or **global**
- CloudTrail Logs have SSE-S3 encryption by default when placed into S3.
- control access to S3 using IAM, Bucket Policy, etc...

# VPC Endpoints

It enhances the security of your network within your VPC.

- Endpoints allows you to connect to AWS services using a private network instead of the public www network.

So the basic scenario is, you have a EC2 instance in private subnet. And there is a SQS, which is a public service, ergo accessible on the worldwide web. How can our instance talk to SQS? NAT Gateway? Stupid! Just create a VPC endpoint(a.k.a. privateLink) (FYI, see the below figure)

![image](https://user-images.githubusercontent.com/34101059/76379590-cb472080-6393-11ea-80c6-774f05e58fe7.png)

- They scale horizontally and are redundant
- They remove the need of Internet Gateway, NAT, etc... to access AWS services



