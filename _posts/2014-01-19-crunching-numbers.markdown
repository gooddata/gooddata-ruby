---
layout: post
title:  "Crunching numbers"
date:   2014-01-19 13:56:00
categories: recipe
pygments: true
perex: Regardless of how much other things there are in the project the most important thing is to get some numbers out. Let's do it. With Ruby.
---

##The case for MAQL
MAQL is a language that is fairly similar to SQL but it is aimed towards getting the data from OLAP system. You are never forced to talk about columns and specify joins explicitly. This is great but there are some drawbacks. Same as SQL MAQL is aimed towards users more than machines which does not help for automation but there is one more caveat that make it hard to use even for humans. Probably to your surprise

  SELECT SUM(Amount)

Is not a MAQL statement (even though you probably have seen this on UI). The more correct (and what goes back and forth over the wire) is

  SELECT SUM([/gdc/md/132131231/obj/1])

GoodData UI does a great job at hiding this complexity from you but this significantly hinders the use of MAQL over and API by regular Joes. Ruby SDK tries to alleviate the situation with some tricks. It also gives you many tools to programmatically define and deal with reports and lays the foundations for test driven BI.

##Jack in
If you do not have one, plese create a project and jack in. Best would be the project from our tutorial so you can get predictable results.

First let's look around. There are no metrics

	GoodData::Metric[:all]
	> []

there is one fact

	GoodData::Fact[:all]
  	> [{"link"=>"/gdc/md/ptbedvc1841r4obgptywd2mzhbwjsfyr/obj/223",
	    "author"=>"/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248",
	    "tags"=>"",
	    "created"=>"2014-02-18 07:44:26",
	    "deprecated"=>"0",
	    "summary"=>"",
	    "title"=>"Lines changed",
	    "category"=>"fact",
	    "updated"=>"2014-02-18 07:44:26",
	    "contributor"=>"/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248"}]

##First metric
Let's create our first metric. There are couple of ways so I will show them one by one. Regardless of how you create the metric the result is the same so pick the one that suits your style or situation.

TBD(add identifier based metric)

	m = GoodData::Metric.create("SELECT SUM([/gdc/md/ptbedvc1841r4obgptywd2mzhbwjsfyr/obj/223])")

You can do it like this but obviously this is the ugly verbose way.

    m = GoodData::Metric.xcreate('SELECT SUM(#"Lines changed")')

Here you are using the name of the fact. Let's notice couple of things. First we are not using create any more. Method xcreate stands for eXtended notation and tries to turn it into valid MAQL. When you are specifying the fact you are doing it using #"NAME".

Regardless of which way you used you have a metric definition. Metric is only locally on your computer we haven't saved it yet. Let's do it.

    m.save
    > RuntimeError: Meric needs to have title

Uh ok. You have two options

    m.title = "My shiny metric"

or

    m = GoodData::Metric.xcreate(:title => "My shiny metric", :expression => 'SELECT SUM(#"Lines changed")')

Go ahead and try saving it again.

    m.save
    > #<GoodData::Metric:0x007f95b609b548 ....

Great, looks good. Let's see if it worked

    m.saved?
    > true

    m.uri
    > "/gdc/md/ptbedvc1841r4obgptywd2mzhbwjsfyr/obj/292"

Let's get some numbers. You can execute the metric.

    m.execute
    > 9.0

Fantastic. You just created your first report over API.

##More on metric execution

Maybe you are wondering if you cannot just execute stuff to poke around. Well you kinda can. The API does not allow to execute a metric without it is saved (but we hope this will change soon). SDK tries to hide this from you but sometimes you can see the wiring. Let's explore. This is our well known metric

    m = GoodData::Metric.xcreate('SELECT SUM(#"Lines changed")')

Let's try executing it

    m.execute
    > 9

It works. What happens behind the scenes is that SDK saves the metric and then deletes it again. It should mostly work

    m.is_saved?
    > false

    m.uri
    > nil

But sometimes you can see some inconsistencies.

    m.title
    > "Untitled metric"

This should not stop you most of the time. Just keep this in mind. Hopefully it will go completely away soon.



