# Big data visualization? == Amazon QuickSight!

- It is an end-user tool
- Fast, easy, cloud-powered business analytics service
- Allows all employees in an organization to:
    - build visualization
    - perform ad-hoc analysis (it's like on-premise version of analysis)
    - quickly get business insights from data
    - Anytime, **on any device?!**
- Serverless

## What can be the data source of QuickSight?

- Redshift
- Aurora / RDS
- Athena
- EC2-hosted databases
- **Files** (S3 or on-premises)
    - Excel (wow....)
    - CSV, TSV
    - Common or extended log format
- Data preparation allows limited ETL (e.x. unwanted filed name in CSV, you can change it in the preparation stage) (e.x.2. change the data types, or issuing SQL queries... )

## SPICE

QuickSight doesn't sit in the top of the data directly. It's actually importing your data sets into an engine called SPICE (super fast, parallel, in-memory calculation engine)

Kinda resembles Redshift:
    - uses columnar storage, in-memory, machine code generation
    - Accelerates interactive queries or large datasets.

- Each user gets 10GB of SPICE
- Highly available / durable
- Serverless
- Scales to hundreds of thousands of users

## Use Case

- Interactive ad-hoc exploration / visualization of data
- Dashboards and KPI
- Stories
    - Guided tours through specific views of an analysis
    - Convey key points, thought process, evolution of an analysis
- Analyze / visualize data from :
    - Logs in S3
    - On-premise databases
    - AWS (RDS, Redshift, Athena, S3)
    - SaaS applications, like Salesforce
    - Any JDBC/ODBC data source.

## Anti-Pattern

- Highly formatted canned reports (rigid report)
- ETL (Use glue instead for ETL)

## Security

- Multi-factor authentication on your account
- VPC connectivity
    - Add QuickSight's IP address range to your database security groups
- Row-level security (row granularity) (a.k.a. RLS)
- private VPC access (enabled by Elastic Network Interface, AWS Direct Connect)

## User Management

- Users defined via IAM, or email sign-up
- Active Directory integration with **QuickSight Enterprise Edition**

## Pricing

- Annual subscription -> standard is \$9 /user /month, enterprise is doubled
- Extra SPICE capacity (beyond 10GB) \$0.25 (0.38)/GB/month
- Month to month -> standard is \$12 /GB/month, doubled for enterprise
- Enterprise edition supports encryption at rest, Microsoft active directory integration

## (important) QuickSight Machine Learning Insights

- ML-powered anomaly detection
    - Uses random cut forest
    - identify top contributors to significant changes in metrics
- ML-powered forecasting
    - Also uses random cut forest
    - detects seasonality and trends
    - excludes outliers and imputes missing values 
- Autonarratives
    - Adds "story of your data" to your dashboards
- Suggested Insights
    - "Insights" tab displays read-to-use suggested insights.

# How to choose the appropriate Visual Types in QuickSight?

There are lots of lots of visual types in QuickSight.

AutoGraph will automatically select the perfect visual type just by selecting the data. (Tableau also has this function too) 

## Bar Charts

For comparison and distributions (histogram)

## Line graphs

For changes over time, time series

## Scatter plot, heat map (= scatter plot, but colored, technically 3d data)

For correlation

## Pie graphs, tree maps

For aggregations

Tree maps shows hierarchical aggregation.

## Pivot Table

For tabular data (multi-dimensional data) e.x. pivoting on the region

## Stories

## Additional Visual Types

- KPI (Key Performance Indicators) (compare key values to its target value)
- Geospatial Chars (maps)
- Donut Charts (used to show percentages, when there are not many values)
- Gauge Charts (compare values in a measure) e.x. bandwidth usage out of available bandwidth
- Word cloud

# Other visualization tools along

- Web-based visualization tools (deployed to the public) (not internal to the organization, individual)
    - D3.js
    - Chart.js
    - Highchart.js

- Business Intelligence Tools
    - Tableau
    - MicroStrategy




