---
layout: guides
title:  "Accessing Projects From Command Line, Browsing Attributes, Facts, and Metrics"
date:   2014-07-09 10:00:00
categories: general
tags:
- metrics
- facts
- attributes
pygments: true
perex: Learn how to print or search for attributes, metrics, facts, using the built in command line tool "jack_in".
---

Learn how to print or search for attributes, metrics, facts using the command line tool “jack_in”.

### Exploring Your Project with "Jack In."
![jack in](https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/693f9e51-b6e6-45d0-8534-320301fdd7fa.png)

- Open the Terminal on your Mac.
- Make sure you have the GoodData Ruby Gem.

{% highlight bash %}
gem install gooddata
{% endhighlight %}

- Using a project id from any of your projects execute this command.

{% highlight bash %}
gooddata -p PROJECT_ID -U YOUR-USERNAME -P YOUR-PASSWORD project jack_in
{% endhighlight %}

<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/706f934f-249a-4f97-b287-768ba718adf2.png" style="width: 70%;">
	</div>
	<small>You now have full access to all of the methods within the SDK so let's start exploring...</small></div>
</div>


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

