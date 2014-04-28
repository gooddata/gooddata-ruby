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

There are several ways how to work with GoodData SDK. Let's look at all the major ones one by one.

###irb
If you are familiar with Ruby at least a little bit you must have seen `irb`. This is an interactive console that comes with your ruby installation. You can start using gooddata sdk inside your irb like this. First you have to star irb so in your terminal run

{% highlight ruby %}
  irb
{% endhighlight %}

This will respond with something similar to `2.1-head :001 >`. This means you are inside of ruby interactive environment.

Now you can try actually playing with gooddata. Type

{% highlight ruby %}
  > GoodData
{% endhighlight %}

It should return `NameError: uninitialized constant GoodData`. This is trying to say that it does not know anything about a gooddata SDK. So let's tell it to require it

{% highlight ruby %}
  > require 'gooddata'
  => true
{% endhighlight %}

Ok. Now repeat the previous experiment.

{% highlight ruby %}
  > GoodData
  => GoodData
{% endhighlight %}

Great. Now it knows about SDK. Let's try to log in with your credentials. I will start omitting the `>` sign inthe irb session for clarity.

{% highlight ruby %}
  GoodData.connect("john@example.com", "password")
{% endhighlight %}

If you typed it correctly you should be logged in. Now you can perform some tasks that are not requiring to be inside a particular projects. For example listing all projects.

{% highlight ruby %}
  GoodData::Project.all
{% endhighlight %}

If you want to list for example the reports in a project you first have to tell the sdk which project you will work on. One of the ways to do this is

{% highlight ruby %}
  GoodData.project = 'YOUR_PROJECT_ID'
{% endhighlight %}

Now you can list for example reports

{% highlight ruby %}
  GoodData::Report.all
{% endhighlight %}

Ok. Now exit from the irb typing `exit`.

###gooddata console
This was one and the most cumbersome way to start working with GoodData SDK using irb. Ther is a slightly better way. Gooddata SDK comes with a `gooddata` command line interface. You can try typing

{% highlight ruby %}
  gooddata console
{% endhighlight %}

It probably looks similar as you have started the irb. In the terminal you should see something like

{% highlight ruby %}
  sdk_live_sesion:
{% endhighlight %}

The only difference is that it already required gooddata for you so you can start logging in and all that stuff we have already seen (exit again by typing `exit`).

###jack_in
There is even better way. You can try
{% highlight ruby %}
  gooddata -U john@example.com -P password -p PROJECT_ID project jack_in
{% endhighlight %}

This will spin up a live session for you like `gooddata console` but on top of it it will log you in and set you up in a project. You can readily start typing commands like

{% highlight ruby %}
  GoodData::Report.all
{% endhighlight %}

By using `gooddata auth store` you can even save your username and password locally so you do not have to type it every single time. If you do not specify it explicitly the stored default will be used. This is a recommended and fastest approach to start trying things out.

###Program
If you want to create a program that would run and not do things interactively you have to write the whole program. There are no shortcuts here and it is very similar to the first irb example. The simplest program that does something useful might look like this

{% highlight ruby %}
  require 'gooddata'
  require 'pp'

  GoodData.connect('username', 'password')
  GoodData.use 'my_project_id'

  pp GoodData::Report[:all]
{% endhighlight %}

put this into a file `my_first.rb` and run it using `ruby my_first.rb`

In the next sections I will assume that you are using whatever method suits your needs and will omit it for brevity.

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
