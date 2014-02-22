---
layout: post
title:  "Crunching numbers"
date:   2014-01-19 13:56:00
categories: recipe
pygments: true
perex: Regardless of how much other things there are in the project the most important thing is to get some numbers out. Let's do it. With Ruby.
---

MAQL is a language that is fairly similar to SQL but it is aimed towards getting the data from OLAP system. You are never forced to talk about columns and specify joins explicitly. This is great but there are some drawbacks. Same as SQL MAQL is aimed towards users more than machines which does not help for automation but there is one more caveat that make it hard to use even for humans. Probably to your surprise

    SELECT SUM(Amount)

Is not a MAQL statement (even though you probably have seen this on UI). The more correct (and what goes back and forth over the wire) is

    SELECT SUM([/gdc/md/132131231/obj/1])

GoodData UI does a great job at hiding this complexity from you but this significantly hinders the use of MAQL over and API by regular Joes. Ruby SDK tries to alleviate the situation with some tricks. It also gives you many tools to programmatically define and deal with reports and lays the foundations for test driven BI.

###Jack in
If you do not have a project best would be to create one by following our tutorial [Your first project](http://sdk.gooddata.com/gooddata-ruby/recipe/2014/01/19/your-first-project.html) so you can get predictable results.

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

###First metric
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

###More on metric execution

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

###Defining a ReportDefinition

Ok we have our metric. Now it would be interesting to see a report. The metric broken down. If you are familiar with the model you know the metric is a summation of lines changed in all commits in all products made by all developers. Let's see, how developers contributed.

    GoodData::ReportDefinition.execute(:top => ["attr.devs.id"], :left => [m])
    > [ 1  |  2  |  3 ]
      [1.0 | 3.0 | 5.0]

Again, there are a lots of ways how to achieve the same result so let's have a look at what is available right now. You can already see that you can see a metric by reference and attribute can be referenced just by a string containing an identifier. Let's pass the attribute as an object as well.

    a = GoodData::Attribute.get_by_id("attr.devs.id")
    GoodData::ReportDefinition.execute(:top => [a], :left => [m])

If you studied UI well you know that Report is defined using Display Forms (or labels) not by attribute. If you are specifying an attribute SDK will take the first one automatically. This works well most of the time since attributes have typically just one label. But sometimes they have many so you need to me more specific. Coincidently our attribute has 2 labels.

    a.display_forms.count
    > 2

The identifiers are "label.devs.email" and "label.devs.id". Let's try using those

    GoodData::ReportDefinition.execute(:top => ["label.devs.id"], :left => [m])
    GoodData::ReportDefinition.execute(:top => ["label.devs.email"], :left => [m])

You can even do something that you cannot do on UI and that is using both of the labels at the same time (sic).

    GoodData::ReportDefinition.execute(:top => ["label.devs.id", "label.devs.email"], :left => [m])

In almost all above cases we had only one thing in left or top section. You can save your fingers and not use the array literal if there is only one item in the section. SDK will wrap them for you.

    GoodData::ReportDefinition.execute(:top => "label.devs.id", :left => m)

Sometimes it might be useful to refer to the objects in a different way. You can do it by title

    GoodData::ReportDefinition.execute(
      :top => [{:type => :attribute, :title => "Month/Year (committed_on)"}],
      :left => m)

Since underneath it uses MdObject.find_first_by_title it also accepts RegExp literal

    GoodData::ReportDefinition.execute(
      :top => [{:type => :attribute, :title => /Month\/Year/}],
      :left => m)

    GoodData::ReportDefinition.execute(
      :top => [{:type => :attribute, :title => /month\/year/i}],
      :left => m)

In our model we have two attributes of name Id. Since the title does not have to be unique this is ok. Currently it will pick the first for you but this behavior will likely change in the favor of throwing an ambiguous error much like your SQL client probably does.

    GoodData::ReportDefinition.execute(:top => [{:type => :attribute, :title => "Id"}], :left => m)

Of course you can combine all things we learned together.

    a = GoodData::Attribute.find_first_by_title(/month\/year/i)
    GoodData::ReportDefinition.execute(:top => [{:type => :attribute, :title => "Id"}], :left => [m, a])

###Reports
Up until now we have been computing the reports just because. Maybe you wonder how you can actually create a report that would be saved. It is simple

    GoodData::ReportDefinition.execute(
      :top => [{:type => :attribute, :title => /Month\/Year/}],
      :left => m)
    
    report = GoodData::Report.create(
      :title => "Fantastic report",
      :top => [{:type => :attribute, :title => /Month\/Year/}],
      :left => m)
    
    report.save


###Results

Ok now we know how to create a report. Now let's see what we can do with the result. The point of this framework is not only you being able to create reports programmatically and save them for consumption over UI. Yes this is incredibly useful but when we have that why stop there. With Ruby SDK  you can actually consume the result programmatically as well so you can use GD as a basis for your application. Or as we show in this section we build a foundation for Test Driven BI development.

Let's execute one of the previously defined reports and this time let's store the result

    result = GoodData::ReportDefinition.execute(
      :top => [{:type => :attribute, :title => /month\/year/i}],
      :left => m)
    >
    [Jan 2014 | Feb 2014]
    [1.0      | 8.0     ]

The class is ReportDataResult. As you will see further it tries to conform to API of an array in key aspoects
    
    result.class
    > GoodData::ReportDataResult
    
    result[0][0]
    > "Jan 2014"
    
    result[1][0]
    > 1.0

All the numbers are of BigDecimal class so you should be able to perform additional computations without losing precision

    result[1][0].class
    > BigDecimal
    
Let's look on couple of methods that are useful for validating the results of reports

    result.include_row? [1, 8]
    > true
    
    result.include_column? ["Feb 2014", 8]
    > true
    
Result is coming from server in a special format but after some processing it is just an 2 D array so it is no wonder that you can test on equality of a whole report.

    result == [["Jan 2014", "Feb 2014"], [1, 8]]
