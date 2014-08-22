---
layout: guides
title:  "Creating Comparison Metrics Programatically"
date:   2014-07-09 10:00:00
categories: metric attribute
pygments: true
perex: Learn how you can automate comparison metrics creation based on give metric and attribute.
---

Tired about creating similar metrics all the time? We can clearly hear it "Every time I create new Project, I want to see the comparison between this and previous period." If you are a developer, you definitely don't like clicking in the UI even if it is the most usable. This guide is for all of you who like automation and scripting.

### Connect to GoodData

In the beginning, we have to connect to the GoodData Platform: 

{% highlight ruby %}
require "gooddata"
require "pp"

GoodData.connect("username","password")
GoodData.use("YOUR-PROJECT-ID")
{% endhighlight %}

### The method

Once we are connected, we can specify the core of our example. `create_div_metric` is the method that creates metrics for this and previous period, save them to the GoodData project and then creates third metric, that shows you the the share between those two periods.

{% highlight ruby %}
def create_div_metrics(metric,date_attribute)

  this = GoodData::Metric.xcreate(:expression => "SELECT ![#{metric.identifier}] WHERE ![#{date_attribute.identifier}] = THIS", :title => "SUM this #{date_attribute.title}")
  this.save

  previous = GoodData::Metric.xcreate(:expression => "SELECT ![#{metric.identifier}] WHERE ![#{date_attribute.identifier}] = THIS - 1", :title => "SUM previous #{date_attribute.title}")
  previous.save

  div = GoodData::Metric.xcreate(:expression => "SELECT ![#{this.identifier}]/![#{previous.identifier}] - 1", :title => "Div by #{date_attribute.title}")
  div.save
  
end
{% endhighlight %}

### Preparing facts and attributes

Great is that we can reuse this method for any number of facts. We just need to specify which fact should be use. You can even reuse it in some more advanced programatical logic. As you can see below, we are grabing the first fact that is returned from the GoodData Project and the method creates metrics based on this fact. 

{% highlight ruby %}
facts = GoodData::Fact.all(:full => true)
fact = facts.first
metric = GoodData::Metric.xcreate(:expression => "SELECT SUM(![#{fact.identifier}])", :title => "Simple sum")
metric.save
{% endhighlight %}

You can use this guide together with the [Batch operation tutorial](http://sdk.gooddata.com/gooddata-ruby/guide/metric-report-batch-operations/) to create multiple number of metrics. Now, let's say we would like to see metrics for two date dimensions (`Month/Year (Committed on)` and `Quarter/Year (Committed on)`). As you can see, you can easily find those attributes, save them to the variable and use later.

{% highlight ruby %}
attributes = GoodData::Attribute.all(:full => true)

attribute_month_year = attributes.find{|a| a.title == "Month/Year (Committed on)"}
attribute_quarter_year = attributes.find{|a| a.title == "Quarter/Year (Committed on)"}
{% endhighlight %}

### Metric creation

Finally, let's call the method we've created with parameters.

{% highlight ruby %}
create_div_metrics(metric,attribute_month_year)
create_div_metrics(metric,attribute_quarter_year)
{% endhighlight %}

That's all. You can check out your Project and put your metrics to Report.

