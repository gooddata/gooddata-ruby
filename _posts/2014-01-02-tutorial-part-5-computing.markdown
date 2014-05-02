---
layout: tutorial
title:  "Part V - Computing reports"
date:   2014-01-19 13:56:00
categories: tutorial
next_section: tutorial/tutorial-part-6-updating-model
prev_section: tutorial/tutorial-part-4-looking-around-project
pygments: true
perex: The logical data model (LDM) defines the facts and attributes in your project, as well as their relationships. Let’s have a look at how to create a project’s LDM using Ruby SDK. Then, we compare this method with other approaches.
---

*Warning*
This is most complex and as of now partially unfinished part of the SDK. We will just give you a glimpse of what is possible and direct you to the reference guide where many examples are described.

##Why do we care
We could make the same argument as we did with model definition. While creating reports interactively is preferred most of the time it is of utmost importance to be able to create them programatically as well. Maybe just for the sake of automation. So some common and probably tedious tasks can be run predictably. But you can go so far as to create whole projects programtically if you are able to devise many programs that will even create reports for you.

##First metric
Right now you are probably interested in how many developers are there in the project.

###Count
{% highlight ruby %}
GoodData::Attribute['attr.devs.dev_id'].create_metric.execute
{% endhighlight %}

This will find an attribute creates a metric out of it (the only aggregation usable on attribute is a Count and that is default) and executes it.

It returns 3 which is correct result.

####Saving a metric
The previous example created a metric on the fly. If we like it we can of course save it.

{% highlight ruby %}
GoodData::Attribute['attr.devs.dev_id'].create_metric.save
{% endhighlight %}

You can make sure it worked by using what we learned last time. Run

{% highlight ruby %}
GoodData::Metric.all
{% endhighlight %}

Our metric should be the only one there. You can grab it if you know its link and inspect it further.

{% highlight ruby %}
uri = GoodData::Metric.all.first['link']
metric = GoodData::Metric[uri]
metric.title
metric.expression
{% endhighlight %}

This should return `SELECT COUNT([/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/201])`. You can see that behind the scene it created a full fledged maql metric.

###Sum metric

Let's say that you would like to create another metric. This time out of fact. The only fact we have is called 'Lines changed'. If it worked with attribute let's try the same with a fact.

{% highlight ruby %}
GoodData::Fact.find_first_by_title('Lines changed').create_metric.execute
{% endhighlight %}

Great very similar. Note couple of differences. We used `find_first_by_title` just to illustrate that there are various ways how to get to the object we want. Create_metrics works the same. The default aggregation function here is `SUM` but there are actually many more available for the fact. Let's say you are interested in average.

{% highlight ruby %}
GoodData::Fact.find_first_by_title('Lines changed').create_metric(:type => :avg).execute
{% endhighlight %}

Let's save both of the metrics like we did previously.

{% highlight ruby %}
sum = GoodData::Fact.find_first_by_title('Lines changed').create_metric.save
avg = GoodData::Fact.find_first_by_title('Lines changed').create_metric(:type => :avg).save
{% endhighlight %}

##First report

Metrics are all fine but we always got back one number. To get more insight we want to slice and dice that number by various attributes. Let's see how each developer performed

{% highlight ruby %}
GoodData::ReportDefinition.execute :top => [sum], :left => 'attr.devs.dev_id'
{% endhighlight %}

This should return something along the lines

{% highlight ruby %}
[jirka@gooddata.com | 5.0]
[petr@gooddata.com  | 3.0]
[tomas@gooddata.com | 1.0]
{% endhighlight %}

The result here is just an array of arrays so you can dig deeper if you need to. Let's find out how people performed across projects.

{% highlight ruby %}
GoodData::ReportDefinition.execute :top => [sum, 'attr.repos.repo_id'], :left => 'attr.devs.dev_id'
{% endhighlight %}

Which returns something like

{% highlight ruby %}
[                   |     gooddata-gem     |  gooddata-platform  ]
[                   | sum of Lines changed | sum of Lines changed]
[jirka@gooddata.com | 5.0                  |                     ]
[petr@gooddata.com  |                      | 3.0                 ]
[tomas@gooddata.com | 1.0                  |                     ]
{% endhighlight %}

###Saving report

Notice that we said we are doing reports yet we used ReportDefinition class. I do not want to go into too much detail but the report is really a report class. The problem is that Report has to be saved to be executed which might cause mixup on UI. We will try to resolve the problem in the future version but remember that ReportDefinition is great for experimentation. Report is good for saving.

Let's create the same report. The only difference is that we need to provide a title so we can save it.

{% highlight ruby %}
report = GoodData::Report.create :title => 'Devs lines commited per repository', :top => [sum, 'attr.repos.repo_id'], :left => 'attr.devs.dev_id'
report.save
report.execute
{% endhighlight %}

Similar enough. Now the report is really in project and accessibel in the UI.

{% highlight ruby %}
GoodData::Report.all
{% endhighlight %}

##Exporting your work
There are several ways how to consume your report. You can go to UI. You can execute it and consume the results. You can also export it as either CSV, PDF

Let's do PDF

{% highlight ruby %}
File.open('export.pdf', 'w') do |f|
  f.puts(report.export(:pdf))
end
{% endhighlight %}

Now you can display exported the file in your favorite viewer. There is much more we did not cover. We did not dig a lot into maql and many other options there are duringcreation of reports. You can have a look at (crunching numbers article)[reference/crunching-numbers] to find more examples.

##What did you learn
You saw how to interactively create reports, save them, execute and export them. You should understand why we bother and how far we could take this.

##Where to go next
We came almost full circle. Let's have a look how what will happen when there is a change in th underlying model.