# This repository is for AWS certified Big Data Specialty 2020

## Roadmap

- First week : ~~A Cloud Guru~~
- Second Week : Udemy ([linkhere](https://www.udemy.com/course/aws-big-data/)) with [LinuxAcademy](https://linuxacademy.com/course/aws-certified-big-data-specialty-course/)?
- Third Week : Refer to official documentation of AWS (recommended service : Kinesis, ElasticSearch, QuickSight, RedShift, EMR, DynamoDB, CloudSearch, so on and so forth), [CrudeTest(WhizLab)](https://www.whizlabs.com/aws-certified-big-data-specialty/)
- Last Week : Various White papers

## Useful Links

- [basicroadmap1](https://towardsdatascience.com/how-did-i-get-certified-with-aws-big-data-specialty-e26f20114d3c)
- [basicroadmap2](https://medium.com/@simonleewm/my-path-to-aws-big-data-speciality-certification-4baff3a8150)
- [Big_data_options](https://www.youtube.com/watch?v=ovPheIbY7U8)
- [DynamoDB](https://www.youtube.com/watch?v=HaEPXoXVf2k)
- [RedShift](https://www.youtube.com/watch?v=TJDtQom7SAA)
- [Kinesis](https://www.youtube.com/watch?v=jKPlGznbfZ0)



## Feedback from passers - 1

- Toughest exam I ever experienced.  Passed Solution Architect Assoc 3 weeks earlier. (That helped tremendously). Here is some feedback from the exam. 
- Course could be improved by covering Microstrategy (what it is and use case). 
- Exam tried from many angles to explore different ways to get data into HDFS quickly.  How to get massive amounts of data in quickly. 
- Lots of buzz words but in the wrong context to throw you off.  If data to be processed is already in "XX", but originated from multiple varied sources, we don't really care.  It is in "XX" as our starting point.  S3distcp may catch your eye, but it is paired with something nonsense (wrong context), you have to discard that option.  I would caution everyone to not jump on the "I know this one" because of a detail you remember from the course. Really really read carefully.  It is exhausting, but the only way to make it through the gauntlet.
- Please also cover Thrift server in the course content (what it is and use case).
- In addition to this course and exam, it helped having recently studied for AWS Solutions Architect.
- I would recommend 2018 reInvent Best Practices (AWS YouTube videos ) on EMR, Dynamo, Redshift,  and Data Lake.  For me, those were my weakness because I have no real world experiences in those topics.
- Videos were highly relevant to the exam. I watched each hour long video twice because it was info packed. Highly recommend these videos!
- Data warehouse schema design showed up in two questions and I struggled there because I’m an OLTP veteran retooling my skill set.


## Feedback from our second passer

1. Security questions were focused on limiting access to a portion of resources in S3, Redshift, DynamoDB ( based on roles)
2. Visualization was focussed on Quicksight visual types(atleast 2 Qs), while a couple were on scenario for Jupytor & D3.js, and on Quicksight underlying dataset
3. ML was all about model Types ( binary. multi etc), along with instance type for deep learning
4. EMR was part of solution in almost 50% of questions, so varied coverage - Hive, Spark, Presto featured. S3 similar nothing specific except security.
5. Redshift was on Distribution, limiting role based access to data and recovering table from snapshot (None on Spectrum or Copy)
6. Cloudsearch not much
7. DynamoDB nothing direct(like LSI, GSI) but was an option on questions with heavy transactions

Some off-guard scenarios

8. Multi PB of one time data migration within a tight timeframe choices were to pick between  Direct Connect or many Snowball edge. Edge was a interesting option since no processing requirement and all the data was in one data store - but there was no Snowball choice at all.
9. In a 2 part answer - one part was Emergency response with a few seconds delay allowance, choices were SQS or Kinesis streams. The other part of the answer convinced me to side with SQS but I wonder if it is also because SQS is more reliable than Kinesis Streams.
10. Centralized Hive metastore, requirement to share between multiple teams in same account  - there was no option of Glue service which I found interesting.
11. RCU, WCU computation based on a expected Read/Write ratio rather than actual processing metrics


