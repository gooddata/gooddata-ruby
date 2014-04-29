---
layout: post
title:  "Getting Started"
date:   2014-01-19 13:56:00
categories: get-started
pygments: true
---

You just installed the Ruby GEM and want to start playing around, right? Follow this guide to learn more about the basics and most common use cases.  

##Disclaimer

This SDK is intended for developers. Programming experience is required. Some operations that can be executed using the SDK can be destructive to your projects and data. For more information, please contact GoodData Customer Support.

##Table of Contents

- [Prerequisities](#prerequisites)
- [Install](#install)
- [First steps](#first)
- [Retrieving Objects](#retrieve)
- [Metrics (not only) Creation](#metrics)
- [Report Handling](#reports)
- [Dashboard Operations](#dashboards)
- [Direct Post Requests](#direct)

##Prerequisites

1. Acquired a GoodData platform account.
2. Set up your Ruby environment. Supported versions of ruby are 1.9, 2.0 and higher. Jruby 1.7 and higher. 1.8 is not supported.
3. Acquired a project authentication key if you are creating new projects or have Administrator access to any project that you wish to modify using this SDK.

##Install

If you are using gems just

{% highlight ruby %}
gem install gooddata --version 0.6.0.pre11
{% endhighlight %}

If you are using bundler. Add

{% highlight ruby %}
gem "gooddata"
{% endhighlight %}

into Gemfile and run

{% highlight ruby %}
bundle install
{% endhighlight %}

##First steps{#first}

There are several methods by which you can work with the GoodData Ruby SDK. Let's look at the major ones.

###irb
`irb` is an interactive console that is provided with your Ruby installation. You may  use gooddata sdk inside your irb. Below are some of the basic steps. 

First, launch irb. In your terminal, execute the following:

{% highlight ruby %}
  irb
{% endhighlight %}

You should receive a message similar to the following, which indicates that you are inside the interactive Ruby environment:

`2.1-head :001 >`

Let's start playing with gooddata. Enter the following:

{% highlight ruby %}
  > GoodData
{% endhighlight %}

You should receive the following:

`NameError: uninitialized constant GoodData`

This error message indicates that irb does not know about the gooddata SDK. So, let's tell irb to require the SDK:

{% highlight ruby %}
  > require 'gooddata'
  => true
{% endhighlight %}

Ok. Now, repeat the previous command:

{% highlight ruby %}
  > GoodData
  => GoodData
{% endhighlight %}

The response indicates that irb knows about SDK. 

Let's try to log in to the GoodData platform with your credentials through the SDK. 
* For clarity, the `>` sign is omitted in the irb session from now on.

{% highlight ruby %}
  GoodData.connect("john@example.com", "password")
{% endhighlight %}

You should be logged in. Now, you can perform tasks that do not require you to be inside of a specific project. For example, use the following to list all of your projects:

{% highlight ruby %}
  GoodData::Project.all
{% endhighlight %}

To work with a project, you must define the project for the SDK. For example, suppose you wish to list the reports in a project. You must tell the SDK the project to review: 

{% highlight ruby %}
  GoodData.project = 'YOUR_PROJECT_ID'
{% endhighlight %}

To list the reports in this project:

{% highlight ruby %}
  GoodData::Report.all
{% endhighlight %}

Ok. To exit irb, enter:
 `exit`

###gooddata console
Working with GoodData SDK using irb can be cumbersome. To make things a bit easier, Gooddata SDK includes a `gooddata` command line interface. 

To start the console:

{% highlight ruby %}
  gooddata console
{% endhighlight %}

In the terminal, you should see something like the following:

{% highlight ruby %}
  sdk_live_sesion:
{% endhighlight %}

Since the console requires the SDK, you do not need to require it. So, you can log in and begin working with your projects:
* To exit, enter: `exit`

###jack_in
For even better results, you can try using the following:
{% highlight ruby %}
  gooddata -U john@example.com -P password -p PROJECT_ID project jack_in
{% endhighlight %}

In a single command, the above launches the command line interface, logs you into the platform, and identifies the project to which to connect. At this point, you may begin entering commands:

{% highlight ruby %}
  GoodData::Report.all
{% endhighlight %}

**Tip:** Use `gooddata auth store` to save your username and password locally, so you do not have to type it every single time. If you do not specify this command explicitly, the stored default is used. 

###Program
To create a program that runs without user input, you must write the whole program. There are no shortcuts. 

A simple program that does something useful is the following:

{% highlight ruby %}
  require 'gooddata'
  require 'pp'

  GoodData.connect('username', 'password')
  GoodData.use 'my_project_id'

  pp GoodData::Report[:all]
{% endhighlight %}

Save this into a file called `my_first.rb`. Run it using the following command: 
`ruby my_first.rb`

The following sections assume that you are using one of the above methods and are comfortable using the SDK. 

##Logging in{#login}

You can connect as a user easily.

{% highlight ruby %}
GoodData.connect("john@example.com", "password")
{% endhighlight %}

This will assume our default servers and the webdav server used for uploading files will be determined automatically. If you need to explicitly provide such information you can also use another form.

{% highlight ruby %}
GoodData.connect( :login => 'svarovsky@gooddata.com',
                  :password => 'pass',
                  :server => "https://na1.secure.gooddata.com",
                  :webdav_server => "https://na1-di.gooddata.com")
{% endhighlight %}

Picking project to work with. There are several ways how to do it.

{% highlight ruby %}
GoodData.connect( :login => 'svarovsky@gooddata.com',
                  :password => 'pass',
                  :project => 'project_pid')

GoodData.project = 'project_pid'

GoodData.use 'project_pid'
{% endhighlight %}
