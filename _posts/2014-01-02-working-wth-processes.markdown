---
layout: post
title:  "Working with processes"
date:   2014-01-19 13:56:00
categories: draft
pygments: true
perex: Use the Ruby SDK to interact with ETL processes that you have uploaded to the GoodData platform.
---


The Ruby SDK enables you to manage your GoodData projects and to control the ETL processes for them. Using the SDK, you can deploy process schedules and execute them.

And where is the fun if you can't do cool stuff like this over API?

Read on to learn more about processes and the whole execution platform.

##CLI

Before we delve into APIs let's briefly explore the capabilities of command line interface for the Ruby SDK.

###List processes
For a given `PROJECT_ID`, this command lists the project's processes:

{% highlight ruby %}
  gooddata -p PROJECT_ID process list
{% endhighlight %}

###Get process details

This command returns details about the specified project's process:

{% highlight ruby %}
  gooddata -p PROJECT_ID  process get --process_id PROCESS_ID
{% endhighlight %}

###Deploy process

Use the following command to deploy a specified process to the target project.

{% highlight ruby %}
  TBD
{% endhighlight %}

##API

The following Ruby commands execute GoodData APIs for managing processes.

###Get processes in a project
{% highlight ruby %}
  processes = GoodData::Process.all
{% endhighlight %}

###Accessing specified process properties
{% highlight ruby %}
  process = processes.first
  p.name
  p.type
  p.graphs
  p.executables
{% endhighlight %}

###Execute process

**NOTE:** This command blocks subsequent commands until process execution is done.

{% highlight ruby %}
  graph_to_execute = p.executables.first // just an example you have to pick whichever makes sense for you
  process.execute_process(graph_to_execute, {"param1" => "value1", "param2" => "value2"})
{% endhighlight %}