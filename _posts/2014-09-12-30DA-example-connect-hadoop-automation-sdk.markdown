---
layout: guides
title:  "Working with Hadoop & AWS S3"
date:   2014-07-09 10:00:00
categories: cool
tags:
- api
- hadoop
pygments: true
perex: Demonstrates how to create a small Hadoop cluster/local build, connect it to S3, and pipe data directly into a GoodData project.
---

The ring leader in bringing about "Big Data", Hadoop is the industry standard for large scale data sets. Based on a Google paper on the "Google File System" (GFS) and Google's MapReduce proposal, Hadoop and stemmed to include Apache Hive, Apache Spark, Apache Pig and the powerful machine learning library called Apache Mahout. 

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/a86dd57a-74df-4725-bead-3cbc5e228509.png">
<div>
</div>
</div>
</div>

Whispered in the shadows of engineering, I am sure you have heard the word "Hadoop" before but few dare travel to Hadoop due to it's difficulty. Is it that difficult though? Today's snippet will arguably be the hardest and perhaps only apply to a small percentage of project. It is valuable for you in two ways, first, it should prove without a doubt that pretty much anything you want can be done with Ruby, no matter what the service and second, it will let you be able to tell a client, "Sure, you can run PIG queries across a Hadoop cluster".

Today's snippet has three prerequisites: 

1. Set up account with [Mortar Data](https://app.mortardata.com/signup).
2. You will need an [AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html?nc1=h_ct) for storing data to S3.
3. The access and secret keys for your S3 bucket ([instructions](http://blogs.aws.amazon.com/security/post/Tx1R9KDN9ISZ0HF/Where-s-my-secret-access-key)).


Now let's talk about Mortar Data. The primary value add of Hadoop is HDFS or Hadoop Distributed File System; this means files can be stored across machines or even farms of machines with replication and somewhat performant accessibility. Setting up these machines and then deploying Hadoop on is complex and has lead to projects like [Apache ZooKeeper](http://zookeeper.apache.org/) to "wrangle" thousands of machines into something usable. Enter Mortar--a service which sits on top of Hadoop and let's you deploy local or clustered versions as easy as an Amazon EC2 machine (one-click).


Mortar itself is built on top of AWS so each is a lay on top of the other which is really what technology is; many parallel and stacked layers.


<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/338c3da7-4538-431e-8ade-3983aa93dc79.png">
<div>
<small>Architecture for ETL between S3, Had.</small></div>
</div>
</div>

- Open Terminal, install the Mortar Development Framework, S3, and the mortar-api, this is easy enough as they are all Ruby Gems. 

{% highlight bash %}
gem install mortar mortar-api-ruby s3
{% endhighlight %}

- Mortar uses a command line tool to manage setting up jobs, clusters, etc. Let's grab their example directory so you can see how this works. 

{% highlight bash %}
mortar projects:fork git@github.com:mortardata/mortar-examples.git my_test_hadoop
{% endhighlight %}

- Download this script ([hadoop.rb](https://s3.amazonaws.com/xnh/hadoop.rb)) and then return to Terminal and move it into the my_test_hadoop folder you just created.

{% highlight bash %}
mv ~/Downloads/hadoop.rb my_test_hadoop/hadoop.rb
{% endhighlight %}

- Go ahead an open one of the PIG scripts. PIG drives Hadoop (or HIVE) and while it is different than Ruby it is very straight forward. 

{% highlight bash %}
open ~/my_test_hadoop/pigscripts/coffee_tweets.pig
{% endhighlight %}

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/845cdfa8-58f6-4b2a-b9fe-85ff8d4cfc52.png">
<div>
<small>coffee_tweets.pig</small></div>
</div>
</div>

- Go to the [S3 web console](https://console.aws.amazon.com/s3/home?region=us-east-1) and create a new bucket (you can name it whatever you like).
- The format for accessing S3 from PIG is "s3n://KEY:SECRET@BUCKET" so using that logic you should have an address that look something like this:

{% highlight bash %}
s3n://9k3f2EXAMPLE0k323:fj929EXAMPLEj3f+3929jf32@my_bucket_example
{% endhighlight %}

- Copy your s3n address with the correct information and change the value of "OUTPUT_PATH" in the coffee_tweets.pig script to your bucket address.

OK at this point you have reached a huge milestone. The Coffee Tweets determines from several million tweets who are the highest "coffee snobbery" as they put it. Technically you could run the drop and it would dump the cleaned and compiled data to your S3 bucket right now. However, you cannot run remote jobs without booting a cluster.

- With that in mind and in order to not have to pay much (the fees however, are nominal), we will use the web projects interface on Mortar which is free. Visit the new projects page here, and then click on "My Web Project" and select "Coffee Tweets". 

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/76d647a7-9251-4686-8eef-4a59894d5998.png">
<div>
<small>Select the Example Project, Coffee Tweets...</small></div>
</div>
</div>

- Return to the coffee_tweets.pig script on your machine and copy the text. Replace the text on the web editor with your own. 

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/733dc7f8-9ab3-4438-a847-fcafa2d8d2b9.png">
<div>
<small>Select the Example Project, Coffee Tweets...</small></div>
</div>
</div>

- Go ahead and click Validate, then select Run on the web project. While this is running take a moment to look at the logs to see all the processes running to enable what you are the functionality you are using.

From here there are several ways for the Ruby SDK could join the architecture. 

1. Set up a Ruby process to check on the S3 bucket and initialize the jobs on Mortar.
2. Create a local Ruby script which only checks the S3 bucket and automatically moves everything there to the project. 
3. Circumvent S3 entirely by having Ruby simply clone the S3 bucket to WebDAV. 

In our case we will chose Option #2 due to brevity, the method of accomplishing the other options should be clear.

- Open the script (hadoop.rb), you will have to edit the PROJECT ID, USERNAME, PASSWORD and the Access Key, Secret Key for S3.
- Next, change the bucket name and the output file to the resulting file generating by the PIG script. Personally, I would link these with a time stamp so that the Ruby process loads the file with the right data.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/f83493b2-5020-4fe9-a1b9-699f604e716b.png
">
<div>
<small>(hadoop.rb) Change the book and file to be downloaded.
</small></div>
</div>
</div>

- Finally upload the process to GoodData (edit the parts in bold in context).

{% highlight bash %}

zip process.zip hadoop.rb &&
gooddata -p PROJECT_ID process deploy --dir process.zip --name Jira &&
gooddata --process_id PROCESS_ID --executable jira.rb &&
gooddata -l -p PROJECT_ID process execute --process_id PROCESS_ID --executable hadoop.rb

{% endhighlight bash %}

And that is it for today, congratulations! The beginnings of Hadoop is now in your toolset.

