---
layout: guides
title:  "Generating Multiple Metrics/Reports"
date:   2014-06-13 10:00:00
categories: example, metric
pygments: true
perex: Learn how you can quickly generate set of metrics and reports in your newly created project.
---

When comming to rapid prototype your first analytical app, you can try follow this use case:

_Let's create a set of basic reports._

1) Connect to the GoodData Project 

{% highlight ruby %}
require "gooddata"
require "pp"

GoodData.connect("username@email.com","PASSWORD")
GoodData.use("Project-Id")
{% endhighlight %}


2) Select Datasets 

Using the following code, we are going to select all facts and attributes that we will work with. As you can see we want to use just Facts from "Devs" and "Repos" datasets. Check the code below to learn how to filter those facts.

{% highlight ruby %}
facts = GoodData::Fact.all(:full => true)
datasets_to_use = ["Devs","Repos"]
attributes = []

GoodData.project.datasets.find_all{|d| datasets_to_use.include?(d.json["dataSet"]["meta"]["title"])}.each do |dataset|
  attributes = attributes + dataset.attributes
end
{% endhighlight %}

3) Metrics

Usng the xcreate method, we can easily generate metrics using all existing facts:

{% highlight ruby %}
metrics = []
facts.each do |f|
  metric = GoodData::Metric.xcreate(:expression => "SELECT SUM(![#{f.identifier}])", :title => "Sum of #{f.title}")
  metrics << metric
  metric.save
end
{% endhighlight %}

Learn more about [_xcreate_ method](http://sdk.gooddata.com/gooddata-ruby/reference/crunching-numbers/) for the Metric object.

4) Generate Reports

Finally create a set of reports. For each report, you specify the layout ":top => a" means that attribute will be shown on the header and ":left => m" means that metrics will be on the left.

{% highlight ruby %}
reports = []
metrics.each do |m|
  attributes.each do |a|
    report = GoodData::Report.create(:title => "Report #{m.title} by #{a.title}", :left => m, :top => a)
    reports << report
    report.save
  end
end
{% endhighlight %}

Now execute all reports. Go to the GoodData and ... find your reports!

{% highlight ruby %}
reports.each do |r|
  pp r.execute
end
{% endhighlight %}
