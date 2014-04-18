---
layout: post
title:  "Workign with processes"
date:   2014-01-19 13:56:00
categories: draft
pygments: true
perex: GoodData is not just about data marts. It is also about surrounding ETL platform. You can deploy processes schedule then and execute them. Where is the fun if you couldn't do it over API
---

If you want to read more about processes and the whole execution platform this is the place to start. 

##CLI

Before we delve into APIs let's briefly explore the capabilities of gooddata command line tool

###List processes
Listing processes in particular project
{% highlight ruby %}
  gooddata -p PROJECT_ID process list
{% endhighlight %}

###Get process details

{% highlight ruby %}
  gooddata -p PROJECT_ID  process get --process_id PROCESS_ID
{% endhighlight %}

###Deploy process details
{% highlight ruby %}
  TBD
{% endhighlight %}

API

###Get processes in a project
{% highlight ruby %}
  processes = GoodData::Process.all
{% endhighlight %}

Accessing typical properties
{% highlight ruby %}
  process = processes.first
  p.name
  p.type
  p.graphs
  p.executables
{% endhighlight %}

###Execute the process

This will actually block until the execution is done
{% highlight ruby %}
  graph_to_execute = p.executables.first // just an example you have to pick whichever makes sense for you
  process.execute_process(graph_to_execute, {"param1" => "value1", "param2" => "value2"})
{% endhighlight %}



