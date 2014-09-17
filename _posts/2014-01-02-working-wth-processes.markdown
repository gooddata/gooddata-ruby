---
layout: guides
title:  "Working With Processes"
date:   2014-01-19 13:56:00
categories: general
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
  gooddata -p PROJECT_ID  process show --process_id PROCESS_ID
{% endhighlight %}

###Deploy process

Use the following command to deploy a specified process to the target project. This will take care of zipping it and uploading it to the server calling correct APIs in the process. You can then just go to the UI and schedule the process as you please.

{% highlight ruby %}
  gooddata -p PROJECT_ID process deploy --dir DIR_WHERE_YOUR_PROCESS_LIVES --name PROCESS_NAME
{% endhighlight %}

###Executing process
There are two ways how to achieve this. Either execute a process directly. Provide it all it needs and just fire it off or prepare a schedule. There are couple of things to conside
* when executing a schedule you do not have to provide the parameters. this happens only once during the schedule creation as opposed to execution of the process where you have to provide parameters every single time.
* system will refuse to run the schedule several times at any one moment. This might be both a pro or a con depending on a situation
* log of execution of a process is not visible in the admin console. But you can grab the list from API.

####Executing process
{% highlight ruby %}
  gooddata -l -p PROJECT_ID process execute --process_id PROCESS_ID --executable NAME_OF_THE_EXECUTABLE
{% endhighlight %}

Note: NAME_OF_THE_EXECUTABLE is a name of the executed graph or a script. Best way how to know what to put here is to inspect the deployed process with the command described above in *Get process details*. It will list the usable executables. Make sure you use it verbatim and you should be safe.

##API

The following Ruby commands execute GoodData APIs for managing processes.

Let's start by setting up the client and project you will be using.

{% highlight ruby %}
  client = GoodData.connect 'YOUR_USER@gooddata.com', 'YOUR_PASSWORD'
  project = client.projects('YOUR-PROJECT-ID')
{% endhighlight %}
###Get processes in a project
{% highlight ruby %}
  project = client.projects('YOUR-PROJECT-ID')
  processes = project.processes
{% endhighlight %}

###Get specific processes by a process id
{% highlight ruby %}
  process = project.processes('YOUR-PROCESS-ID')
{% endhighlight %}

###Accessing specified process properties
{% highlight ruby %}
  p = project.processes.first
  p.name
  p.type
  p.graphs
  p.executables
{% endhighlight %}

###Deploying process
You can deploy process with SDK like this:

{% highlight ruby %}
  client = GoodData.connect 'YOUR-USER@gooddata.com', 'YOUR-PASSWORD'
  project = client.projects('YOUR-PROJECT-ID')
  process = project.deploy_process('./spec/data/ruby_process', type: 'RUBY', name: 'Demo Process')
{% endhighlight %}e process

**NOTE:** This command blocks subsequent commands until process execution is done.

{% highlight ruby %}
  graph = process.execute(process.executables.first, :params => {"param1" => "value1", "param2" => "value2"}, :hidden_params => {"param1" => "value1"}))
{% endhighlight %}

###Creating a schedule
{% highlight ruby %}
  schedule = process.create_schedule('0 15 27 7 *', process.executables.first)
{% endhighlight %}


###Execute a schedule
{% highlight ruby %}
  schedule.execute
{% endhighlight %}
